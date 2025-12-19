#!/bin/bash

# Enhanced Performance Monitor Test Runner
# Usage: ./test.sh [--compact|--verbose]

set -e

cd "$(dirname "$0")/PerformanceMonitor"

# Colors (disabled if not a terminal)
if [ -t 1 ]; then
    GREEN=$'\033[0;32m'
    RED=$'\033[0;31m'
    YELLOW=$'\033[1;33m'
    BLUE=$'\033[0;34m'
    BOLD=$'\033[1m'
    NC=$'\033[0m' # No Color
else
    GREEN=''
    RED=''
    YELLOW=''
    BLUE=''
    BOLD=''
    NC=''
fi

# Phase definitions
PHASE1_SUITES="UptimeParserTests VMStatParserTests DiskParserTests"
PHASE2_SUITES="DriftScoreTests HealthStatusTests"
PHASE3_SUITES="CPUParserTests SpotlightParserTests AppActivityParserTests"
PHASE4_SUITES="SystemMonitorTests MockShellExecutorTests"

# Parse arguments
MODE="full"
if [ "$1" == "--compact" ]; then
    MODE="compact"
elif [ "$1" == "--verbose" ]; then
    MODE="verbose"
fi

# Run tests and capture output
echo ""
echo "${BOLD}Running PerformanceMonitor tests...${NC}"
echo ""

OUTPUT=$(xcodebuild -project PerformanceMonitor.xcodeproj \
                    -scheme PerformanceMonitor \
                    -configuration Debug \
                    test 2>&1)

# Check if tests succeeded
if echo "$OUTPUT" | grep -q "TEST SUCCEEDED"; then
    TEST_RESULT="SUCCEEDED"
else
    TEST_RESULT="FAILED"
fi

# Compact mode - simple output
if [ "$MODE" == "compact" ]; then
    PASSED=$(echo "$OUTPUT" | grep -c "passed" || true)
    FAILED=$(echo "$OUTPUT" | grep -c "failed" || true)
    
    if [ "$TEST_RESULT" == "SUCCEEDED" ]; then
        echo "${GREEN}✅ TEST SUCCEEDED${NC}"
        echo ""
        echo "   Tests passed: $PASSED"
        echo "   Tests failed: $FAILED"
    else
        echo "${RED}❌ TEST FAILED${NC}"
        echo ""
        echo "$OUTPUT" | grep -E "(failed|error:)" | head -20
        exit 1
    fi
    echo ""
    exit 0
fi

# Function to get suite stats
get_suite_stats() {
    local suite=$1
    local passed=$(echo "$OUTPUT" | grep "Test case '$suite\." | grep -c "passed" || true)
    local failed=$(echo "$OUTPUT" | grep "Test case '$suite\." | grep -c "failed" || true)
    
    # Extract timing - sum all test times for this suite
    local times=$(echo "$OUTPUT" | grep "Test case '$suite\." | grep -oE '\([0-9]+\.[0-9]+ seconds\)' | grep -oE '[0-9]+\.[0-9]+')
    local total_time=0
    if [ -n "$times" ]; then
        total_time=$(echo "$times" | awk '{sum += $1} END {printf "%.2f", sum}')
    fi
    
    echo "$passed $failed $total_time"
}

