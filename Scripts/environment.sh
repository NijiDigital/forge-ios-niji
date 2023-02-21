#!/bin/sh

echo "Switching environment file for '${CONFIGURATION}'..."

case "${CONFIGURATION}" in
  Release)
    JSON_FILE="environment.prod.json"
    ;;
  *)
    JSON_FILE="environment.dev.json"
    ;;
esac

INPUT_FILE="${PROJECT_DIR}/Environment/${JSON_FILE}"
OUTPUT_FILE="${PROJECT_DIR}/Environment/environment.data"

echo "Checking content of ${INPUT_FILE}"
declare jsonCheck=$(cat ${INPUT_FILE} | json_pp)

if [[ ${jsonCheck:0:1} != "{" && ${jsonCheck:0:1} != "[" ]]
then
  echo "The file at ${INPUT_FILE} is not a valid JSON"
  echo "$jsonCheck"
  exit -2
fi

set -e

JSON_DIR="$(dirname "${JSON_FILE}")"
echo "Converting to base64 data"
more "${INPUT_FILE}" | base64 > "${OUTPUT_FILE}"
