targetScope = 'resourceGroup'

@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('Short workload name used as a resource name prefix.')
param workloadName string = 'petclinic-rehost'

@description('Linux admin username for SSH access.')
param adminUsername string

@description('SSH public key used for Linux admin access.')
param sshPublicKey string

@description('CIDR allowed to reach SSH. Use your public IP with /32 for least privilege.')
param adminSourceIp string

@description('CIDR allowed to reach public HTTP ingress. Tighten for enterprise validation.')
param httpSourceIp string = '0.0.0.0/0'

@description('Azure VM size.')
param vmSize string = 'Standard_B2ms'

@description('Git repository URL cloned by cloud-init on first boot.')
param repoUrl string = 'https://github.com/ravikumarkotapati/spring-petclinic.git'

@description('Git branch cloned by cloud-init on first boot.')
param repoBranch string = 'module4-rehost-azure-vm'

@description('Internal Spring Boot app port. NGINX listens on 80 and proxies to this port.')
param appPort int = 8081

@allowed([
  'h2'
  'postgres'
  'mysql'
])
@description('Spring active profile stored in Key Vault. Use h2 for a self-contained smoke test, postgres/mysql for an external database endpoint.')
param activeProfile string = 'h2'

@secure()
@description('Spring datasource JDBC URL stored in Key Vault. Leave empty for h2 profile.')
param datasourceUrl string = ''

@secure()
@description('Spring datasource username stored in Key Vault. Leave empty for h2 profile.')
param datasourceUsername string = ''

@secure()
@description('Spring datasource password stored in Key Vault. Leave empty for h2 profile.')
param datasourcePassword string = ''

var resourceToken = toLower(uniqueString(resourceGroup().id, workloadName))
var normalizedWorkload = toLower(replace(workloadName, '_', '-'))
var vnetName = '${normalizedWorkload}-vnet'
var subnetName = '${normalizedWorkload}-app-snet'
var nsgName = '${normalizedWorkload}-app-nsg'
var publicIpName = '${normalizedWorkload}-pip'
var nicName = '${normalizedWorkload}-nic'
var vmName = '${normalizedWorkload}-vm'
var managedIdentityName = '${normalizedWorkload}-mi'
var keyVaultName = take(replace('${normalizedWorkload}-${resourceToken}-kv', '-', ''), 24)
var logAnalyticsName = '${normalizedWorkload}-${resourceToken}-law'
var recoveryVaultName = '${normalizedWorkload}-${resourceToken}-rsv'
var dcrName = '${normalizedWorkload}-vm-dcr'
var keyVaultSecretsUserRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
}

