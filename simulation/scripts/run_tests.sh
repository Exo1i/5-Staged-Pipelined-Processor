#!/bin/bash
# Script to run all control unit testbenches
cd "$(dirname "$0")"
vsim -c -do run_all_control_tests.do 2>&1 | tee test_output.log
echo ""
echo "Test output saved to test_output.log"
