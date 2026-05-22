#!/usr/bin/env bash
set -euo pipefail

APP_URL="${APP_URL:-}"
OUTPUT_DIR="${OUTPUT_DIR:-evidence/logs}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-30}"
INCLUDE_RUNTIME_INFO="${INCLUDE_RUNTIME_INFO:-false}"
CURL_INSECURE="${CURL_INSECURE:-false}"

if [[ -z "${APP_URL}" ]]; then
  echo "APP_URL is required. Example: APP_URL=https://example.com ./tests/smoke_test.sh" >&2
  exit 2
fi

APP_URL="${APP_URL%/}"
mkdir -p "${OUTPUT_DIR}"

CSV_PATH="${OUTPUT_DIR}/module11-smoke-test-results.csv"
MD_PATH="${OUTPUT_DIR}/module11-smoke-test-evidence.md"
CAPTURED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

tests=(
  "home|/|PetClinic"
  "owners-find|/owners/find|Find Owners"
  "vets|/vets.html|Veterinarians"
  "health|/actuator/health|UP"
)

if [[ "${INCLUDE_RUNTIME_INFO}" == "true" ]]; then
  tests+=("runtime-info|/actuator/info|petclinicRuntime")
fi

curl_args=(-sS --max-time "${TIMEOUT_SECONDS}")
if [[ "${CURL_INSECURE}" == "true" ]]; then
  curl_args+=(-k)
fi

printf '"Name","Url","StatusCode","Success","DurationMs","ExpectedText","CapturedAt"\n' > "${CSV_PATH}"
{
  echo "# Module 11 Smoke Test Evidence"
  echo
  echo "| Field | Value |"
  echo "|---|---|"
  echo "| App URL | ${APP_URL} |"
  echo "| Captured at | ${CAPTURED_AT} |"
  echo
  echo "| Check | URL | Status | Duration ms | Expected Text | Result |"
  echo "|---|---|---:|---:|---|---|"
} > "${MD_PATH}"

failures=0

for entry in "${tests[@]}"; do
  IFS="|" read -r name path expected <<< "${entry}"
  url="${APP_URL}${path}"
  tmp_body="$(mktemp)"
  start_ms="$(date +%s%3N)"

  status_code="000"
  if status_code="$(curl "${curl_args[@]}" -o "${tmp_body}" -w "%{http_code}" "${url}")"; then
    :
  else
    status_code="000"
  fi

  end_ms="$(date +%s%3N)"
  duration_ms=$((end_ms - start_ms))

  if [[ "${status_code}" =~ ^[23] ]] && grep -qi "${expected}" "${tmp_body}"; then
    success="true"
    result="PASS"
  else
    success="false"
    result="FAIL"
    failures=$((failures + 1))
  fi

  printf '"%s","%s","%s","%s","%s","%s","%s"\n' \
    "${name}" "${url}" "${status_code}" "${success}" "${duration_ms}" "${expected}" "${CAPTURED_AT}" >> "${CSV_PATH}"
  printf '| %s | %s | %s | %s | %s | %s |\n' \
    "${name}" "${url}" "${status_code}" "${duration_ms}" "${expected}" "${result}" >> "${MD_PATH}"

  rm -f "${tmp_body}"
done

if [[ "${failures}" -gt 0 ]]; then
  echo "Smoke tests failed. Review ${MD_PATH} and ${CSV_PATH}." >&2
  exit 1
fi

echo "Smoke tests passed. Evidence written to ${MD_PATH} and ${CSV_PATH}."