var cloudInitTemplate = '''
#cloud-config
package_update: true
package_upgrade: false
packages:
  - openjdk-17-jdk
  - git
  - nginx
  - curl
  - jq

groups:
  - petclinic

users:
  - default
  - name: petclinic
    groups: petclinic
    shell: /usr/sbin/nologin
    system: true

write_files:
  - path: /opt/petclinic/render-env.sh
    owner: root:root
    permissions: '0750'
    content: |
      #!/usr/bin/env bash
      set -euo pipefail
      KEYVAULT_NAME="__KEYVAULT_NAME__"
      IDENTITY_CLIENT_ID="__IDENTITY_CLIENT_ID__"
      ACTIVE_PROFILE_SECRET_NAME="petclinic-active-profile"
      DB_URL_SECRET_NAME="petclinic-datasource-url"
      DB_USERNAME_SECRET_NAME="petclinic-datasource-username"
      DB_PASSWORD_SECRET_NAME="petclinic-datasource-password"
      ENV_FILE="/etc/petclinic/petclinic.env"

      get_token() {
        curl -fsS -H Metadata:true "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2F__KEYVAULT_RESOURCE_HOST__&client_id=$IDENTITY_CLIENT_ID" | jq -r '.access_token'
      }

      get_secret() {
        local secret_name="$1"
        local token="$2"
        curl -fsS -H "Authorization: Bearer $token" "https://$KEYVAULT_NAME__KEYVAULT_DNS_SUFFIX__/secrets/$secret_name?api-version=7.4" | jq -r '.value'
      }

      token=""
      active_profile=""
      db_url=""
      db_username=""
      db_password=""
      for attempt in $(seq 1 30); do
        token="$(get_token || true)"
        if [ -n "$token" ]; then
          active_profile="$(get_secret "$ACTIVE_PROFILE_SECRET_NAME" "$token" || true)"
          db_url="$(get_secret "$DB_URL_SECRET_NAME" "$token" || true)"
          db_username="$(get_secret "$DB_USERNAME_SECRET_NAME" "$token" || true)"
          db_password="$(get_secret "$DB_PASSWORD_SECRET_NAME" "$token" || true)"
        fi
        if [ -n "$active_profile" ] && [ "$active_profile" != "null" ]; then
          break
        fi
        echo "Waiting for Key Vault secret access, attempt $attempt of 30"
        sleep 10
      done

      if [ -z "$active_profile" ] || [ "$active_profile" = "null" ]; then
        echo "Unable to read required Key Vault secrets" >&2
        exit 1
      fi

      install -d -m 0750 -o petclinic -g petclinic /etc/petclinic
      {
        echo "SERVER_PORT=__APP_PORT__"
        echo "SPRING_PROFILES_ACTIVE=$active_profile"
        echo "MANAGEMENT_ENDPOINT_HEALTH_PROBES_ADD_ADDITIONAL_PATHS=true"
        if [ "$active_profile" != "h2" ] && [ -n "$db_url" ] && [ "$db_url" != "null" ]; then
          echo "SPRING_DATASOURCE_URL=$db_url"
          echo "SPRING_DATASOURCE_USERNAME=$db_username"
          echo "SPRING_DATASOURCE_PASSWORD=$db_password"
        fi
      } > "$ENV_FILE"
      chown petclinic:petclinic "$ENV_FILE"
      chmod 0640 "$ENV_FILE"

  - path: /etc/systemd/system/petclinic.service
    owner: root:root
    permissions: '0644'
    content: |
      [Unit]
      Description=Spring PetClinic rehosted application
      Wants=network-online.target
      After=network-online.target
      StartLimitIntervalSec=0

      [Service]
      User=petclinic
      Group=petclinic
      WorkingDirectory=/opt/petclinic
      ExecStartPre=/opt/petclinic/render-env.sh
      EnvironmentFile=/etc/petclinic/petclinic.env
      ExecStart=/usr/bin/java -XX:MaxRAMPercentage=75.0 -jar /opt/petclinic/app.jar
      Restart=always
      RestartSec=10
      SuccessExitStatus=143
      NoNewPrivileges=true
      PrivateTmp=true
      ProtectSystem=strict
      ReadWritePaths=/opt/petclinic /etc/petclinic /var/log/petclinic

      [Install]
      WantedBy=multi-user.target

  - path: /etc/nginx/sites-available/petclinic
    owner: root:root
    permissions: '0644'
    content: |
      server {
          listen 80 default_server;
          listen [::]:80 default_server;
          server_name _;

          access_log /var/log/nginx/petclinic-access.log;
          error_log /var/log/nginx/petclinic-error.log;

          location / {
              proxy_pass http://127.0.0.1:__APP_PORT__;
              proxy_http_version 1.1;
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
          }

          location /healthz {
              proxy_pass http://127.0.0.1:__APP_PORT__/actuator/health;
              proxy_http_version 1.1;
              proxy_set_header Host $host;
          }
      }

runcmd:
  - install -d -o petclinic -g petclinic /opt/petclinic /var/log/petclinic
  - git clone --branch __REPO_BRANCH__ --depth 1 __REPO_URL__ /opt/petclinic/source
  - cd /opt/petclinic/source && ./mvnw -DskipTests package
  - cp /opt/petclinic/source/target/*.jar /opt/petclinic/app.jar
  - chown -R petclinic:petclinic /opt/petclinic /var/log/petclinic
  - rm -f /etc/nginx/sites-enabled/default
  - ln -sf /etc/nginx/sites-available/petclinic /etc/nginx/sites-enabled/petclinic
  - nginx -t
  - systemctl daemon-reload
  - systemctl enable petclinic
  - systemctl restart petclinic
  - systemctl enable nginx
  - systemctl restart nginx
'''
var cloudInitStep1 = replace(cloudInitTemplate, '__KEYVAULT_NAME__', keyVaultName)
var cloudInitStep2 = replace(cloudInitStep1, '__IDENTITY_CLIENT_ID__', managedIdentity.properties.clientId)
var cloudInitStep3 = replace(cloudInitStep2, '__APP_PORT__', string(appPort))
var cloudInitStep4 = replace(cloudInitStep3, '__REPO_BRANCH__', repoBranch)
var keyVaultResourceHost = substring(environment().suffixes.keyvaultDns, 1, length(environment().suffixes.keyvaultDns) - 1)
var cloudInitStep5 = replace(cloudInitStep4, '__REPO_URL__', repoUrl)
var cloudInitStep6 = replace(cloudInitStep5, '__KEYVAULT_DNS_SUFFIX__', environment().suffixes.keyvaultDns)
var cloudInit = replace(cloudInitStep6, '__KEYVAULT_RESOURCE_HOST__', keyVaultResourceHost)
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTP-NGINX'
        properties: {
          priority: 100
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: httpSourceIp
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'Allow-SSH-Admin'
        properties: {
          priority: 110
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: adminSourceIp
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.40.0.0/16'
      ]
    }
  }
}

