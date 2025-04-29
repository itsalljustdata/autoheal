# Docker Autoheal

A containerized solution that automatically restarts unhealthy Docker containers.

## Overview

Docker Autoheal is a lightweight, secure monitoring system that checks for containers marked with health checks and automatically restarts them if they're detected to be in an unhealthy state. It consists of two main components:

1. **Autoheal Service**: Monitors containers with health checks and initiates restarts when needed
2. **Socket Proxy Service**: Provides a secure interface to the Docker socket with fine-grained permissions ([tecnativa/docker-socket-proxy](https://github.com/Tecnativa/docker-socket-proxy))

## Features

- **Automatic Container Recovery**: Automatically restarts unhealthy containers
- **Label-based Monitoring**: Only monitors containers with the `autoheal=true` label
- **Secure Docker Socket Access**: Uses a proxy to limit access to the Docker API
- **Isolated Network**: Internal network prevents external communication
- **Flexible Configuration**: Environment variables control behavior

## Security

The setup includes several security measures:

- The Docker socket is not directly exposed to the autoheal container
- The socket proxy limits API access to only the necessary endpoints
- The network is configured as internal, preventing external communication
- All operations are performed through a restricted API proxy

## Setup and Configuration

### Prerequisites
- Docker and Docker Compose installed
- Proper permissions to interact with Docker

### Installation

1. Clone this repository
2. Set up environment variables in `.env` file or use the defaults
3. Launch with Docker Compose

```bash
docker-compose up -d
```

### Environment Variables

The following environment variables can be configured:

- `CONTAINER_NAME_AUTOHEAL`: Name for the autoheal container (default: `autoheal`)
- `CONTAINER_NAME_PROXY`: Name for the socket proxy (derived from autoheal name)

## How It Works

1. The autoheal container runs a health check script every 30 seconds
2. The script identifies containers with the `autoheal=true` label that also have health checks
3. For each monitored container, it checks the health status via the Docker API
4. When an unhealthy container is detected, it issues a restart command

## Usage

To enable automatic healing for a container, add the following to your container configuration:

1. Set the `autoheal=true` label
2. Define a health check for your container

Example:

```yaml
services:
  my-service:
    image: my-image
    labels:
      - "autoheal=true"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

## Troubleshooting

- Check the logs of the autoheal container for diagnostic information:
  ```bash
  docker logs autoheal
  ```
- Ensure containers have proper health checks defined
- Verify that the `autoheal=true` label is applied to containers you want monitored

## Technical Details

The system consists of:

- **autoheal.sh**: Main script that checks and restarts unhealthy containers
- **socket-proxy**: HAProxy-based Docker socket proxy for secure API access
- **docker-socket-proxy.env**: Environment configuration for API permissions
- **haproxy.cfg**: HAProxy configuration for the socket proxy. Modification to default one based on [issue #123](https://github.com/Tecnativa/docker-socket-proxy/issues/123) in [tecnativa/docker-socket-proxy](https://github.com/Tecnativa/docker-socket-proxy).
- **server-state**: empty file for binding to avoid warning in [tecnativa/docker-socket-proxy](https://github.com/Tecnativa/docker-socket-proxy).
- **healthcheck-proxy.sh**: Healthcheck script for proxy container

## License

This project is licensed under the GNU General Public License v3 (GPL-3.0).
