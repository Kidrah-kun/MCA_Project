#!/usr/bin/env bash
set -e

echo "======================================================"
echo "⚡ MEMORY HIERARCHY TEST SUITE RUNNER"
echo "======================================================"

mkdir -p sim/waveforms

echo ""
echo ">> [1/2] Running Baseline Integration Testbench (memory_hierarchy_tb.v)..."
iverilog -o sim/memory_hierarchy testbench/memory_hierarchy_tb.v src/*.v
vvp sim/memory_hierarchy

echo ""
echo ">> [2/2] Running Comprehensive E2E Verification Testbench (memory_hierarchy_e2e_tb.v)..."
iverilog -o sim/memory_hierarchy_e2e testbench/memory_hierarchy_e2e_tb.v src/*.v
vvp sim/memory_hierarchy_e2e

echo ""
echo "======================================================"
echo "✅ ALL END-TO-END SUITES COMPLETED SUCCESSFULLY!"
echo "Waveforms generated:"
echo "  - sim/waveforms/dump.vcd"
echo "  - sim/waveforms/e2e_dump.vcd"
echo "======================================================"
