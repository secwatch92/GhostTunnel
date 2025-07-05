#!/bin/bash
# Helper functions for the deployment scripts

# Status display function
status() {
  echo -e "\n\033[1;32m>>> $1\033[0m"
}

# Error checking function
check_error() {
  if [ $? -ne 0 ]; then
    echo -e "\n\033[1;31mERROR: $1\033[0m"
    exit 1
  fi
}
