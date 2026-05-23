# Module 11 Smoke Test Evidence

| Field | Value |
|---|---|
| App URL | https://petclinic-container-app.victorioussand-ef83e08c.centralus.azurecontainerapps.io |
| Captured at | 2026-05-22T12:41:24Z |

| Check | URL | Status | Duration ms | Expected Text | Result |
|---|---|---:|---:|---|---|
| home | https://petclinic-container-app.victorioussand-ef83e08c.centralus.azurecontainerapps.io/ | 200 | 1869 | PetClinic | PASS |
| owners-find | https://petclinic-container-app.victorioussand-ef83e08c.centralus.azurecontainerapps.io/owners/find | 200 | 2104 | Find Owners | PASS |
| vets | https://petclinic-container-app.victorioussand-ef83e08c.centralus.azurecontainerapps.io/vets.html | 200 | 2937 | Veterinarians | PASS |
| health | https://petclinic-container-app.victorioussand-ef83e08c.centralus.azurecontainerapps.io/actuator/health | 200 | 1860 | UP | PASS |
