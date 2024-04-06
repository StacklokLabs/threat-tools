#!/bin/bash

# Usage: ./get_npm_users.sh --usernames=user1,user2,user3

fetch_packages_for_user() {
    local username="$1"
    local output_file="${username}_packages.json"
    local packages=()
    local url="https://registry.npmjs.org/-/v1/search?text=maintainer:${username}&size=5000"

    # Pagination handling
    while : ; do
        # Fetch the package data
        response=$(curl -s "$url")
        
        # Extract package names from the current page
        current_page_packages=$(echo "$response" | jq -r '.objects[] | .package.name')
        
        # If no packages are found, break the loop
        if [[ -z "$current_page_packages" ]]; then
            break
        fi

        # Add package names to the list
        packages+=($current_page_packages)
        
        # Get the URL for the next page
        local next_url=$(echo "$response" | jq -r '.urls.next // empty')
        if [[ -z "$next_url" ]]; then
            break
        fi
        url="$next_url"
    done

    # Convert the array of packages to a JSON array
    local json_packages_array=$(printf '%s\n' "${packages[@]}" | jq -R . | jq -s .)

    # Create final JSON object with username and package list
    echo "{\"username\": \"$username\", \"packages\": $json_packages_array}" > "$output_file"

    echo "Package list for $username saved to $output_file"
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
