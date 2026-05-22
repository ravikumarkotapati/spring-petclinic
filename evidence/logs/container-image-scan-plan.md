# Container Image Scan Evidence And Promotion Plan

## Scan Execution

| Item | Value |
|---|---|
| Image | `petclinic:module5-local` |
| Revision tag | `petclinic:9de94c5` |
| Image digest | `bf9d25eb2d16` |
| Scan tool | Docker Scout CLI `v1.20.4` |
| Scan evidence | [`container-image-scan.log`](container-image-scan.log) |
| Remediation recommendation evidence | [`container-image-recommendations.log`](container-image-recommendations.log) |
| Image metadata evidence | [`container-image-inspect.json`](container-image-inspect.json) |

## Scan Result Summary

Docker Scout indexed 330 packages and reported vulnerabilities in 21 packages.

| Severity | Count |
|---|---:|
| Critical | 11 |
| High | 12 |
| Medium | 25 |
| Low | 11 |
| Unspecified | 1 |

The most important promotion blocker is the application dependency baseline, especially `org.apache.tomcat.embed/tomcat-embed-core 11.0.18`. Docker Scout reports fixed Tomcat versions for the critical/high findings, commonly `11.0.20`, `11.0.21` or `11.0.22` depending on the CVE.

## Promotion Decision

This image is acceptable as Module 5 local build evidence, but it should not be promoted to shared test, staging or production while critical/high vulnerabilities remain open.

Required promotion gates:

| Gate | Required Action |
|---|---|
| Dependency remediation | Upgrade the Spring Boot/Tomcat dependency baseline or apply an approved dependency override that brings Tomcat to a fixed version. |
| Rebuild | Rebuild the image with immutable tags: `petclinic:<git-sha>` and registry-qualified environment tags. |
| Rescan | Rerun `docker scout cves <image>` or `trivy image <image>` and store the report under `evidence/logs/`. |
| Exception control | If a vulnerability cannot be remediated immediately, capture owner, expiry date, compensating controls and approval before promotion. |
| CI/CD gate | Module 6 pipeline should fail on critical/high vulnerabilities unless a documented exception exists. |

## SBOM Plan

The Maven container build generated a CycloneDX application SBOM during package creation:

```text
target/classes/META-INF/sbom/application.cdx.json
```

For registry promotion, export SBOM evidence from the final image using one of these commands:

```powershell
docker sbom petclinic:<git-sha> --format cyclonedx-json > evidence/logs/container-sbom.json
```

or

```powershell
syft petclinic:<git-sha> -o cyclonedx-json > evidence/logs/container-sbom.json
```

## Base Image Recommendation

Docker Scout reports the current base image `eclipse-temurin:17-jre-jammy` as up to date with no critical or high base-image vulnerabilities. The remaining critical/high blockers are primarily application dependencies, so the next remediation action should focus on the Maven dependency baseline before changing Java runtime families.
