#!/bin/bash

# Set the platforms you want to build for
PLATFORMS="linux/amd64,linux/arm64"

# Base directory (default to current dir if not provided)
BASE_DIR="${1:-.}"

# Tag prefix (e.g. "myrepo/service")
TAG_PREFIX="${2:-rvoitpg}"

# Builder name
BUILDER_NAME="$3"

OPENCTI_VERSION="${4:-false}"
BUILD_OPENCTI="${5:-false}"
OPENBAS_VERSION="${6:-false}"
BUILD_OPENBAS="${7:-false}"

MAX_BUILDS=${8:-100}
SKIP_BUILDS=${9:-0}

# Ensure buildx builder exists
if ! docker buildx inspect "$BUILDER_NAME" >/dev/null 2>&1; then
    echo "❌ Buildx builder '$BUILDER_NAME' does not exist."
    exit 1
fi

docker buildx use "$BUILDER_NAME"

# ------------------------
# Find Dockerfiles recursively
# ------------------------
ctr=0
find "$BASE_DIR" -type f -name 'Dockerfile' | while read -r dockerfile; do
    ctr=$((ctr + 1))

    service_dir=$(dirname "$dockerfile")
    
    # Filters out directories that shouldn't be parsed
    if [[ "$service_dir" =~ (/templates/|/shared/) ]]; then
        ctr=$((ctr - 1))
        continue
    fi
    buildNr=$((ctr - SKIP_BUILDS))

    # Extract category and service from the path
    path_parts=(${service_dir//\// })
    SERVICE="${path_parts[-1]}"
    ORIGIONAL_REPO="NOTGOOD"
    SERVICE_PREFIX="NOTGOOD"
    if [ "${path_parts[1]}" == "OpenCTI" ]; then
        if [ "${BUILD_OPENCTI}" == "false" ]; then
            ctr=$((ctr - 1))
            continue
        fi
        ORIGIONAL_REPO="opencti"
        IMAGE_VERSION=$OPENCTI_VERSION
        if [ "${path_parts[2]}" == "Connectors" ]; then
            SERVICE_PREFIX="connector"
        fi
    else 
        if [ "${BUILD_OPENBAS}" == "false" ]; then
            ctr=$((ctr - 1))
            continue
        fi
        ORIGIONAL_REPO="openbas"
        IMAGE_VERSION=$OPENBAS_VERSION
        if [ "${path_parts[2]}" == "Collectors" ]; then
            SERVICE_PREFIX="collector"
        else
            SERVICE_PREFIX="injector"
        fi
    fi
    
    if ((ctr <= SKIP_BUILDS)); then
        continue
    fi

    # Create image name
    IMAGE_NAME="${SERVICE_PREFIX}-${SERVICE}"
    IMAGE_TAG="${TAG_PREFIX}/${IMAGE_NAME}:${IMAGE_VERSION}"


    echo "🔨 Building #${buildNr} $IMAGE_TAG from $service_dir for platforms: $PLATFORMS"

    docker buildx build \
        --builder "$BUILDER_NAME" \
        --platform "$PLATFORMS" \
        -t "$IMAGE_TAG" \
        --push \
        "$service_dir"

    echo "✅ Successfully built #${buildNr} and pushed $IMAGE_TAG"

    if (((ctr - SKIP_BUILDS) >= MAX_BUILDS)); then
        tmp=$((ctr - SKIP_BUILDS))
        echo "🛑 Stopping due to max builds reached."
        break
    fi
done