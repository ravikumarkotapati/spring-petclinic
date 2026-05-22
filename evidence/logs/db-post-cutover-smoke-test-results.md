# Container Apps Health Check Evidence

| Item | Value |
|---|---|
| Endpoint | https://petclinic-container-app.victorioussand-ef83e08c.centralus.azurecontainerapps.io |
| Captured at | 2026-05-22T15:58:05+08:00 |

| Check | URL | Status | Success | Duration ms |
|---|---|---:|---|---:|
| home | https://petclinic-container-app.victorioussand-ef83e08c.centralus.azurecontainerapps.io/ | 200 | True | 3491 |
| health | https://petclinic-container-app.victorioussand-ef83e08c.centralus.azurecontainerapps.io/actuator/health | 200 | True | 1338 |
| owners | https://petclinic-container-app.victorioussand-ef83e08c.centralus.azurecontainerapps.io/owners/find | 200 | True | 1216 |

## Response Excerpts

### home

```text
<!DOCTYPE html> <html> <head> <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" /> <meta charset="utf-8"> <meta http-equiv="X-UA-Compatible" content="IE=edge"> <me
```
### health

```text
{"groups":["liveness","readiness"],"status":"UP"}
```

### owners

```text
<!DOCTYPE html> <html> <head> <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" /> <meta charset="utf-8"> <meta http-equiv="X-UA-Compatible" content="IE=edge"> <me
```
