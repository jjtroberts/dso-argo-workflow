#!/usr/bin/env python3

import sys
import json
import os
import argparse
import logging
from pathlib import Path
import requests
from requests.structures import CaseInsensitiveDict

parser = argparse.ArgumentParser(
    description="Processing of CVE reports from various sources"
)
parser.add_argument(
    "-j",
    "--job_id",
    help="Pipeline job ID",
    required=False,
)
parser.add_argument(
    "-sd",
    "--scan_date",
    help="Scan date for pipeline run",
    required=False,
)
parser.add_argument(
    "-ch",
    "--commit_hash",
    help="Commit hash for container build",
    required=False,
)
parser.add_argument(
    "-c",
    "--container",
    help="Container VENDOR/PRODUCT/CONTAINER",
    required=False,
)
parser.add_argument(
    "-v",
    "--version",
    help="Container Version from VENDOR/PRODUCT/CONTAINER/VERSION format",
    required=False,
)
parser.add_argument(
    "-dg",
    "--digest",
    help="Container Digest as SHA256 Hash",
    required=False,
)
parser.add_argument(
    "-t",
    "--trivy",
    help="location of the trivy.json scan file",
    required=False,
)
parser.add_argument(
    "-g",
    "--grype",
    help="location of the grype.json scan file",
    required=False,
)
parser.add_argument(
    "-pc",
    "--parent",
    help="Parent VENDOR/PRODUCT/CONTAINER",
    required=False,
)
parser.add_argument(
    "-pv",
    "--parent_version",
    help="Parent Version from VENDOR/PRODUCT/CONTAINER/VERSION format",
    required=False,
)


def transform_grype_findings():
    """
    Transform grype findings into a standard format
    """
    as_path = Path(args.grype)
    with as_path.open(mode="r", encoding="utf-8") as f:
        json_data = json.load(f)

    cves = []
    for v_d in json_data["matches"]:
        cve = {
            "finding": v_d["vulnerability"]["id"],
            "severity": v_d["vulnerability"]["severity"].lower(),
            "description": v_d["vulnerability"]["description"],
            "link": v_d["vulnerability"]["urls"],
            "package": v_d["artifact"]["name"],
            "packagePath": v_d["artifact"]["locations"][0]["path"],
            "packageVersion": v_d["artifact"]["version"],
            "fixVersion": v_d["vulnerability"]["fix"]["versions"],
            "fixState": v_d["vulnerability"]["fix"]["state"],
            "scanSource": "grype"
        }
        if cve not in cves:
            cves.append(cve)

    return cves


def transform_trivy_findings():
    """
    Transform trivy findings into a standard format
    """
    as_path = Path(args.trivy)
    with as_path.open(mode="r", encoding="utf-8") as f:
        json_data = json.load(f)

    cves = []
    for result in json_data["Results"]:
        for v_d in result["Vulnerabilities"]:
            cve = {
                "finding": v_d["VulnerabilityID"] if "VulnerabilityID" in v_d.keys() else "",
                "severity": v_d["Severity"].lower() if "Severity" in v_d.keys() else "",
                "description": v_d["Description"] if "Description" in v_d.keys() else "",
                "link": v_d["PrimaryURL"] if "PrimaryURL" in v_d.keys() else "",
                "package": v_d["PkgName"] if "PkgName" in v_d.keys() else "",
                "packageVersion": v_d["InstalledVersion"] if "InstalledVersion" in v_d.keys() else "",
                "fixVersion": v_d["FixedVersion"] if "FixedVersion" in v_d.keys() else "",
                "scanSource": "trivy"
            }
            if cve not in cves:
                cves.append(cve)
        if cve not in cves:
            cves.append(cve)

    return cves


def main():
   #print(transform_grype_findings())
   print(json.dumps(transform_trivy_findings()))


if __name__ == "__main__":
    args = parser.parse_args()
   
    # loglevel = os.environ.get("LOGLEVEL", "INFO").upper()
    # if loglevel == "DEBUG":
    #     logging.basicConfig(
    #         level=loglevel,
    #         filename="etl_logging.out",
    #         format="%(levelname)s [%(filename)s:%(lineno)d]: %(message)s",
    #     )
    #     logging.debug("Log level set to debug")
    # else:
    #     logging.basicConfig(
    #         level=loglevel, format="%(levelname)s: %(message)s")
    #     #logging.info("Log level set to info")
    main()
