#!/bin/sh

if [ "${CONFIGURATION}" == "Debug" ]; then
  if which "${PODS_ROOT}/SwiftLint/swiftlint" >/dev/null; then
    echo "Running SwiftLint"
    "${PODS_ROOT}/SwiftLint/swiftlint"
  else
    echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
  fi
else
  echo "info: As we're not building for Debug, no SwiftLint is running."
fi