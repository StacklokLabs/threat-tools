#!/bin/bash

# Usage: ./get_keys.sh --usernames=user1,user2,user3

fetch_packages_for_user() {
    local username="$1"
    local output_file="${username}_packages.json"
    local public_key_file="${username}_public_keys.txt"
    local packages=()
    local from=0
    local size=100
    local total_packages

    # Fetch the total number of packages first
    total_packages=$(curl -s "https://registry.npmjs.org/-/v1/search?text=maintainer:${username}" | jq '.total')

    if [[ -z "$total_packages" ]]; then
        echo "No packages found for user: ${username}"
        exit 1
    fi

    # Continue fetching until we reach the total number of packages
    while [ $from -lt $total_packages ]; do
        echo "Fetching packages $from to $(($from + $size)) for user $username"
        # Fetch the package data
        response=$(curl -s "https://registry.npmjs.org/-/v1/search?text=maintainer:${username}&size=${size}&from=${from}")

        # Extract package names from the current page
        current_page_packages=$(echo "$response" | jq -r '.objects[].package.name')

        # If no packages are found, break the loop
        if [ -z "$current_page_packages" ]; then
            echo "No more packages found."
            break
        fi

        # Add package names to the list
        packages+=($current_page_packages)

        # Increase the 'from' for the next iteration
        from=$(($from + $size))
    done



    # Convert the array of packages to a JSON array
    json_array=$(printf '%s\n' "${packages[@]}" | jq -R . | jq -s .)

    # Create the final JSON object
    echo "{\"username\":\"$username\", \"packages\":$json_array}" > "$output_file"

    echo "Package list for $username saved to $output_file"

    # Iterate over each package name
    for pkg in $current_page_packages; do
        echo "Processing package: $pkg"

        # Use npm pack to download the tarball and capture its name
        tarball=$(npm pack "$pkg" 2>/dev/null)

        if [[ ! -f "$tarball" ]]; then
            echo "Tarball not found for package: $pkg"
            continue
        fi

        # Create a directory for the package
        pkg_dir=$(echo "$pkg" | sed 's/@//;s/\//-/g')
        mkdir "$pkg_dir"

        # Extract the tarball into the directory
        tar -xzf "$tarball" -C "$pkg_dir" --strip-components=1
        rm "$tarball"

        # Search for 'tea.yaml' files and extract hex strings / eth pub keys
        find "$pkg_dir" -name 'tea.yaml' -exec grep -Eo '0x[a-fA-F0-9]{40}' {} \; | while read -r hex_string; do
            echo "Found hex string in $pkg: $hex_string"
            # Append the package name and hex string to the output file
            echo "$pkg: $hex_string" >> "$public_key_file"
        done

        # Cleanup
        rm -rf "$pkg_dir"
    done

    echo "Hex strings saved to $public_key_file"
}

# Parse the command line argument for usernames
for i in "$@"; do
    case $i in
        --usernames=*)
        usernames="${i#*=}"
        ;;
        *)
        echo "Unknown option: $i"
        exit 1
        ;;
    esac
done

# Check if the usernames variable is set, if not, show usage
if [[ -z $usernames ]]; then
    echo "Usage: $0 --usernames=user1,user2,user3"
    exit 1
fi

# Split the usernames and call the function for each user
IFS=',' read -ra ADDR <<< "$usernames"
for username in "${ADDR[@]}"; do
    fetch_packages_for_user "$username"
done
