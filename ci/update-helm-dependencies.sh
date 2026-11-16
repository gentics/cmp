#!/bin/bash

set -o nounset
set -o errexit

CHART_FOLDER=${1}

REPO_USERNAME=${REPO_USERNAME:-}
REPO_PASSWORD=${REPO_PASSWORD:-}

echo "Adding Helm repositories and updating dependencies"
docker run --rm -v $(pwd):/apps -w /apps \
    --pids-limit 4096 \
    -e REPO_USERNAME="${REPO_USERNAME}" -e REPO_PASSWORD="${REPO_PASSWORD}" -e CHART_FOLDER="${CHART_FOLDER}" \
    -e GOMAXPROCS=2 \
    --entrypoint sh \
    alpine/helm:3.11.1 -c '
        helm repo add --username "$REPO_USERNAME" --password "$REPO_PASSWORD" gentics https://repo.gentics.com/repository/helm/
        helm repo add --username "$REPO_USERNAME" --password "$REPO_PASSWORD" gentics-snapshots https://repo.gentics.com/repository/helm-snapshots/
        # Public repositories of the monitoring stack dependencies
        helm repo add grafana-community https://grafana-community.github.io/helm-charts
        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
        helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
        helm repo update
        helm dependency update $CHART_FOLDER
    '
