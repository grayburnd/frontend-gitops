#!/usr/bin/env bash
set -euo pipefail #Exit immediately if a command exits with a non-zero status, and if a value is unbound.

TARGET_LINT_DIRECTORIES="${1}"
TEAM="${2}"
ENVIRONMENT="${3}"
KUBECONFORM="${4}"

for CATEGORY in ${TARGET_LINT_DIRECTORIES}; do
  ORIGINAL_DIR=$(pwd)
  echo "===VALIDATING K8S ${CATEGORY} MANIFESTS==="
  for APP in "${CATEGORY}"/*; do
    cd "${APP}"
    if [[ "${KUBECONFORM}" == true ]]; then
      helm template . -f=../../values/"${TEAM}"-gitops/"${APP}"/"${ENVIRONMENT}"-values.yml | kubeconform -ignore-missing-schemas -strict
    else
      helm lint . -f=../../values/"${TEAM}"-gitops/"${APP}"/"${ENVIRONMENT}"-values.yml
    fi
    cd "${ORIGINAL_DIR}";
  done;
done