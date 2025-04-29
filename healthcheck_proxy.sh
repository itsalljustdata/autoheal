#!/bin/sh
set -e
# Check if Docker is running
info=$(wget -q -O - http://127.0.0.1:2375/info)