resource appSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  parent: vnet
  name: subnetName
  properties: {
    addressPrefix: '10.40.1.0/24'
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: take('${normalizedWorkload}-${resourceToken}', 63)
    }
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: appSubnet.id
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: tenant().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    enablePurgeProtection: true
    publicNetworkAccess: 'Enabled'
    accessPolicies: []
  }
}

resource activeProfileSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'petclinic-active-profile'
  properties: {
    value: activeProfile
  }
}

resource datasourceUrlSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'petclinic-datasource-url'
  properties: {
    value: datasourceUrl
  }
}

resource datasourceUsernameSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'petclinic-datasource-username'
  properties: {
    value: datasourceUsername
  }
}

resource datasourcePasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'petclinic-datasource-password'
  properties: {
    value: datasourcePassword
  }
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource recoveryVault 'Microsoft.RecoveryServices/vaults@2023-04-01' = {
  name: recoveryVaultName
  location: location
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

resource dataCollectionRule 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: dcrName
  location: location
  properties: {
    dataSources: {
      syslog: [
        {
          name: 'linux-syslog'
          streams: [
            'Microsoft-Syslog'
          ]
          facilityNames: [
            'auth'
            'authpriv'
            'cron'
            'daemon'
            'kern'
            'syslog'
            'user'
          ]
          logLevels: [
            'Warning'
            'Error'
            'Critical'
            'Alert'
            'Emergency'
          ]
        }
      ]
      performanceCounters: [
        {
          name: 'vm-performance'
          streams: [
            'Microsoft-Perf'
          ]
          samplingFrequencyInSeconds: 60
          counterSpecifiers: [
            '\\Processor(_Total)\\% Processor Time'
            '\\Memory\\Available MBytes'
            '\\LogicalDisk(_Total)\\% Free Space'
          ]
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          name: 'central-law'
          workspaceResourceId: workspace.id
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-Syslog'
          'Microsoft-Perf'
        ]
        destinations: [
          'central-law'
        ]
      }
    ]
  }
}

resource vmKeyVaultSecretsUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, managedIdentity.id, 'key-vault-secrets-user')
  scope: keyVault
  properties: {
    roleDefinitionId: keyVaultSecretsUserRoleDefinitionId
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: 64
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      customData: base64(cloudInit)
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
  dependsOn: [
    vmKeyVaultSecretsUser
    activeProfileSecret
    datasourceUrlSecret
    datasourceUsernameSecret
    datasourcePasswordSecret
  ]
}

resource azureMonitorAgent 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  parent: vm
  name: 'AzureMonitorLinuxAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorLinuxAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}

resource dcrAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' = {
  name: '${vm.name}-dcr-association'
  scope: vm
  properties: {
    dataCollectionRuleId: dataCollectionRule.id
  }
  dependsOn: [
    azureMonitorAgent
  ]
}

output vmName string = vm.name
output publicIpAddress string = publicIp.properties.ipAddress
output appUrl string = 'http://${publicIp.properties.dnsSettings.fqdn}'
output keyVaultName string = keyVault.name
output logAnalyticsWorkspaceName string = workspace.name
output recoveryServicesVaultName string = recoveryVault.name
output sshCommand string = 'ssh ${adminUsername}@${publicIp.properties.dnsSettings.fqdn}'

