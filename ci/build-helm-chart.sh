#!/bin/bash

set -o nounset
set -o errexit

VERSION=${1}
CHART_FOLDER=${2}

echo "Packaging Helm Chart $CHART_FOLDER with Version $VERSION"

docker run --rm -v $(pwd):/apps -w /apps \
    alpine/helm:3.11.1 package $CHART_FOLDER --version $VERSION --app-version $VERSION -d target