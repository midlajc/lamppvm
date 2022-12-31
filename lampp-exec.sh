#!/usr/bin/env bash

DIR="$(command cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck disable=SC1090,SC1091
\. "$DIR/lamppvm.sh" --no-use

if [ -n "$LAMPP_VERSION" ]; then
  lamppvm use "$LAMPP_VERSION" > /dev/null || exit 127
elif ! lamppvm use >/dev/null 2>&1; then
  echo "No LAMPP_VERSION provided; no .lamppvmrc file found" >&2
  exit 127
fi

exec "$@"
