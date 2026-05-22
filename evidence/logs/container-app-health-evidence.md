# Container Apps Health Check Evidence

| Item | Value |
|---|---|
| Endpoint | https://petclinic-container-app.victorioussand-ef83e08c.centralus.azurecontainerapps.io |
| Captured at | 2026-05-22T14:31:44+08:00 |

| Check | URL | Status | Success | Duration ms |
|---|---|---:|---|---:|
| home | https://petclinic-container-app.victorioussand-ef83e08c.centralus.azurecontainerapps.io/ | 200 | True | 713 |
| health | https://petclinic-container-app.victorioussand-ef83e08c.centralus.azurecontainerapps.io/actuator/health | 200 | True | 994 |
| owners | https://petclinic-container-app.victorioussand-ef83e08c.centralus.azurecontainerapps.io/owners/find | 200 | True | 935 |

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

