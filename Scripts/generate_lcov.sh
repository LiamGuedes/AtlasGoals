#!/bin/bash

# Exit immediately if any command fails
set -e

DERIVED_DATA_PATH="./Application/DerivedData"
XCRESULT_PATH="$DERIVED_DATA_PATH/Logs/Test/*.xcresult"
LCOV_OUTPUT="coverageinfo"
TEMP_DIR=$(mktemp -d)

if ! command -v xcrun &> /dev/null || ! command -v jq &> /dev/null; then
  echo "xcrun or jq not found. Please install Xcode Command Line Tools and jq."
  exit 1
fi

if [ ! -e $XCRESULT_PATH ]; then
  echo "No xcresult file found at $XCRESULT_PATH. Ensure tests are run with code coverage enabled."
  exit 1
fi

echo "Extracting coverage data from $XCRESULT_PATH..."

COVERAGE_JSON="$TEMP_DIR/coverage.json"
xcrun xccov view --report --json $XCRESULT_PATH > $COVERAGE_JSON

echo "Converting JSON coverage to LCOV format..."

echo "TN:" > $LCOV_OUTPUT

jq -r '.targets[] 
        | select(.name != "System" and .name != "TestBundle") 
        | .files[] 
        | select(.lineNumber != null and .executionCount != null) 
        | "\(.path)\nDA:\(.lineNumber),\(.executionCount)"' $COVERAGE_JSON | while read -r line; do
  if [[ $line == /* ]]; then
    echo "SF:$line" >> $LCOV_OUTPUT
  elif [[ $line == DA:* ]]; then
    echo "$line" >> $LCOV_OUTPUT
  else
    echo "end_of_record" >> $LCOV_OUTPUT
  fi
done

echo "end_of_record" >> $LCOV_OUTPUT

rm -rf $TEMP_DIR

echo "LCOV report generated at $LCOV_OUTPUT"
