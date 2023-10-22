#!/bin/sh

CURRENT_FILE=$(basename "$0")

# Set github output variable
set_output() {
  echo "$1=$2" >> "$GITHUB_OUTPUT"
}

# Logging functions
info() {
  echo "::info::$*" >&2
}
warn() {
  echo "::warning file=$CURRENT_FILE::$*" >&2
}
error() {
  echo "::error file=$CURRENT_FILE::$*" >&2
}

# Variable tests
# Check if variable is empty
is_empty() {
  if [ "$1" = "" ]; then
    true
  else
    false
  fi
}
# Check if variable is truthy
# Unknown values will return false
is_true() {
  if [ "$1" = "yes" ] || [ "$1" = "true" ] || [ "$1" = "1" ]; then
    true
  else
    false
  fi
}
