#!/bin/sh

export PATH="$PATH:/opt/homebrew/bin"
if [ "${CONFIGURATION}" == "Debug" ]; then
  echo "Running Swift Format"
  if which swiftformat > /dev/null; then
    swiftformat . --config "$SRCROOT/fastlane/forge/.swiftformat" --exclude "$SRCROOT/fastlane/" --exclude "$SRCROOT/Pods/" --exclude "**/Generated/" --exclude "**/Templates/" --exclude "Build/" --exclude "Reports/" --exclude ".build/" --exclude "DerivedData/"
  else
    echo "warning: SwiftFormat not installed, download from https://github.com/nicklockwood/SwiftFormat"
  fi
else
  echo "info: As we're not building for Debug, no SwiftFormat is running."
fi