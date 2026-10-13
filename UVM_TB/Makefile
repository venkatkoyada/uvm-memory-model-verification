# Portable VCS + Verdi Makefile for UVM_MEMORY_MODEL.
# Uses GNU Make's .RECIPEPREFIX so recipe lines do not require literal TABs.
.RECIPEPREFIX := >
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

VCS ?= vcs
VERDI ?= verdi
URG ?= urg
TOP ?= top
TEST ?= new_test
SEED ?= 1
UVM_VERBOSITY ?= UVM_MEDIUM
# DEFINES=+define+ORIGINAL_RTL builds the design without the bug fixes
DEFINES ?=
RTL_DIR ?= ../rtl
# results (logs + coverage reports) are copied here by 'make save'
DOC_DIR ?= ../doc
SIMV ?= simv
BUILD_DIR ?= build
LOG_DIR ?= logs
WAVE ?= dump.vcd
COV_TYPES ?= line+cond+branch+tgl+assert
# code coverage only for the DUT and the interface (see cov_hier.cfg)
COV_HIER ?= cov_hier.cfg
COV_DIR ?= urgReport
BROWSER ?= firefox
# seeds used by 'make regress' and 'make all'
SEEDS ?= 1 2 3
# QUIET=1 hides the simulation output during regress (only the table is shown)
QUIET ?= 0
# extra simulator options, e.g. PLUSARGS="+UVM_MAX_QUIT_COUNT=3" (see runtime_commandlines.txt)
PLUSARGS ?=
export SEEDS UVM_VERBOSITY QUIET PLUSARGS
FILELIST := $(BUILD_DIR)/sources.f
COMPILE_LOG := $(LOG_DIR)/compile.log
SIM_LOG := $(LOG_DIR)/$(TEST)_$(SEED).log
SV_FILES := $(wildcard *.sv) $(wildcard $(RTL_DIR)/*.sv)

.PHONY: all wave compile sim run regress cov cov_view cov_gui save verdi clean help check-vcs check-verdi

help:
> @printf '%s\n' \
> 'Targets:' \
> '  make all      - everything: clean, compile, run all tests, coverage report, open it' \
> '  make wave     - compile, run one test, then open the waveform in Verdi' \
> '  make compile  - compile the testbench with VCS' \
> '  make sim      - compile and run one UVM test' \
> '  make run      - run the already-compiled simulation' \
> '  make regress  - compile and run all tests with a few seeds' \
> '  make cov      - make the merged HTML + text coverage report (after sim or regress)' \
> '  make cov_view - open the HTML coverage report in a browser' \
> '  make cov_gui  - open the coverage database in Verdi' \
> '  make save     - copy logs and coverage text reports into ../doc' \
> '  make verdi    - open the generated VCD waveform in Verdi' \
> '  make clean    - remove generated build files, logs, and waveforms' \
> '' \
> 'Tests: new_test csr_test chip_disable_test b2b_test illegal_addr_test reset_test' \
> 'Overrides: TEST=csr_test SEED=5 SEEDS="1 2 3 4 5" UVM_VERBOSITY=UVM_HIGH QUIET=1 DEFINES=+define+ORIGINAL_RTL' \
> 'Extra simulator options: PLUSARGS="+UVM_MAX_QUIT_COUNT=3"   (more in runtime_commandlines.txt)'

check-vcs:
> @command -v "$(VCS)" >/dev/null 2>&1 || { echo "ERROR: VCS '$(VCS)' not found in PATH. Load the site VCS environment first."; exit 127; }
> @test -f testbench.sv || { echo "ERROR: testbench.sv not found. Run make from the UVM_TB directory."; exit 2; }
> @test -f $(RTL_DIR)/memory_rtl.sv || { echo "ERROR: $(RTL_DIR)/memory_rtl.sv not found."; exit 2; }
> @test -f $(COV_HIER) || { echo "ERROR: $(COV_HIER) not found."; exit 2; }

check-verdi:
> @command -v "$(VERDI)" >/dev/null 2>&1 || { echo "ERROR: Verdi '$(VERDI)' not found in PATH. Load the site Verdi environment first."; exit 127; }

$(BUILD_DIR):
> mkdir -p "$@"

$(LOG_DIR):
> mkdir -p "$@"

# RTL first, then testbench.sv. testbench.sv includes top.sv; top.sv includes the
# interface, assertions and program. program_mem.sv includes mem_env_pkg.sv, so only
# these two files are listed to avoid duplicate package/module definitions.
$(FILELIST): $(SV_FILES) | $(BUILD_DIR)
> @printf '%s\n' '+incdir+.' '$(RTL_DIR)/memory_rtl.sv' 'testbench.sv' > "$@"

compile: check-vcs $(FILELIST) | $(LOG_DIR)
> @echo "==> Compiling UVM testbench with VCS..."
> "$(VCS)" -full64 -sverilog -ntb_opts uvm-1.2 -timescale=1ns/1ps $(DEFINES) -debug_access+all -kdb -lca -cm $(COV_TYPES) -cm_hier $(COV_HIER) -top "$(TOP)" -f "$(FILELIST)" -o "$(SIMV)" -l "$(COMPILE_LOG)"
> @echo "==> Compilation completed. Log: $(COMPILE_LOG)"

# Run only; this target intentionally does not compile.
# The test passes only if the PASSED banner is printed and there are no UVM_ERROR/UVM_FATAL.
run: | $(LOG_DIR)
> @test -x "./$(SIMV)" || { echo "ERROR: ./$(SIMV) not found. Run 'make compile' first."; exit 2; }
> @echo "==> Running UVM test '$(TEST)' with seed $(SEED)..."
> @set +e; "./$(SIMV)" +UVM_TESTNAME="$(TEST)" +UVM_VERBOSITY="$(UVM_VERBOSITY)" +ntb_random_seed=$(SEED) $(PLUSARGS) -cm $(COV_TYPES) -cm_name "$(TEST)_$(SEED)" -l "$(SIM_LOG)"; sim_status=$$?; set -e; \
> if [ $$sim_status -ne 0 ]; then echo "ERROR: simulation process exited with status $$sim_status. See $(SIM_LOG)."; exit $$sim_status; fi; \
> if grep -Eq 'UVM_FATAL[[:space:]]*:[[:space:]]*[1-9]|UVM_ERROR[[:space:]]*:[[:space:]]*[1-9]' "$(SIM_LOG)"; then \
>   echo "ERROR: UVM_FATAL/UVM_ERROR reports were found in $(SIM_LOG)."; \
>   exit 1; \
> fi; \
> if ! grep -q 'TEST PASSED' "$(SIM_LOG)"; then \
>   echo "ERROR: PASSED banner not found in $(SIM_LOG)."; \
>   exit 1; \
> fi; \
> echo "==> $(TEST) passed. Log: $(SIM_LOG)"

sim: compile run

regress: compile
> @bash ./regress.sh

# Merges every test run saved in simv.vdb.
# HTML pages: dashboard.html (summary), hierarchy.html (code coverage),
# groups.html (covergroups), asserts.html (assertions), tests.html (runs merged).
cov:
> @test -d "$(SIMV).vdb" || { echo "ERROR: $(SIMV).vdb not found. Run 'make sim' or 'make regress' first."; exit 2; }
> rm -rf "$(COV_DIR)"
> "$(URG)" -dir "$(SIMV).vdb" -report "$(COV_DIR)" -format both
> @echo "==> HTML report: $(COV_DIR)/dashboard.html   (open with 'make cov_view')"
> @echo "==> Text report: $(COV_DIR)/dashboard.txt"
> @cat "$(COV_DIR)/dashboard.txt"

cov_view:
> @test -f "$(COV_DIR)/dashboard.html" || { echo "ERROR: $(COV_DIR)/dashboard.html not found. Run 'make cov' first."; exit 2; }
> @if command -v "$(BROWSER)" >/dev/null 2>&1; then "$(BROWSER)" "$(COV_DIR)/dashboard.html" & \
> elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$(COV_DIR)/dashboard.html"; \
> else echo "No browser found, open $(CURDIR)/$(COV_DIR)/dashboard.html yourself."; fi

# Copies the results into ../doc (like the doc folder of a submitted project):
#   doc/logs/            compile log, one log per test run, summary.txt
#   doc/coverage_reports/ URG text reports (dashboard, groups, hierarchy, asserts, ...)
save:
> @test -f "$(LOG_DIR)/regress/summary.txt" || { echo "ERROR: no regression results. Run 'make all' first."; exit 2; }
> @test -f "$(COV_DIR)/dashboard.txt" || { echo "ERROR: no coverage report. Run 'make cov' first."; exit 2; }
> mkdir -p "$(DOC_DIR)/logs" "$(DOC_DIR)/coverage_reports"
> rm -f "$(DOC_DIR)"/logs/*.log "$(DOC_DIR)"/logs/*.txt "$(DOC_DIR)"/coverage_reports/*.txt
> @if [ -f "$(COMPILE_LOG)" ]; then cp "$(COMPILE_LOG)" "$(DOC_DIR)/logs/"; fi
> cp "$(LOG_DIR)"/regress/*.log "$(LOG_DIR)/regress/summary.txt" "$(DOC_DIR)/logs/"
> cp "$(COV_DIR)"/*.txt "$(DOC_DIR)/coverage_reports/"
> @echo "==> Results saved in $(DOC_DIR)/logs and $(DOC_DIR)/coverage_reports"

cov_gui: check-verdi
> @test -d "$(SIMV).vdb" || { echo "ERROR: $(SIMV).vdb not found. Run 'make sim' or 'make regress' first."; exit 2; }
> "$(VERDI)" -cov -covdir "$(SIMV).vdb" &

# One command for the full flow. The coverage report is made even if some tests
# fail, but make still exits with an error in that case.
all:
> @$(MAKE) --no-print-directory clean
> @$(MAKE) --no-print-directory compile
> @set +e; bash ./regress.sh; reg_status=$$?; set -e; \
> $(MAKE) --no-print-directory cov; \
> $(MAKE) --no-print-directory cov_view; \
> if [ $$reg_status -ne 0 ]; then echo "==> Some tests FAILED, see the table above. Results not copied to $(DOC_DIR)."; exit 1; fi; \
> if [ -n "$(strip $(DEFINES))" ]; then echo "==> DEFINES='$(DEFINES)' was used, results not copied to $(DOC_DIR)."; exit 0; fi; \
> $(MAKE) --no-print-directory save; \
> echo "==> All tests passed. Coverage report: $(COV_DIR)/dashboard.html"

# 'make wave' compiles, runs one test, and then attempts to open Verdi even if the test
# reports UVM errors. The final make status still reflects simulation failure.
wave: compile
> @set +e; \
> $(MAKE) --no-print-directory run; sim_status=$$?; \
> if [ -f "$(WAVE)" ]; then \
>   echo "==> Attempting to open Verdi waveform: $(WAVE)"; \
>   if command -v "$(VERDI)" >/dev/null 2>&1; then "$(VERDI)" -sv -ssf "$(WAVE)"; verdi_status=$$?; \
>   else echo "WARNING: Verdi '$(VERDI)' not found in PATH; skipping GUI."; verdi_status=127; fi; \
> else \
>   echo "WARNING: waveform '$(WAVE)' was not generated; cannot open Verdi."; \
>   verdi_status=2; \
> fi; \
> if [ $$sim_status -ne 0 ]; then exit $$sim_status; fi; \
> exit $$verdi_status

verdi: check-verdi
> @test -f "$(WAVE)" || { echo "ERROR: waveform '$(WAVE)' not found. Run the simulation first."; exit 2; }
> @echo "==> Opening Verdi waveform: $(WAVE)"
> "$(VERDI)" -sv -ssf "$(WAVE)"

clean:
> rm -rf "$(BUILD_DIR)" "$(LOG_DIR)" "$(SIMV)" "$(SIMV).daidir" "$(SIMV).vdb" "$(COV_DIR)" csrc ucli.key vc_hdrs.h *.vcd *.fsdb *.vpd novas.conf novas.rc verdiLog
