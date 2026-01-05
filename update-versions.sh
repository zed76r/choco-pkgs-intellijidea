#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if version is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Version number is required${NC}"
    echo "Usage: ./update-versions.sh <version>"
    echo "Example: ./update-versions.sh 2025.3.2"
    exit 1
fi

VERSION="$1"
COMMUNITY_URL="https://download.jetbrains.com/idea/idea-${VERSION}.exe"
ULTIMATE_URL="https://download.jetbrains.com/idea/ideaIU-${VERSION}.exe"

echo -e "${YELLOW}Updating IntelliJ IDEA to version ${VERSION}${NC}"
echo ""

# Fetch SHA256 checksums
echo -e "${YELLOW}Fetching Community Edition SHA256...${NC}"
COMMUNITY_SHA=$(curl -sL "${COMMUNITY_URL}.sha256" | awk '{print $1}')
if [ -z "$COMMUNITY_SHA" ]; then
    echo -e "${RED}Error: Could not fetch Community Edition SHA256${NC}"
    exit 1
fi
echo -e "${GREEN}Community SHA256: ${COMMUNITY_SHA}${NC}"

echo ""
echo -e "${YELLOW}Fetching Ultimate Edition SHA256...${NC}"
ULTIMATE_SHA=$(curl -sL "${ULTIMATE_URL}.sha256" | awk '{print $1}')
if [ -z "$ULTIMATE_SHA" ]; then
    echo -e "${RED}Error: Could not fetch Ultimate Edition SHA256${NC}"
    exit 1
fi
echo -e "${GREEN}Ultimate SHA256: ${ULTIMATE_SHA}${NC}"

echo ""
echo -e "${YELLOW}Updating files...${NC}"

# Update community version
echo "Updating community/intellijidea-community.nuspec..."
sed -i '' "s/<version>.*<\/version>/<version>${VERSION}<\/version>/" community/intellijidea-community.nuspec

echo "Updating community/tools/chocolateyInstall.ps1..."
sed -i '' "s|'https://download.jetbrains.com/idea/idea-.*.exe'|'${COMMUNITY_URL}'|" community/tools/chocolateyInstall.ps1
sed -i '' "s/\$sha256sum = '[^']*'/\$sha256sum = '${COMMUNITY_SHA}'/" community/tools/chocolateyInstall.ps1

# Update ultimate version
echo "Updating ultimate/intellijidea-ultimate.nuspec..."
sed -i '' "s/<version>.*<\/version>/<version>${VERSION}<\/version>/" ultimate/intellijidea-ultimate.nuspec

echo "Updating ultimate/tools/chocolateyInstall.ps1..."
sed -i '' "s|'https://download.jetbrains.com/idea/ideaIU-.*.exe'|'${ULTIMATE_URL}'|" ultimate/tools/chocolateyInstall.ps1
sed -i '' "s/\$sha256sum = '[^']*'/\$sha256sum = '${ULTIMATE_SHA}'/" ultimate/tools/chocolateyInstall.ps1

# Update unified version
echo "Updating unified/intellijidea-unified.nuspec..."
sed -i '' "s/<version>.*<\/version>/<version>${VERSION}<\/version>/" unified/intellijidea-unified.nuspec

echo "Updating unified/tools/chocolateyInstall.ps1..."
sed -i '' "s|'https://download.jetbrains.com/idea/idea-.*.exe'|'${COMMUNITY_URL}'|" unified/tools/chocolateyInstall.ps1
sed -i '' "s/\$sha256sum = '[^']*'/\$sha256sum = '${COMMUNITY_SHA}'/" unified/tools/chocolateyInstall.ps1

echo ""
echo -e "${GREEN}✓ All files updated successfully!${NC}"
echo ""
echo -e "${YELLOW}Summary:${NC}"
echo "Version: ${VERSION}"
echo "Community URL: ${COMMUNITY_URL}"
echo "Community SHA256: ${COMMUNITY_SHA}"
echo "Ultimate URL: ${ULTIMATE_URL}"
echo "Ultimate SHA256: ${ULTIMATE_SHA}"
