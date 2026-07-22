#!/bin/bash

set -o nounset
set -o errexit

CHART_FILE=${1}
shift 2


# Each remaining arg is either NAME (repository only) or NAME=VERSION (repository + version).
for ENTRY in "$@"; do
    NAME=${ENTRY%%=*}

    echo "Setting repository '${REPOSITORY_URL}' for dependency '${NAME}' in ${CHART_FILE}"
    docker run --rm -v $(pwd):/apps -w /apps --user root \
        mikefarah/yq:4 eval -i \
        "(.dependencies[] | select(.name == \"${NAME}\") | .repository) = \"${REPOSITORY_URL}\"" \
        "${CHART_FILE}"

    if [[ "${ENTRY}" == *=* ]]; then
        VERSION=${ENTRY#*=}
        echo "Setting dependency '${NAME}' to version ${VERSION} in ${CHART_FILE}"
        docker run --rm -v $(pwd):/apps -w /apps --user root \
            mikefarah/yq:4 eval -i \
            "(.dependencies[] | select(.name == \"${NAME}\") | .version) = \"${VERSION}\"" \
            "${CHART_FILE}"
    fi
done

