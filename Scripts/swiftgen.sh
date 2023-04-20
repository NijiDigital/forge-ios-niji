#!/bin/sh
if [ "$ENABLE_PREVIEWS" == "YES" ]; then
  echo "We avoid launching SwiftGen for SwiftUI previews to avoid build loops"
  exit 0
fi

export PATH="$PATH:/opt/homebrew/bin"
if which swiftgen > /dev/null; then
  swiftgen config run --config "$PROJECT_DIR/$TARGETNAME/swiftgen.yml"
else
  echo "warning: SwiftGen not installed, download from https://github.com/SwiftGen/SwiftGen"
fi