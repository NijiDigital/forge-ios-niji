#!/bin/sh

export PATH="$PATH:/opt/homebrew/bin"
if which swiftgen > /dev/null; then
  swiftgen config run --config "$PROJECT_DIR/$TARGETNAME/swiftgen.yml"
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi