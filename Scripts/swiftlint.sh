#!/bin/sh

export PATH="$PATH:/opt/homebrew/bin"
if [ "${CONFIGURATION}" == "Debug" ]; then
  echo "Running SwiftLint"
  if which swiftlint > /dev/null; then
    swiftlint
  else
    echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
  fi
else
  echo "info: As we're not building for Debug, no SwiftLint is running."
fi
