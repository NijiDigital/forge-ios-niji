#!/bin/sh
if [ "$ENABLE_PREVIEWS" == "YES" ]; then
  echo "We avoid launching SwiftFormat for SwiftUI previews to avoid conflicts"
  exit 0
fi

export PATH="$PATH:/opt/homebrew/bin"
if [ "${CONFIGURATION}" == "Debug" ]; then
  echo "Running Swift Format"
  if which swiftformat > /dev/null; then
    CONFIG_FILE="$SRCROOT/fastlane/forge/.swiftformat"
    if [ -f "$SRCROOT/.swiftformat" ]; then
        echo "Switching to local .swiftformat"
        CONFIG_FILE="$SRCROOT/.swiftformat"
    fi
    swiftformat . --config $CONFIG_FILE --exclude "$SRCROOT/fastlane/" --exclude "$SRCROOT/Pods/" --exclude "**/Generated/" --exclude "**/*.generated.swift" --exclude "**/Templates/" --exclude "Build/" --exclude "Reports/" --exclude ".build/" --exclude "DerivedData/"
  else
    echo "warning: SwiftFormat not installed, download from https://github.com/nicklockwood/SwiftFormat"
  fi
else
  echo "info: As we're not building for Debug, no SwiftFormat is running."
fi