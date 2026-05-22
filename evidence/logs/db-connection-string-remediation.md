# Connection String Remediation Evidence

| Item | Value |
|---|---|
| Target profile | `SPRING_PROFILES_ACTIVE=postgres` |
| JDBC URL key | `POSTGRES_URL` |
| Username key | `POSTGRES_USER` |
| Password key | `POSTGRES_PASS` |
| Secret store pattern | Key Vault references or Container Apps secrets |
| TLS requirement | `sslmode=require` in JDBC URL |

## Evidence Of Externalized Configuration

The application already externalizes PostgreSQL settings in `src/main/resources/application-postgres.properties`:

```properties
spring.datasource.url=${POSTGRES_URL:jdbc:postgresql://localhost/petclinic}
spring.datasource.username=${POSTGRES_USER:petclinic}
spring.datasource.password=${POSTGRES_PASS:petclinic}
```

## Target Secret References

| Secret | Purpose |
|---|---|
| `petclinic-postgres-jdbc-url` | Azure PostgreSQL JDBC URL |
| `petclinic-postgres-username` | Application database principal |
| `petclinic-postgres-password` | Application database password when password auth is used |

## Deployment Evidence

The cutover manifest pattern is captured in:

`infra/container-apps/petclinic-containerapp-db-cutover.template.yaml`

The production platform should grant the application managed identity access to these secrets and avoid committing any database password to source control.
