#!/bin/bash

# Exit immediately if any command fails
set -e

DERIVED_DATA_PATH="../Application/DerivedData"
XCRESULT_PATH="$DERIVED_DATA_PATH/Logs/Test/*.xcresult"
LCOV_OUTPUT="coverage.info"
TEMP_DIR=$(mktemp -d)

if ! command -v xcrun &> /dev/null; then
  echo "xcrun could not be found. Please ensure Xcode Command Line Tools are installed."
  exit 1
fi

if ! command -v lcov &> /dev/null; then
  echo "lcov could not be found. Please install it using Homebrew: brew install lcov"
  exit 1
fi

if [ ! -e $XCRESULT_PATH ]; then
  echo "No xcresult file found at $XCRESULT_PATH. Ensure tests are run with code coverage enabled."
  exit 1
fi

echo "Extracting code coverage data from $XCRESULT_PATH..."

COVERAGE_JSON="$TEMP_DIR/coverage.json"
xcrun xccov view --report --json $XCRESULT_PATH > $COVERAGE_JSON

echo "Converting JSON coverage to LCOV format..."

echo "Creating $LCOV_OUTPUT..."

echo "TN:" > $LCOV_OUTPUT

jq -r '.targets[] | select(.name != "System" and .name != "TestBundle") | .files[] | "\(.path)\nDA:\(.lineNumber),\(.executionCount)"' $COVERAGE_JSON | while read -r line; do
  if [[ $line == /* ]]; then
    echo "SF:$line" >> $LCOV_OUTPUT
  elif [[ $line == DA:* ]]; then
    echo "$line" >> $LCOV_OUTPUT
  else
    echo "end_of_record" >> $LCOV_OUTPUT
  fi
done

rm -rf $TEMP_DIR

echo "LCOV report generated at $LCOV_OUTPUT"
