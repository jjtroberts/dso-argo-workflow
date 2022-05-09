# devsecops-argo-workflow
An Argo Workflows and opensource implementation of Platform One's Iron Bank CI process.

## Proof-of-Concept
Expectations:
1. Use of an existing Iron Bank hardened container image.
2. Tools installed:
   1. Docker
   2. k3d
   3. kubectl
   4. argo

## Usage
1. Setup your k3d cluster and deploy Argo, secrets and pvc: `k3dup`
2. Edit the `registry1` secret in the `argo` namespace to copy `.dockerconfigjson` to a `config.json` key as required by Syft and Grype:
```
apiVersion: v1
data:
  .dockerconfigjson: <your-registry-auth-token>
  config.json: <your-registry-auth-token>
kind: Secret
metadata:
  name: registry1
  namespace: argo
type: kubernetes.io/dockerconfigjson
```
3. Apply the argo scan workflow: `make scan`

### Test Plan
- We will select an opensource project already hardened and approved within Iron Bank and compare our scan results against those of Iron Bank's Gitlab CI pipeline scanners.
- The Argo Workflow will use opensource dockerhub images where possible
- The Argo workflow itself will template each step and support parallel processes to speed up run time
- Compare the grype and P1 anchore findings

### Unknowns
- How to differentiate findings that belong to the base image versus those that belong to the application image.

## Outcomes
We **require** a database (not sure relational or nosql) to track what findings belong to which layer. I'd say just use VAT to filter out findings that belong to the base images, but the API requires AppGate SDP to access so that's not feasible for a service account. And I doubt P1 will provide an SLA, backwards compatibility with their API changes, or even allow us to utilize VAT's api in this way. Regardless, Rackner's Scan-as-a-service should not be dependent upon anything but registry1.dso.mil for Iron Bank image pulls.

A better approach might be to use Cloud Build and export the syft.json, grype.json, and trivy.json files to Cloud Storage to then trigger a load of that json+schema into BigQuery where analytics could be run on it, and perhaps use Data Studio for reporting.

See: https://cloud.google.com/bigquery/docs/samples/bigquery-load-table-gcs-json#bigquery_load_table_gcs_json-python

We could have an automated process that parses a list of base images (UBI8, Java, Python, etc) we want to track, and scans those 2-3 times per day; continuously updating findings in BigQuery. Then when we scan a customer's image we can filter out findings that come from the base layer.

## Potential JSON Schema Example
TODO: Identify common output format

Identifier,Source,Severity,Package,Package Path,Inherits From
CVE-2020-9493,anchore_cve,Critical,log4j-over-slf4j-1.7.36,/opt/cbflow/utils/langs/log4j-over-slf4j.jar,Uninherited

```json
{
  "$id": "https://example.com/findings.schema.json",
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "description": "A representation of a security finding.",
  "title": "Finding",
  "type": "object",
  "properties": {
    "identifier": {
      "type": "string",
      "description": "The vulnerability ID (CVE, CCE, etc)."
    },
    "source": {
      "type": "string",
      "description": "The scanner that produced the finding."
    },
    "severity": {
      "description": "Critical, High, Medium, Moderate, Low, Go",
      "type": "string"
    },
    "package": {
      "description": "Package name where finding was identified",
      "type": "string"
    },
    "package-path": {
      "description": "Path of file where finding was identified.",
      "type": "string"
    },
    "inherits-from": {
      "description": "The image to which the finding belongs (e.g. base, intermediate, uninherited)",
      "type": "string"
    }
  }
}
```