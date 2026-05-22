# 24-Hour Observability Snapshot

| Item | Value |
|---|---|
| Target | Azure Database for PostgreSQL Flexible Server |
| Monitoring system | Azure Monitor and PostgreSQL metrics |
| Snapshot type | Hypercare metric checklist and assessment baseline |
| Hypercare window | First 24 hours after production cutover |

## Metrics To Capture

| Metric | Green Threshold | Alert Trigger |
|---|---|---|
| CPU percent | Below 70% sustained | Above 80% for 15 minutes |
| Storage percent | Below 70% | Above 80% |
| Active connections | Within connection pool plan | Sudden saturation or connection failures |
| Failed connections | 0 or isolated | Any sustained failures |
| p95 database latency | Below 500 ms for this workload | Above 500 ms for 15 minutes |
| Deadlocks | 0 | Any repeated deadlocks |
| Backup health | Successful automated backups | Missed backup or PITR failure |

## Assessment Snapshot

| Signal | Status |
|---|---|
| Schema conversion | PASS |
| Data validation | PASS |
| Cutover runbook | Ready |
| Rollback decision tree | Ready |
| Observability thresholds | Defined |

During a live production cutover, export Azure Monitor charts for CPU, storage, connections, failed connections and latency for the first 24-hour window and attach them here.
