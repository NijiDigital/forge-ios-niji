#!/bin/sh

if which "$PODS_ROOT/SwiftGen/bin/swiftgen" >/dev/null; then
  echo "Running SwiftGen"
  "$PODS_ROOT/SwiftGen/bin/swiftgen" config run --config "$PROJECT_DIR/$TARGETNAME/swiftgen.yml"
else
  echo "warning: SwiftGen is not installed, download from https://github.com/SwiftGen/SwiftGen"
fi