#!/bin/sh

# Get container IDs without Bash array syntax
docker compose ps -q | while read -r c; do
    # Single docker inspect command to get container name, image details, and health information
    docker inspect "$c" | jq '.[0] | {
        Name: (.Name | sub("^/"; "")),
        Image: .Config.Image,
        image: {
            repository: (.Config.Image | split(":")[0]),
            tag: (if (.Config.Image | contains(":")) then (.Config.Image | split(":")[1]) else "latest" end)
        },
        Health: .State.Health
    }'
done