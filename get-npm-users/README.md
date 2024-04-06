# Script to retrieve all npm packages published by a user

This is script is useful for performing a mass report on all packages published by a netfarious user.

It outputs to a simple json format which can then be serialized into any format you need.

## Usage

```bash
./get_npm_user_pkgs.sh.sh --usernames=username1,username2,username3
```

This script will output all of the packages published by the specified users to a file named `${username}_packages.txt`.

## Requirements

Just jq and curl.
