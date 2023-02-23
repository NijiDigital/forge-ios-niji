#!/bin/sh

if [ "${CONFIGURATION}" == "Debug" ]; then
  #if which "${PODS_ROOT}/SwiftFormat/CommandLineTool/swiftformat" >/dev/null; then
  echo "Running Swift Format"
  #  "${PODS_ROOT}/SwiftFormat/CommandLineTool/swiftformat" "$SRCROOT"
  #else
  #echo "warning: SwiftFormat not installed, download from https://github.com/nicklockwood/SwiftFormat"
  #fi
  bundle exec fastlane format
else
  echo "info: As we're not building for Debug, no SwiftFormat is running."
fi