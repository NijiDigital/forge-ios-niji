#!/bin/sh
if [ "$ENABLE_PREVIEWS" == "YES" ]; then
  echo "We avoid launching SwiftFormat for SwiftUI previews to avoid conflicts"
  exit 0
fi

export PATH="$PATH:/opt/homebrew/bin"
if [ "${CONFIGURATION}" == "Debug" ]; then
  echo "Running Swift Format"
  if which swiftformat > /dev/null; then
    swiftformat .
  fi
else
  echo "info: As we're not building for Debug, no SwiftFormat is running."
fi