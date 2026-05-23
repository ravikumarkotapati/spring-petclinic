\# Module 1 - Application Selection and On-Premise Baseline



\## Selected Application

Spring PetClinic was selected as the primary assessment application. It represents a familiar Spring Boot monolith-style workload suitable for application discovery, dependency mapping, containerization, database migration planning and Azure target architecture design.



\## Fork Repository

The application was forked from the upstream Spring PetClinic repository into a candidate-owned GitHub repository.



Evidence:

\- `evidence/logs/git-remote.txt`



\## Baseline Hosting Assumption

For Module 1, the application was run locally as an on-premise VM simulation. The local workstation represents the VM host. The app runtime, build tool, source files, configuration, logs and local ingress path are treated as the current-state baseline.



The application was run on port `8081` because Jenkins was already using port `8080` on the local machine.



\## Local Run Instructions

Prerequisites:

\- Git

\- Java

\- Maven wrapper included with the repository

\- Browser

\- Docker Desktop, optional for database/container scenarios



Run command:



```powershell

.\\mvnw.cmd spring-boot:run "-Dspring-boot.run.arguments=--server.port=8081"

Local endpoint:



http://localhost:8081/

Validation commands:



Invoke-WebRequest http://localhost:8081/ -UseBasicParsing

Invoke-WebRequest http://localhost:8081/owners/find -UseBasicParsing

Invoke-WebRequest http://localhost:8081/vets.html -UseBasicParsing

Runtime and Build Inventory

The application was started with the local Java runtime using the Maven wrapper. Runtime, build tool and OS baseline evidence were captured under evidence/logs.



Evidence:



evidence/logs/java-version.txt

evidence/logs/maven-version.txt

evidence/logs/os-baseline.txt

evidence/logs/app-startup-8081.log

Port and Ingress

The baseline ingress path is local browser HTTP access to the application on port 8081.



Evidence:



evidence/logs/endpoint-home-8081.txt

evidence/logs/endpoint-owners-find-8081.txt

evidence/logs/endpoint-vets-8081.txt

evidence/screenshots/

Database Baseline

The Module 1 baseline uses the application’s local development database behavior. Database details and configuration references are captured through startup logs and the manual dependency scan. A more detailed database inventory will be generated in Module 2 and expanded in the database migration module.



Evidence:



evidence/logs/app-startup-8081.log

evidence/logs/manual-dependency-scan.txt

Configuration and Environment Variables

The application was configured with a runtime port override using Spring Boot arguments. Configuration files and dependency references were scanned and recorded.



Evidence:



evidence/logs/manual-dependency-scan.txt

Secrets, Certificates and Identity

No production secrets, certificates, LDAP or OIDC dependencies were identified during the Module 1 baseline scan. Any sample credentials discovered in configuration are considered non-production and must be externalized to Azure Key Vault or equivalent secure configuration during migration.



Scheduled Jobs and File Dependencies

No scheduled jobs or business file-share dependencies were identified during the Module 1 baseline scan. Static assets, source files and logs are local disk dependencies for the baseline VM simulation.



External Dependencies

No SMTP or third-party API dependencies were identified during the Module 1 baseline scan. In a real enterprise migration, this would be validated through app-team interviews, firewall logs and Azure Migrate dependency analysis.



Current-State Architecture

The current-state architecture is documented in:

[docs/current-state-architecture.md](current-state-architecture.md)

Evidence Index

Evidence	Purpose

evidence/logs/java-version.txt	Java runtime baseline

evidence/logs/maven-version.txt	Build tool baseline

evidence/logs/os-baseline.txt	Host OS baseline

evidence/logs/app-startup-8081.log	Application startup evidence

evidence/logs/endpoint-home-8081.txt	Home endpoint validation

evidence/logs/endpoint-owners-find-8081.txt	Owners endpoint validation

evidence/logs/endpoint-vets-8081.txt	Vets endpoint validation

evidence/logs/manual-dependency-scan.txt	Initial dependency scan

evidence/screenshots/	Browser-based endpoint evidence

inventory/current\_state\_inventory.md	Current-state inventory table

docs/current-state-architecture.md	Current-state architecture diagram and description

Assumptions and Open Questions

Item	Assumption / Question	Follow-up

Hosting	Local workstation is used as the on-prem VM simulation	Replace with actual VM data in enterprise migration

Port	App uses 8081 locally because Jenkins occupies 8080	Confirm target ingress port mapping during Azure design

Database	Local development DB behavior is sufficient for Module 1 baseline	Build formal DB inventory in later modules

Secrets	No production secrets identified	Validate with source scan, pipeline scan and app-team interview

Auth	No LDAP/OIDC dependency identified	Confirm with app owner

SMTP/API	No external SMTP or partner API dependency identified	Confirm with firewall/network evidence



