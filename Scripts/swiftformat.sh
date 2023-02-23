#!/bin/sh

export PATH="$PATH:/opt/homebrew/bin"
if [ "${CONFIGURATION}" == "Debug" ]; then
  echo "Running Swift Format"
  if which swiftformat > /dev/null; then
    swiftformat --config "$PROJECT_DIR/fastlane/forge/.swiftformat" "$PROJECT_DIR/$TARGETNAME"
  else
    echo "warning: SwiftFormat not installed, download from https://github.com/nicklockwood/SwiftFormat"
  fi
else
  echo "info: As we're not building for Debug, no SwiftFormat is running."
fi