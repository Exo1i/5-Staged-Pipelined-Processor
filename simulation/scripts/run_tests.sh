#!/bin/bash

# Change to script directory
cd "$(dirname "$0")"

# Print header
echo "========================================================================"
echo "Control Unit Test Suite"
echo "========================================================================"
echo "Starting test execution..."
echo ""

# Run tests and save output
vsim -c -do run_all_control_tests.do 2>&1 | tee test_output.log

# Print summary
echo ""
echo "========================================================================"
echo "Test execution complete!"
echo "Output saved to: test_output.log"
echo "========================================================================"
echo ""

# Check for errors in output
if grep -q "Error" test_output.log; then
    echo "⚠️  Errors detected in test output"
    exit 1
else
    echo "✓ All tests completed (check test_output.log for results)"
    exit 0
fi
