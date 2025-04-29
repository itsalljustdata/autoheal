#!/bin/sh
echo "Running container health check"

# Get all containers with healthcheck and autoheal label
AUTO_DETECT_CONTAINERS=$(docker ps --format '{{.Names}}' --filter 'label=autoheal=true')

if [ -n "${AUTO_DETECT_CONTAINERS}" ]; then
    echo "Auto-detected containers with autoheal=true label: ${AUTO_DETECT_CONTAINERS}"
    CONTAINERS_TO_CHECK="${AUTO_DETECT_CONTAINERS}"
else
    echo "No containers found with autoheal=true label."
    exit 0
fi

# Initialize array for containers with healthcheck
MONITORED_CONTAINERS=""

# Populate array with only containers that have healthchecks defined
for container in ${CONTAINERS_TO_CHECK}; do
    if docker inspect ${container} >/dev/null 2>&1; then
        has_health=$(docker inspect -f '{{if .Config.Healthcheck}}true{{else}}false{{end}}' ${container} 2>/dev/null)
        if [ "$has_health" = "true" ]; then
            MONITORED_CONTAINERS="${MONITORED_CONTAINERS} ${container}"
        # else
        #     echo "${container} does not have a healthcheck defined - skipping"
        fi
    else
        echo "Container ${container} not found - skipping"
    fi
done

# Trim leading space if any
MONITORED_CONTAINERS=$(echo "${MONITORED_CONTAINERS}" | sed 's/^ *//')

if [ -z "${MONITORED_CONTAINERS}" ]; then
    echo "No containers with healthchecks found."
    exit 0
fi

echo "Checking containers with healthchecks: ${MONITORED_CONTAINERS}"

# Check all monitored containers and restart if unhealthy
EXIT_CODE=0
for container in ${MONITORED_CONTAINERS}; do
    {
        # Check if container exists and is running
        if docker inspect --format '{{.State.Running}}' ${container} >/dev/null 2>&1; then
            status=$(docker inspect -f '{{.State.Health.Status}}' ${container} 2>/dev/null)
            if [ "$status" = "unhealthy" ]; then
                echo "${container} is unhealthy - restarting"
                docker restart ${container} > /dev/null
                echo "${container} restart initiated"
                EXIT_CODE=1
            fi
        else
            echo "Container ${container} not running or not found"
        fi
    } || {
        echo "Error while checking ${container}"
        EXIT_CODE=1
    }
done

# Exit with 0 if all checks pass, 1 if there were issues
exit ${EXIT_CODE}