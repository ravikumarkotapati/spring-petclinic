\# Current-State Inventory



| Area | Finding | Evidence | Notes |

|---|---|---|---|

| Application | Spring PetClinic | evidence/logs/git-remote.txt | Primary assessment application |

| Repository | Forked Spring PetClinic repository | evidence/logs/git-remote.txt | Candidate-owned fork used for assessment |

| App type | Spring Boot monolith | pom.xml, source structure | Single deployable application |

| Runtime | Java / Spring Boot | evidence/logs/java-version.txt, evidence/logs/app-startup-8081.log | Local VM simulation |

| Build tool | Maven wrapper | mvnw.cmd, evidence/logs/maven-version.txt | Used for local build/run |

| OS baseline | Windows local machine | evidence/logs/os-baseline.txt | Represents on-prem VM simulation |

| App port | 8081 | evidence/logs/endpoint-home-8081.txt | Changed from 8080 because Jenkins uses 8080 |

| Local ingress | Browser HTTP access | evidence/screenshots, endpoint logs | http://localhost:8081 |

| Database | Local development database profile | startup logs, config scan | Default profile uses embedded/local DB behavior unless PostgreSQL profile is enabled |

| Config files | Spring application config files | evidence/logs/manual-dependency-scan.txt | Review application properties/yaml files identified by scan |

| Environment variables | Server port override | startup command | Used `--server.port=8081` to avoid local Jenkins conflict |

| Secrets | No production secrets identified | evidence/logs/manual-dependency-scan.txt | Any sample credentials are non-production and must move to Key Vault in Azure |

| Certificates | None identified in local baseline | evidence/logs/manual-dependency-scan.txt | TLS/certificate handling required in Azure target design |

| Scheduled jobs | None identified in baseline scan | evidence/logs/manual-dependency-scan.txt | Validate again in Module 2 crawler |

| File shares | None identified for business data | evidence/logs/manual-dependency-scan.txt | Static resources and local logs only unless discovery finds more |

| Auth provider | None identified | evidence/logs/manual-dependency-scan.txt | No LDAP/OIDC integration identified in Module 1 |

| External APIs/SMTP | None identified | evidence/logs/manual-dependency-scan.txt | Confirm with app-team interview in real migration |

| Operational dependency | Jenkins occupies localhost:8080 | user observation | PetClinic baseline was moved to 8081 |



