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
OPENBAS_VERSION="${5:-false}"

# Ensure buildx builder exists
if ! docker buildx inspect "$BUILDER_NAME" >/dev/null 2>&1; then
    echo "❌ Buildx builder '$BUILDER_NAME' does not exist."
    exit 1
fi

docker buildx use "$BUILDER_NAME"

# Find Dockerfiles recursively
ctr=0
find "$BASE_DIR" -type f -name 'Dockerfile' | sort | awk '
  BEGIN {
    while ((getline pattern < "filter.txt") > 0) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", pattern);  # trim whitespace
      patterns[pattern] = 1;
    }
  }
  {
    for (p in patterns) {
      if (index($0, p) > 0) {
        print $0;
        break;
      }
    }
  }
' | while read -r dockerfile; do
    service_dir=$(dirname "$dockerfile")
    
    # Filters out directories that shouldn't be parsed
    if [[ "$service_dir" =~ (/templates/|/shared/) ]]; then
        continue
    fi

    # Extract category and service from the path
    path_parts=(${service_dir//\// })
    SERVICE="${path_parts[-1]}"
    ORIGIONAL_REPO="NOTGOOD"
    SERVICE_PREFIX="NOTGOOD"
    if [ "${path_parts[1]}" == "OpenCTI" ]; then
        ORIGIONAL_REPO="opencti"
        IMAGE_VERSION=$OPENCTI_VERSION
        if [ "${path_parts[2]}" == "Connectors" ]; then
            SERVICE_PREFIX="connector"
        fi
    else
        ORIGIONAL_REPO="openbas"
        IMAGE_VERSION=$OPENBAS_VERSION
        if [ "${path_parts[2]}" == "Collectors" ]; then
            SERVICE_PREFIX="collector"
        else
            SERVICE_PREFIX="injector"
        fi
    fi
    ctr=$((ctr + 1))
    buildNr=$((ctr))

    # Create image name
    IMAGE_NAME="${SERVICE_PREFIX}-${SERVICE}"
    IMAGE_TAG="${TAG_PREFIX}/${IMAGE_NAME}:${IMAGE_VERSION}"


    echo "🔨 Building #${buildNr} $IMAGE_TAG from $service_dir for platforms: $PLATFORMS"

    #docker buildx build \
    #    --builder "$BUILDER_NAME" \
    #    --platform "$PLATFORMS" \
    #    -t "$IMAGE_TAG" \
    #    --push \
    #    "$service_dir"

    echo "✅ Successfully built #${buildNr} and pushed $IMAGE_TAG"
done