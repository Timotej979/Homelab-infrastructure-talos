#!/bin/bash

set -eo pipefail

# Color codes
GREEN='\033[38;5;82m'   # Bright green
ORANGE='\033[38;5;208m' # Bright orange
RED='\033[38;5;196m'    # Bright red
RESET='\033[0m'         # Reset to default color

# Logging functions for colored messages
log_success() {
    printf "${GREEN}[SUCCESS] %s${RESET}\n" "$1"
}

log_warning() {
    printf "${ORANGE}[WARNING] %s${ORANGE}\n" "$1"
}

log_error() {
    printf "${RED}[ERROR] %s${RESET}\n" "$1"
}

log_info() {
    printf "[INFO] %s\n" "$1"
}

# Help function to display usage
show_help() {
    echo "Usage: $0 [TALOS_VERSION] [TALOS_MACHINE_TYPE] [TALOS_EXTENSIONS]"
    echo
    echo "Fetch Hetzner image from the Talos Factory API."
    echo
    echo "Arguments:"
    echo "  TALOS_VERSION       (Optional) Specify the Talos version to use."
    echo "  TALOS_MACHINE_TYPE  (Optional) Specify the Talos machine type to use."
    echo "                                 The only option is amd64 (Default is amd64)."
    echo "  TALOS_EXTENSIONS    (Optional) Specify the Talos extensions to use."
    echo "                                 Check list of available extensions at https://github.com/siderolabs/extensions"
    echo 
    echo "Examples:"
    echo "  $0                                                             Fetch latest version with arm64 machine type."
    echo "  $0 v1.9.3                                                      Fetch version v1.9.3."
    echo "  $0 v1.9.3 amd64                                                Fetch version v1.9.3 with amd64 machine type."
    echo "  $0 v1.9.3 amd64 '["siderolabs/gvisor", "siderolabs/amd-ucode"]'    Fetch version v1.9.3 with extensions."
    echo 
    exit 0
}

# Check if help flag is used
if [ "$1" == "--help" || "$1" == "-h" ]; then
    show_help
fi

# Function to check if the version is valid
get_correct_image_version() {
    log_info "Checking if the provided version is valid or fetching the latest image if the version was not specified ..."

    # Get the list of versions from the Talos Factory API
    log_info "Fetching the list of TalosOS versions from the API ..."
    TALOS_VERSIONS_LIST=$(curl -s -X GET $TALOS_IMAGE_FACTORY_URL/versions)

    # Check if the curl command was successful
    if [ $? -ne 0 ]; then
        log_error "Error: Failed to fetch TalosOS versions from the API"
        exit 1
    fi

    # Fetch the latest version if the version is not provided
    if [ -z "$TALOS_VERSION" ] || [ "$TALOS_VERSION" = "latest" ]; then
        log_info "Fetching latest version..."
        TALOS_VERSION=$(echo "$TALOS_VERSIONS_LIST" | jq -r '.[]' | grep -oE '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1)
        log_success "Latest version is $TALOS_VERSION"
    fi

    # Validate if the provided version exists in the list
    log_info "Validating the version provided/extracted ..."
    if echo "$TALOS_VERSIONS_LIST" | sed 's/[][]//g' | tr -d '"' | tr ',' '\n' | grep -Fxq "$TALOS_VERSION"; then
        log_success "Version $TALOS_VERSION is valid"
    else
        log_error "Error: Version $TALOS_VERSION is not valid. Please provide one of the valid versions which are: $TALOS_VERSIONS_LIST"
        exit 1
    fi

    export TALOS_VERSION=$TALOS_VERSION
}

# Function to generate the image schematic for the Alicloud image
generate_image_schematic() {
    log_info "Generating the image schematic for the Alicloud image ..."

    # Check the validity of the extensions
    log_info "Checking the validity of the extensions ..."
    if [ -z "$TALOS_EXTENSIONS" ]; then
        TALOS_EXTENSIONS='[]'   # Default value
    elif ! echo "$TALOS_EXTENSIONS" | jq empty > /dev/null 2>&1; then
        log_error "Error: Extensions $TALOS_EXTENSIONS is not a valid JSON array. Please provide the extensions in the format '[\"extension1\", \"extension2\"]'"
        exit 1
    fi
    log_success "Extensions are valid, using the following list of extencions:"
    log_success "$TALOS_EXTENSIONS"

    # Generate the image schematic to send to the API
    log_info "Generating the image schematic to send to the API ..."
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

    # Send the image schematic to the Talos Factory API
    log_info "Sending the image schematic to the Talos Factory API ..."
    RESPONSE=$(curl -s -X POST $TALOS_IMAGE_FACTORY_URL/schematics \
                                 -H "Content-Type: application/json" \
                                 -d "$TALOS_SCHEMATIC_SPECIFICATION")

    # Check if the curl command was successful
    if [ $? -ne 0 ]; then
        log_error "Error: Failed to generate the image schematic"
        exit 1
    else
        log_success "Image schematic generated successfully"
    fi

    # Extract the schematic ID from the response
    log_info "Extracting the schematic ID from the response ..."
    TALOS_SCHEMATIC_ID=$(echo $RESPONSE | jq -r '.id')

    export TALOS_SCHEMATIC_ID=$TALOS_SCHEMATIC_ID
}

fetch_image_from_talos_factory() {
    log_info "Fetching the image from the Talos Factory API..."

    # Check validity of the machine type
    log_info "Checking the validity of the machine type ..."
    if [ -z "$TALOS_MACHINE_TYPE" ]; then
        TALOS_MACHINE_TYPE="amd64"  # Default value
    elif [ "$TALOS_MACHINE_TYPE" != "amd64" ]; then
        log_error "Error: Machine type $MACHINE_TYPE is not valid. Please provide one of the valid machine types which are: amd64"
        exit 1
    fi
    log_success "Machine type is valid, using $TALOS_MACHINE_TYPE"

    # Fetch the image from the Talos Factory API
    log_info "Fetching the image from the Talos Factory API ..."
    curl -X GET $TALOS_IMAGE_FACTORY_URL/image/$TALOS_SCHEMATIC_ID/$TALOS_VERSION/hcloud-$TALOS_MACHINE_TYPE.raw.xz -o talos-img.raw.xz

    # Check if the curl command was successful
    if [ $? -ne 0 ]; then
        log_error "Error: Failed to fetch the image from the Talos Factory API"
        exit 1
    else
        log_success "Machine image for Hetzner cloud for $TALOS_MACHINE_TYPE fetched successfully"
    fi
}


# INPUTS
TALOS_VERSION=$1
TALOS_MACHINE_TYPE=$2
TALOS_EXTENSIONS=$3

# Constants
TALOS_IMAGE_FACTORY_URL="https://factory.talos.dev"

# Check Talos version
get_correct_image_version

# Generate the image schematic
generate_image_schematic

# Fetch the image from the Talos Factory API
fetch_image_from_talos_factory

# Output JSON to STDOUT so Packer can parse it
echo "{\"version\": \"$TALOS_VERSION\", \"arch\": \"$TALOS_MACHINE_TYPE\"}"