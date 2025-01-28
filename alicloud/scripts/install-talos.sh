#!/bin/bash

set -eo pipefail

# Color codes
GREEN='\033[38;5;82m'   # Bright green
ORANGE='\033[38;5;208m' # Bright orange
RED='\033[38;5;196m'    # Bright red
RESET='\033[0m'         # Reset to default color

# Logging functions for colored messages
log_success() {
    echo -e "${GREEN}[SUCCESS] $1${RESET}"
}

log_warning() {
    echo -e "${ORANGE}[WARNING] $1${ORANGE}"
}

log_error() {
    echo -e "${RED}[ERROR] $1${RESET}"
}

log_info() {
    echo -e "[INFO] $1"
}

# Help function to display usage
show_help() {
    echo "Usage: $0 [TALOS_VERSION]"
    echo
    echo "Fetch Alicloud image from the Talos Factory API."
    echo
    echo "Arguments:"
    echo "  TALOS_VERSION  (Optional) Specify the Talos version to use."
    echo
    echo "Examples:"
    echo "  $0            Fetch latest version."
    echo "  $0 v1.0.0     Fetch version v1.0.0."
    echo
    exit 0
}

# Check if help flag is used
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
fi

# Function to check if the version is valid
get_correct_image_version() {
    log_info "Checking if the provided version is valid or fetching the latest image if the version was not specified..."

    # Get the list of versions from the Talos Factory API
    TALOS_VERSIONS_LIST=$(curl -s -X GET $TALOS_IMAGE_FACTORY_URL/versions)

    # Check if the curl command was successful
    if [[ $? -ne 0 ]]; then
        log_error "Error: Failed to fetch TalosOS versions from the API"
        exit 1
    fi

    if [[ -z "$TALOS_VERSION" || "$TALOS_VERSION" == "latest" ]]; then
        log_info "Fetching latest version..."
        TALOS_VERSION=$(echo "$TALOS_VERSIONS_LIST" | jq -r '.[]' | grep -oE '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1)
        log_success "Latest version is $TALOS_VERSION"
    fi

    # Validate if the provided version exists in the list
    if [[ "$TALOS_VERSIONS_LIST" == *"$TALOS_VERSION"* ]]; then
        log_success "Version $TALOS_VERSION is valid"
    else
        log_error "Error: Version $TALOS_VERSION is not valid. Please provide one of the valid versions which are: $TALOS_VERSIONS_LIST"
        exit 1
    fi
}

# Function to generate the image schematic for the Alicloud image
generate_image_schematic() {
    log_info "Generating the image schematic for the Alicloud image..."



}

fetch_image_from_talos_factory() {
    log_info "Fetching the image from the Talos Factory API..."




}


# INPUTS
TALOS_VERSION=$1

# Constants
TALOS_IMAGE_FACTORY_URL="https://factory.talos.dev"

# Check if the version is valid
get_correct_image_version

# Generate the image schematic
generate_image_schematic

# Fetch the image from the Talos Factory API
