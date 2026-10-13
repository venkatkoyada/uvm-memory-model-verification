#!/bin/bash
# Runs every test with a few seeds. The output of each test is shown on the screen
# and saved in logs/regress/<test>_<seed>.log. A pass/fail table is printed at the end.
# Usage: ./regress.sh            (run 'make compile' first, or use 'make regress' / 'make all')
#        SEEDS="1 2 3 4 5" ./regress.sh
#        UVM_VERBOSITY=UVM_HIGH ./regress.sh    (also shows driver/monitor/scoreboard messages)
#        QUIET=1 ./regress.sh                   (only the table, no simulation output)

TESTS="new_test csr_test chip_disable_test b2b_test illegal_addr_test reset_test"
SEEDS=${SEEDS:-"1 2 3"}
UVM_VERBOSITY=${UVM_VERBOSITY:-UVM_MEDIUM}
QUIET=${QUIET:-0}
PLUSARGS=${PLUSARGS:-}
COV_TYPES=${COV_TYPES:-"line+cond+branch+tgl+assert"}
LOG_DIR=logs/regress

if [ ! -x ./simv ]; then
  echo "ERROR: ./simv not found, run 'make compile' first"
  exit 2
fi

mkdir -p $LOG_DIR
pass=0
fail=0
failed_list=""
table=""

for t in $TESTS; do
  for s in $SEEDS; do
    log=$LOG_DIR/${t}_${s}.log
    echo ""
    echo "################################################################"
    echo "####  Running $t  seed=$s"
    echo "################################################################"

    if [ "$QUIET" = "1" ]; then
      ./simv +UVM_TESTNAME=$t +ntb_random_seed=$s +UVM_VERBOSITY=$UVM_VERBOSITY +NO_DUMP $PLUSARGS \
             -cm $COV_TYPES -cm_name ${t}_${s} -l $log > /dev/null 2>&1
    else
      ./simv +UVM_TESTNAME=$t +ntb_random_seed=$s +UVM_VERBOSITY=$UVM_VERBOSITY +NO_DUMP $PLUSARGS \
             -cm $COV_TYPES -cm_name ${t}_${s} -l $log
    fi

    if grep -q "TEST PASSED" $log && ! grep -Eq "UVM_(ERROR|FATAL) *: *[1-9]" $log; then
      result="PASS"
      pass=$((pass+1))
    else
      result="FAIL"
      fail=$((fail+1))
      failed_list="$failed_list $log"
    fi
    errors=$(grep -E '^UVM_ERROR *:' $log | awk '{print $3}')
    table="$table$(printf '%-20s %-6s %-6s %s' $t $s $result "${errors:-?}")\n"
  done
done

# summary goes to the screen and to logs/regress/summary.txt
{
echo ""
echo "================================================================"
echo "  REGRESSION SUMMARY"
echo "================================================================"
printf "%-20s %-6s %-6s %s\n" "TEST" "SEED" "RESULT" "UVM_ERRORS"
printf "%-20s %-6s %-6s %s\n" "----" "----" "------" "----------"
printf "$table"
echo ""
echo "Passed: $pass  Failed: $fail"
if [ $fail -ne 0 ]; then
  echo "Failed logs (first errors of each):"
  for f in $failed_list; do
    echo ""
    echo "  $f  ($(grep -E '^UVM_ERROR *:' $f | awk '{print $3}') errors)"
    grep -m 4 -E '^UVM_(ERROR|FATAL) [^:]' $f | sed -E 's/^(UVM_[A-Z]+) ([^ ]+) @ *([0-9.]+ns): [^[]*/    \3 \2 /'
  done
fi
} | tee $LOG_DIR/summary.txt

[ $fail -ne 0 ] && exit 1
exit 0
