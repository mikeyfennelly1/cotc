#!/bin/bash

var_must_exist() {
  for var_name in "$@"; do
    if [ -z "${!var_name+x}" ]; then
      echo "environment variable ${var_name} is unset. Exiting..."
      exit 1
    fi
  done
}
