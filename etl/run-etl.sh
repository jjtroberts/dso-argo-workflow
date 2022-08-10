#!/bin/bash
set -Eeuo pipefail

# output OSCAP link variables for the VAT stage to use
python3 "transform.py" \
  # --scan_date "$(date --utc '+%FT%TZ')" \
  # --commit_hash "${CI_COMMIT_SHA}" \
  # --container "${IMAGE_NAME}" \
  # --version "${IMAGE_VERSION}" \
  # --digest "${IMAGE_PODMAN_SHA}" \
  # --parent "${BASE_IMAGE:-}" \
  # --parent_version "${BASE_TAG:-}" \
  # --comp_link "${OSCAP_COMPLIANCE_URL:-''}" \
  # --repo_link "${CI_PROJECT_URL}" \
  # --oscap "${ARTIFACT_STORAGE}/scan-results/openscap/compliance_output_report.xml" \
  --trivy "${ARTIFACT_STORAGE}/trivy.json" \
  --g "${ARTIFACT_STORAGE}/grype.json"

  # $ cat a.json | jq -c '.[]'
