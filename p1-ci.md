# Platform One CI Scanning
- Anchore Enterprise
  - scanning will be replaced with grype `docker pull anchore/grype:v0.35.0`
    - Parse [grype findings](https://repo1.dso.mil/ironbank-tools/grype-parser/-/blob/master/grype-parser.py)
  - sbom generation will be replaced with syft `docker pull anchore/syft:v0.45.1`
- OpenSCAP
  - Will remain the same but no rootless podman `docker pull openscap/openscap`
- Twistlock
  - CVE-File identification will be replaced with trivy `docker pull aquasec/trivy:0.27.1`
- Skopeo `docker pull quay.io/skopeo/stable:latest`

## skopeo to pull images
```
pull_cmd = [
        "skopeo",
        "copy",
        "--authfile=/tmp/prod_auth.json",
        "--remove-signatures",
        "--additional-tag",
        tag_value,
    ]
    if username and password:
        pull_cmd += ["--src-creds", f"{username}:{password}"]
    pull_cmd += [
        f"docker://{image}",
        f"docker-archive:{os.environ['ARTIFACT_STORAGE']}/import-artifacts/images/{tar_name}.tar",
    ]
```

## Anchore Generate SBOM
```
anchore_scan.generate_sbom(image, artifacts_path, "cyclonedx", "xml")
anchore_scan.generate_sbom(image, artifacts_path, "spdx-tag-value", "txt")
anchore_scan.generate_sbom(image, artifacts_path, "spdx-json", "json")
anchore_scan.generate_sbom(image, artifacts_path, "json", "json")
```

## Anchore Scan
```
image = os.environ["IMAGE_FULLTAG"]

digest = anchore_scan.image_add(image)
anchore_scan.image_wait(digest=digest)
anchore_scan.get_vulns(digest=digest, image=image, artifacts_path=artifacts_path)
anchore_scan.get_compliance(
    digest=digest, image=image, artifacts_path=artifacts_path
)
anchore_scan.get_version(artifacts_path=artifacts_path)
```

## OpenSCAP
```
#!/bin/bash
set -Eeuxo pipefail
# shellcheck source=./stages/scanning/openscap/base_image_type.sh
source "${PIPELINE_REPO_DIR}/stages/scanning/openscap/base_image_type.sh"
echo "Imported Base Image Type: ${BASE_IMAGE_TYPE}"
mkdir -p "${OSCAP_SCANS}"
echo "${DOCKER_IMAGE_PATH}"

# If OSCAP_VERSION variable doesn't exist, create the variable
if [[ -z ${OSCAP_VERSION:-} ]]; then
  OSCAP_VERSION=$(jq -r .version "$PIPELINE_REPO_DIR/stages/scanning/rhel-oscap-version.json" | sed 's/v//g')
fi

oscap_container=$(python3 "${PIPELINE_REPO_DIR}/stages/scanning/openscap/compliance.py" --oscap-version "${OSCAP_VERSION}" --image-type "${BASE_IMAGE_TYPE}" | sed s/\'/\"/g)
echo "${oscap_container}"
SCAP_CONTENT="scap-content"
mkdir -p "${SCAP_CONTENT}"

# If SCAP_URL var exists, use this to download scap content, else retrieve it based on BASE_IMAGE_TYPE
if [[ -n ${SCAP_URL:-} ]]; then
  curl -L "${SCAP_URL}" -o "${SCAP_CONTENT}/scap-security-guide.zip"
else
  curl -L "https://github.com/ComplianceAsCode/content/releases/download/v${OSCAP_VERSION}/scap-security-guide-${OSCAP_VERSION}.zip" -o "${SCAP_CONTENT}/scap-security-guide.zip"
fi

unzip -qq -o "${SCAP_CONTENT}/scap-security-guide.zip" -d "${SCAP_CONTENT}"
profile=$(echo "${oscap_container}" | grep -o '"profile": "[^"]*' | grep -o '[^"]*$')
securityGuide=$(echo "${oscap_container}" | grep -o '"securityGuide": "[^"]*' | grep -o '[^"]*$')
echo "profile: ${profile}"
echo "securityGuide: ${securityGuide}"
oscap-podman "${DOCKER_IMAGE_PATH}" xccdf eval --verbose ERROR --fetch-remote-resources --profile "${profile}" --results compliance_output_report.xml --report report.html "${SCAP_CONTENT}/${securityGuide}" || true
ls compliance_output_report.xml
ls report.html
rm -rf "${SCAP_CONTENT}"
echo "${OSCAP_VERSION}" >>"${OSCAP_SCANS}/oscap-version.txt"
cp report.html "${OSCAP_SCANS}/report.html"
cp compliance_output_report.xml "${OSCAP_SCANS}/compliance_output_report.xml"

echo "OSCAP_COMPLIANCE_URL=${CI_JOB_URL}" >oscap-compliance.env

cat oscap-compliance.env
```

## Twistlock
```
 before_script:
    - mkdir -p "${TWISTLOCK_SCANS}"
  script:
    - 'podman pull --authfile "${DOCKER_AUTH_CONFIG}" "${IMAGE_FULLTAG}"'
    - 'twistcli --version >"${VERSION_FILE}"'
    - 'twistcli images scan --address "${TWISTLOCK_SERVER_ADDRESS}" --podman-path podman --custom-labels --output-file "${CVE_FILE}" --details "${IMAGE_FULLTAG}" | tee "${DETAIL_FILE}"'
    - 'ls "${CVE_FILE}"'
    - 'chmod 0644 "${CVE_FILE}"'
```