# Function to print suite line
print_suite_line() {
    local suite=$1
    local stats=$(get_suite_stats "$suite")
    local passed=$(echo $stats | cut -d' ' -f1)
    local failed=$(echo $stats | cut -d' ' -f2)
    local time=$(echo $stats | cut -d' ' -f3)
    
    # Format the line with dots
    local suite_display=$(printf "%-28s" "$suite")
    local dots=""
    local dot_count=$((35 - ${#suite}))
    for ((i=0; i<dot_count; i++)); do dots+="."; done
    
    if [ "$failed" -gt 0 ]; then
        printf "  %s %s ${RED}%2d passed, %d failed${NC} (%.2fs)\n" "$suite" "$dots" "$passed" "$failed" "$time"
    else
        printf "  %s %s ${GREEN}%2d passed${NC}   (%.2fs)\n" "$suite" "$dots" "$passed" "$time"
    fi
}

# Function to calculate phase totals
get_phase_stats() {
    local suites="$1"
    local total_passed=0
    local total_failed=0
    local total_time=0
    
    for suite in $suites; do
        local stats=$(get_suite_stats "$suite")
        local passed=$(echo $stats | cut -d' ' -f1)
        local failed=$(echo $stats | cut -d' ' -f2)
        local time=$(echo $stats | cut -d' ' -f3)
        
        total_passed=$((total_passed + passed))
        total_failed=$((total_failed + failed))
        total_time=$(echo "$total_time + $time" | bc)
    done
    
    echo "$total_passed $total_failed $total_time"
}

# Print header
echo "============================================================"
echo "               PerformanceMonitor Test Suite                "
echo "============================================================"
echo ""

# Phase 1: Parser Unit Tests
phase1_stats=$(get_phase_stats "$PHASE1_SUITES")
phase1_time=$(echo $phase1_stats | cut -d' ' -f3)
echo "${BOLD}PHASE 1: Parser Unit Tests${NC}                          [${phase1_time}s]"
echo "------------------------------------------------------------"
for suite in $PHASE1_SUITES; do
    print_suite_line "$suite"
done
echo ""

# Phase 2: Business Logic Tests
phase2_stats=$(get_phase_stats "$PHASE2_SUITES")
phase2_time=$(echo $phase2_stats | cut -d' ' -f3)
echo "${BOLD}PHASE 2: Business Logic Tests${NC}                       [${phase2_time}s]"
echo "------------------------------------------------------------"
for suite in $PHASE2_SUITES; do
    print_suite_line "$suite"
done
echo ""

# Phase 3: Complex Parser Tests
phase3_stats=$(get_phase_stats "$PHASE3_SUITES")
phase3_time=$(echo $phase3_stats | cut -d' ' -f3)
echo "${BOLD}PHASE 3: Complex Parser Tests${NC}                       [${phase3_time}s]"
echo "------------------------------------------------------------"
for suite in $PHASE3_SUITES; do
    print_suite_line "$suite"
done
echo ""

# Phase 4: Integration Tests
phase4_stats=$(get_phase_stats "$PHASE4_SUITES")
phase4_time=$(echo $phase4_stats | cut -d' ' -f3)
echo "${BOLD}PHASE 4: Integration Tests${NC}                          [${phase4_time}s]"
echo "------------------------------------------------------------"
for suite in $PHASE4_SUITES; do
    print_suite_line "$suite"
done
echo ""

# Calculate totals
unit_suites="$PHASE1_SUITES $PHASE2_SUITES $PHASE3_SUITES"
unit_stats=$(get_phase_stats "$unit_suites")
unit_passed=$(echo $unit_stats | cut -d' ' -f1)
unit_failed=$(echo $unit_stats | cut -d' ' -f2)
unit_time=$(echo $unit_stats | cut -d' ' -f3)

integration_stats=$(get_phase_stats "$PHASE4_SUITES")
int_passed=$(echo $integration_stats | cut -d' ' -f1)
int_failed=$(echo $integration_stats | cut -d' ' -f2)
int_time=$(echo $integration_stats | cut -d' ' -f3)

total_passed=$((unit_passed + int_passed))
total_failed=$((unit_failed + int_failed))
total_time=$(echo "$unit_time + $int_time" | bc)

# Print summary
echo "============================================================"
echo "${BOLD}SUMMARY${NC}"
echo "============================================================"
printf "  Unit Tests:        %3d passed   (%.2fs)\n" "$unit_passed" "$unit_time"
printf "  Integration Tests: %3d passed   (%.2fs)\n" "$int_passed" "$int_time"
echo "  ----------------------------------------"
printf "  ${BOLD}TOTAL:${NC}           %3d passed   (%.2fs)\n" "$total_passed" "$total_time"
echo ""

if [ "$TEST_RESULT" == "SUCCEEDED" ]; then
    echo "  ${GREEN}✅ TEST SUCCEEDED${NC}"
else
    echo "  ${RED}❌ TEST FAILED${NC}"
    echo ""
    echo "Failed tests:"
    echo "$OUTPUT" | grep "failed" | head -10
fi
echo "============================================================"
echo ""

# Verbose mode - also show individual test names
if [ "$MODE" == "verbose" ]; then
    echo ""
    echo "${BOLD}DETAILED TEST RESULTS:${NC}"
    echo ""
    echo "$OUTPUT" | grep -E "Test case.*passed|Test case.*failed" | sed 's/Test case /  /' | sed "s/passed/${GREEN}passed${NC}/" | sed "s/failed/${RED}failed${NC}/"
fi

# Exit with error if tests failed
if [ "$TEST_RESULT" != "SUCCEEDED" ]; then
    exit 1
fi
