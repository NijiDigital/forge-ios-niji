#!/bin/sh

if [ "${RUN_CLANG_STATIC_ANALYZER}" == "YES" ]; then
  echo "Printing TODOs as warnings..."
  KEYWORDS="TODO:|FIXME:|\?\?\?:|\!\!\!:"
  FILE_EXTENSIONS="swift|h|m|mm|c|cpp"
  find -E "${SRCROOT}" -ipath "${SRCROOT}/Carthage" -o -ipath "${SRCROOT}/Pods" -prune -o \( -regex ".*\.($FILE_EXTENSIONS)$" \) -print0 | xargs -0 egrep --with-filename --line-number --only-matching "($KEYWORDS).*\$" | perl -p -e "s/($KEYWORDS)/ warning: \$1/"
fi