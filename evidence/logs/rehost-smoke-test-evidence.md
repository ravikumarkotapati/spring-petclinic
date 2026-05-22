# Rehost Smoke Test Evidence

| Field | Value |
|---|---|
| App URL | http://petclinic-rehost-qevd19.centralus.cloudapp.azure.com |
| Test time | 2026-05-22 10:59:49 +08:00 |

| Endpoint | URL | Status | Expected Text Found | Duration ms | Result | Error |
|---|---|---:|---|---:|---|---|
| home | http://petclinic-rehost-qevd19.centralus.cloudapp.azure.com/ | 200 | True | 549 | PASS |  |
| vets | http://petclinic-rehost-qevd19.centralus.cloudapp.azure.com/vets.html | 200 | True | 253 | PASS |  |
| owners-find | http://petclinic-rehost-qevd19.centralus.cloudapp.azure.com/owners/find | 200 | True | 242 | PASS |  |
| health | http://petclinic-rehost-qevd19.centralus.cloudapp.azure.com/healthz | 200 | True | 276 | PASS |  |
