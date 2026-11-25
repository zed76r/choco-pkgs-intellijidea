#!/bin/bash

set -euo pipefail
export LC_ALL=C
cd -- "$(dirname -- "$0")"

fail() {
    printf '%s\n' "$*" >&2
    exit 1
}

fetch() {
    curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' \
        --retry 2 --connect-timeout 10 --max-time 30 "$1"
}

version_key() {
    local major minor patch revision
    IFS=. read -r major minor patch revision <<< "$1"
    printf '%09d%09d%09d%09d' "$((10#$major))" "$((10#$minor))" \
        "$((10#${patch:-0}))" "$((10#${revision:-0}))"
}

[[ $# == 1 ]] || fail "Usage: $0 <version|--latest>"
version_pattern='^[0-9]{1,9}(\.[0-9]{1,9}){1,3}$'
sha_pattern='^[[:xdigit:]]{64}$'
auto=false
if [[ $1 == --latest ]]; then
    auto=true
    release=$(fetch 'https://data.services.jetbrains.com/products/releases?code=IIU&latest=true&type=release')
    fields=$(jq -er '.IIU | select(length == 1) | .[0] | select(.type == "release") |
        [.version, .downloads.windows.link, .downloads.windows.checksumLink] | @tsv' <<< "$release") \
        || fail 'JetBrains did not return a single stable Windows release.'
    IFS=$'\t' read -r version url checksum_url <<< "$fields"
else
    version=$1
    url="https://download.jetbrains.com/idea/idea-${version}.exe"
    checksum_url="${url}.sha256"
fi

[[ $version =~ $version_pattern ]] || fail 'Invalid IntelliJ IDEA version.'
[[ $url == "https://download.jetbrains.com/idea/idea-${version}.exe" && $checksum_url == "${url}.sha256" ]] \
    || fail 'Unexpected JetBrains installer or checksum URL.'

editions=(community ultimate unified)
for edition in "${editions[@]}"; do
    spec="$edition/intellijidea-$edition.nuspec"
    install="$edition/tools/chocolateyInstall.ps1"
    current=$(sed -nE 's/^[[:space:]]*<version>([^<]+)<\/version>[[:space:]]*$/\1/p' "$spec")
    current_url=$(sed -nE "s/^\\\$url = '([^']+)'[[:space:]]*$/\1/p" "$install")
    current_sha=$(sed -nE "s/^\\\$sha256sum = '([^']+)'[[:space:]]*$/\1/p" "$install")
    [[ $current =~ $version_pattern && $current_sha =~ $sha_pattern &&
        $current_url == "https://download.jetbrains.com/idea/idea-${current}.exe" ]] \
        || fail "Unexpected current package fields for $edition."

    if $auto; then
        if [[ $edition == community ]]; then
            base_version=$current
            base_url=$current_url
            base_sha=$current_sha
        else
            [[ $current == "$base_version" && $current_url == "$base_url" && $current_sha == "$base_sha" ]] \
                || fail 'Current package versions, URLs or checksums differ.'
        fi
    fi
done

if $auto; then
    candidate_key=$(version_key "$version")
    base_key=$(version_key "$base_version")
    if [[ $candidate_key < $base_key ]]; then
        printf 'Keeping %s because JetBrains returned an older release (%s).\n' "$base_version" "$version"
        exit 0
    fi
fi

checksum=$(fetch "$checksum_url" | awk 'NF {print tolower($1)}')
[[ $checksum =~ $sha_pattern ]] || fail 'JetBrains did not return a valid SHA256 checksum.'

if $auto && [[ $candidate_key == "$base_key" ]]; then
    [[ $url == "$base_url" && $checksum == "$(tr '[:upper:]' '[:lower:]' <<< "$base_sha")" ]] \
        || fail "JetBrains changed the installer URL or SHA256 for existing version $base_version."
    printf 'Already at %s.\n' "$base_version"
    exit 0
fi

backup=".idea-update-$$"
for edition in "${editions[@]}"; do
    spec="$edition/intellijidea-$edition.nuspec"
    install="$edition/tools/chocolateyInstall.ps1"
    sed -i"$backup" -E "s|^([[:space:]]*)<version>[^<]+</version>([[:space:]]*)$|\1<version>${version}</version>\2|" "$spec"
    sed -i"$backup" -E \
        -e "s|^(\\\$url = )'[^']+'([[:space:]]*)$|\1'${url}'\2|" \
        -e "s|^(\\\$sha256sum = )'[^']+'([[:space:]]*)$|\1'${checksum}'\2|" "$install"
    rm -- "${spec}${backup}" "${install}${backup}"
done

printf 'Updated the three IntelliJ IDEA packages to %s.\n' "$version"
