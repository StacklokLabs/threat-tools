# Tea Public Key Retrieval Script

This script is used to retrieve the public keys used in every package
uploaded by an attacker to the npm registry. The script uses the npm
registry API to retrieve the public keys of the packages uploaded by
the attacker.

## Usage

```bash
./get_keys.sh --usernames=username1,username2,username3
```

The script will output the public keys of the packages to a file named
`${username}_public_keys.txt`.

## Requirements

Just jq and curl.