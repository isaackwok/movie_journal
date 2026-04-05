#!/bin/bash
set -euo pipefail

# ============================================================
# deploy.sh — Build and upload Movie Journal to App Store Connect
# Usage: ./deploy.sh [--build-number N]
# ============================================================

# --- Load credentials ---
if [[ -f .deploy.env ]]; then
    source .deploy.env
fi
API_KEY="${ASC_API_KEY:?ERROR: Set ASC_API_KEY in .deploy.env or environment}"
API_ISSUER="${ASC_API_ISSUER:?ERROR: Set ASC_API_ISSUER in .deploy.env or environment}"

# --- Parse arguments ---
BUILD_NUMBER_ARG=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --build-number)
            BUILD_NUMBER_ARG="--build-number $2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# --- Clean & install ---
echo "==> Cleaning previous build..."
flutter clean

echo "==> Installing dependencies..."
flutter pub get

# --- Build IPA ---
echo "==> Building IPA for App Store..."
flutter build ipa --release $BUILD_NUMBER_ARG

IPA_PATH=$(find build/ios/ipa -name "*.ipa" 2>/dev/null | head -1)
if [[ -z "$IPA_PATH" ]]; then
    echo "ERROR: No IPA file found in build/ios/ipa/"
    exit 1
fi
echo "==> Built: $IPA_PATH"

# --- Validate ---
echo "==> Validating IPA..."
xcrun altool --validate-app \
    -f "$IPA_PATH" \
    --apiKey "$API_KEY" \
    --apiIssuer "$API_ISSUER" \
    --type ios

# --- Upload ---
echo "==> Uploading to App Store Connect..."
xcrun altool --upload-package "$IPA_PATH" \
    --apiKey "$API_KEY" \
    --apiIssuer "$API_ISSUER" \
    --type ios

echo ""
echo "==> Upload complete!"
echo "    The build will appear in TestFlight within ~15-30 minutes."
echo "    No manual encryption compliance step needed."
