#!/bin/bash

# ================================
# Color codes
# ================================
GREEN='\033[38;5;82m'
ORANGE='\033[38;5;208m'
RED='\033[38;5;196m'
RESET='\033[0m'

# ================================
# Logging functions
# ================================
log_success() { printf "${GREEN}[SUCCESS] %s${RESET}\n" "$1" >&2; }
log_warning() { printf "${ORANGE}[WARNING] %s${RESET}\n" "$1" >&2; }
log_error()   { printf "${RED}[ERROR] %s${RESET}\n" "$1" >&2; exit 1; }
log_info()    { printf "[INFO] %s\n" "$1" >&2; }

# ================================
# Help / usage
# ================================
show_help() {
    cat <<EOF
Usage: $0 [options]

Fetch AWS image from the Talos Factory API.

Options:
  -v, --version <VERSION>    Talos version (default: latest or from stdin/env)
  -a, --arch <ARCH>          Machine type: amd64 | arm64 (default: arm64 or from stdin/env)
  -e, --extensions <JSON>    Talos extensions JSON array (default: [] or from stdin/env)
  -h, --help                 Show this help message and exit
EOF
    exit 0
}

# ================================
# Defaults from environment
# ================================
TALOS_VERSION="${TALOS_VERSION:-latest}"
TALOS_MACHINE_TYPE="${TALOS_MACHINE_TYPE:-arm64}"
TALOS_EXTENSIONS="${TALOS_EXTENSIONS:-[]}"

# ================================
# Read stdin JSON for external provider
# ================================
if [ ! -t 0 ]; then
    # stdin is not empty, read JSON from Packer
    eval "$(jq -r '@sh "STDIN_VERSION=\(.version) STDIN_ARCH=\(.arch) STDIN_EXTENSIONS=\(.extensions)"' 2>/dev/null || echo "")"

    # Override environment defaults if stdin provided values
    TALOS_VERSION="${STDIN_VERSION:-$TALOS_VERSION}"
    TALOS_MACHINE_TYPE="${STDIN_ARCH:-$TALOS_MACHINE_TYPE}"
    TALOS_EXTENSIONS="${STDIN_EXTENSIONS:-$TALOS_EXTENSIONS}"
fi

# ================================
# Parse arguments (CLI overrides everything)
# ================================
while [ $# -gt 0 ]; do
    case "$1" in
        -v|--version)    TALOS_VERSION="$2"; shift 2 ;;
        -a|--arch)       TALOS_MACHINE_TYPE="$2"; shift 2 ;;
        -e|--extensions) TALOS_EXTENSIONS="$2"; shift 2 ;;
        -h|--help)       show_help ;;
        -*)              log_error "Unknown option: $1" ;;
        *)               log_error "Unexpected argument: $1" ;;
    esac
done

# ================================
# Constants
# ================================
TALOS_IMAGE_FACTORY_URL="https://factory.talos.dev"

# ================================
# Functions
# ================================
get_correct_image_version() {
    log_info "Checking version validity (or fetching latest)..."

    log_info "Fetching the list of TalosOS versions from the API ..."
    TALOS_VERSIONS_LIST=$(curl -s -X GET "$TALOS_IMAGE_FACTORY_URL/versions") \
        || log_error "Failed to fetch TalosOS versions from the API"

    if [ -z "$TALOS_VERSION" ] || [ "$TALOS_VERSION" = "latest" ]; then
        log_info "Fetching latest version..."
        TALOS_VERSION=$(echo "$TALOS_VERSIONS_LIST" | jq -r '.[]' \
            | grep -oE '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1)
        log_success "Latest version is $TALOS_VERSION"
    fi

    log_info "Validating version $TALOS_VERSION ..."
    if echo "$TALOS_VERSIONS_LIST" | sed 's/[][]//g' | tr -d '"' | tr ',' '\n' | grep -Fxq "$TALOS_VERSION"; then
        log_success "Version $TALOS_VERSION is valid"
    else
        log_error "Version $TALOS_VERSION is not valid. Valid versions: $TALOS_VERSIONS_LIST"
    fi
}

generate_image_schematic() {
    log_info "Generating the image schematic ..."

    if [ -z "$TALOS_EXTENSIONS" ]; then
        TALOS_EXTENSIONS='[]'
    elif ! echo "$TALOS_EXTENSIONS" | jq empty >/dev/null 2>&1; then
        log_error "Extensions $TALOS_EXTENSIONS is not valid JSON. Use '[\"ext1\", \"ext2\"]'"
    fi

    log_success "Using extensions: $TALOS_EXTENSIONS"

    TALOS_SCHEMATIC_SPECIFICATION=$(jq -n --argjson talos_extensions "$TALOS_EXTENSIONS" \
        '{
            "customization": {
                "extraKernelArgs": [],
                "meta": [{}],
                "systemExtensions": {
                    "officialExtensions": $talos_extensions
                },
                "secureboot": {}
            }
        }')

    RESPONSE=$(curl -s -X POST "$TALOS_IMAGE_FACTORY_URL/schematics" \
        -H "Content-Type: application/json" \
        -d "$TALOS_SCHEMATIC_SPECIFICATION") \
        || log_error "Failed to generate the image schematic"

    TALOS_SCHEMATIC_ID=$(echo "$RESPONSE" | jq -r '.id')
    log_success "Image schematic generated successfully (ID: $TALOS_SCHEMATIC_ID)"
}

fetch_image_from_talos_factory() {
    log_info "Fetching the image from the Talos Factory API..."

    if [ "$TALOS_MACHINE_TYPE" != "amd64" ] && [ "$TALOS_MACHINE_TYPE" != "arm64" ]; then
        log_error "Invalid machine type: $TALOS_MACHINE_TYPE (must be amd64 or arm64)"
    fi
    log_success "Machine type is valid: $TALOS_MACHINE_TYPE"

    IMAGE_URL="$(printf "%s/image/%s/%s/aws-%s.raw.xz" \
        "$TALOS_IMAGE_FACTORY_URL" "$TALOS_SCHEMATIC_ID" "$TALOS_VERSION" "$TALOS_MACHINE_TYPE")"
    OUTPUT_FILE="talos-img.raw.xz"

    log_info "Downloading Talos image from $IMAGE_URL ..."
    curl -fSL "$IMAGE_URL" -o "$OUTPUT_FILE" \
        || log_error "Failed to fetch the image"

    log_success "Image downloaded successfully"
}

# ================================
# Main execution
# ================================
get_correct_image_version
generate_image_schematic
fetch_image_from_talos_factory

# Output JSON for Packer external provider
jq -n \
    --arg version "$TALOS_VERSION" \
    --arg schematic_id "$TALOS_SCHEMATIC_ID" \
    --arg arch "$TALOS_MACHINE_TYPE" \
    '{talos_version: $version, schematic_id: $schematic_id, architecture: $arch}'
