#!/bin/bash
set -e

# mirror the nist data using a cache from github

MY_TMP_DIR=$(mktemp -d)

# 2. Check if the directory creation was successful
if [[ ! -d "$MY_TMP_DIR" ]]; then
    echo "Failed to create a temporary directory" >&2
    exit 1
fi

# 3. Ensure the temporary directory is cleaned up when the script exits
trap 'rm -rf "$MY_TMP_DIR"' EXIT

cd "$MY_TMP_DIR"
echo "Using temp dir $MY_TMP_DIR"

# get all the files from github. Can be done in the following format
# https://github.com/{owner}/{repository}/releases/latest/download/{filename}
my_list=("CVE-all.json.xz" "CVE-all.meta" "CVE-modified.json.xz" "CVE-modified.meta" "CVE-recent.json.xz" "CVE-recent.meta")
for item in "${my_list[@]}"; do
    curl -LO -w "%{url_effective}\n" "https://github.com/fkie-cad/nvd-json-data-feeds/releases/latest/download/$item"
done

# get the year specific files
for year in $(seq 1999 $(date +%Y)); do
    curl -LO -w "%{url_effective}\n" "https://github.com/fkie-cad/nvd-json-data-feeds/releases/latest/download/CVE-$year.meta"
    curl -LO -w "%{url_effective}\n" "https://github.com/fkie-cad/nvd-json-data-feeds/releases/latest/download/CVE-$year.json.xz"
done

# recompress all files that match the name
for file in *.xz; do
    # Check if any .xz files actually exist to avoid errors
    [ -e "$file" ] || continue

    # Extract the base name without the .xz extension
    base_name="${file%.xz}"

    # Decompress and compress on the fly using a pipe
    xz -dc "$file" | gzip -c > "${base_name}.gz"

    echo "Converted $file to ${base_name}.gz"
done

echo "Now we rename the files to be in the pattern expected by dependency check"
for f in CVE-*; do
    [ -e "$f" ] || continue
    mv -n "$f" "nvdcve-${f#CVE-}"
done

find . -type f

echo "Now importing the files using dependency-check-maven"
mvn org.owasp:dependency-check-maven:RELEASE:update-only -DnvdDatafeedUrl="file:///$MY_TMP_DIR"
