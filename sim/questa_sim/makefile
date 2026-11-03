# GNU make with a POSIX shell (Linux, or Git Bash/MSYS2 on Windows) and Python 3.
# Run here, or use: make -C sim/questa_sim <target>
SHELL := sh
.SHELLFLAGS := -ec
.DEFAULT_GOAL := usage
.NOTPARALLEL:

ifneq ($(notdir $(CURDIR)),questa_sim)
$(error Run from sim/questa_sim or use make -C sim/questa_sim)
endif

# Installed Windows defaults; on Linux set UVM_HOME and put Questa on PATH.
ifeq ($(OS),Windows_NT)
QUESTA_HOME ?= C:/questasim64_10.7c
QUESTA_BIN ?= $(QUESTA_HOME)/win64
TOOL_SUFFIX := .exe
PYTHON ?= python
else
QUESTA_HOME ?= $(MTI_HOME)
QUESTA_BIN ?=
TOOL_SUFFIX :=
PYTHON ?= python3
endif
VLIB ?= $(if $(QUESTA_BIN),$(QUESTA_BIN)/,)vlib$(TOOL_SUFFIX)
VLOG ?= $(if $(QUESTA_BIN),$(QUESTA_BIN)/,)vlog$(TOOL_SUFFIX)
VOPT ?= $(if $(QUESTA_BIN),$(QUESTA_BIN)/,)vopt$(TOOL_SUFFIX)
VSIM ?= $(if $(QUESTA_BIN),$(QUESTA_BIN)/,)vsim$(TOOL_SUFFIX)
VCOVER ?= $(if $(QUESTA_BIN),$(QUESTA_BIN)/,)vcover$(TOOL_SUFFIX)
UVM_HOME ?= $(if $(QUESTA_HOME),$(QUESTA_HOME)/verilog_src/uvm-1.1d)
UVM_LIB ?= mtiUvm

test ?= aes_encrypt_test
seed ?= 1
uvm_verbosity ?= UVM_MEDIUM
test_folder ?= $(test)_$(seed)
testlist_name ?= apb_regression.list
coverage ?= 1
EXTRA_VLOG_FLAGS ?=
EXTRA_VOPT_FLAGS ?=
EXTRA_SIM_FLAGS ?=

FILELIST := ../apb_compile.f
RUN_MAKE = $(MAKE)
TESTLIST = ../../src/hvl_top/testlists/$(testlist_name)
TEST_DIR = results/$(test_folder)
TEST_LOG = $(TEST_DIR)/simulation.log
COV_DB = $(TEST_DIR)/coverage.ucdb

ifeq ($(coverage),1)
COVER_COMPILE := +cover=bcesft
COVER_RUN := -coverage
COVER_SAVE = coverage save -onexit -testname {$(test)_$(seed)} -assert -directive -cvg -codeAll {$(COV_DB)};
else ifneq ($(coverage),0)
$(error coverage must be 0 or 1)
endif

.PHONY: usage help compile simulate all regression check_run coverage_report \
        merge_cov_report compile_war_err simulate_war_err clean_compile \
        clean_simulate clean clean_all

usage help:
	@echo 'AES-128 / Questa: GNU make + sh + Python 3'
	@echo 'make compile'
	@echo 'make simulate test=aes_encrypt_test seed=1 uvm_verbosity=UVM_MEDIUM'
	@echo 'make all test=aes_decrypt_test coverage=1'
	@echo 'make regression testlist_name=apb_regression.list'
	@echo 'make coverage_report     # selected test'
	@echo 'make merge_cov_report    # latest regression manifest'
	@echo 'make clean_compile | clean_simulate | clean'
	@echo 'On Linux, set UVM_HOME to Questa/verilog_src/uvm-1.1d (matching UVM_LIB).'

# Compilation is explicit: simulate can reuse this build for different tests.
compile:
	@test -f "$(UVM_HOME)/src/uvm_macros.svh" || { echo 'Set UVM_HOME to the UVM sources matching UVM_LIB.'; exit 2; }
	@mkdir -p logs
	@if [ ! -d work ]; then "$(VLIB)" work; fi
	"$(VLOG)" -sv -L "$(UVM_LIB)" "+incdir+$(UVM_HOME)/src" \
		-assertdebug $(COVER_COMPILE) $(EXTRA_VLOG_FLAGS) \
		-f "$(FILELIST)" -l logs/questa_compile.log
	"$(VOPT)" -L "$(UVM_LIB)" work.hdl_top work.hvl_top \
		-o aes_sim +acc $(EXTRA_VOPT_FLAGS) -l logs/questa_elaborate.log
	@printf '%s\n' '$(coverage)' > logs/coverage_setting

# Limit result-folder names to a single directory below this flow's results/.
check_run:
	@case "$(test_folder)" in ''|*[!A-Za-z0-9_-]*) echo 'test_folder may contain only letters, digits, _ and -.'; exit 2;; esac

simulate: check_run
	@test -d work || { echo 'No work library. Run make compile first.'; exit 2; }
	@test -f logs/coverage_setting && [ "$$(cat logs/coverage_setting)" = "$(coverage)" ] || { echo 'Run make compile with the same coverage setting first.'; exit 2; }
	@mkdir -p "$(TEST_DIR)"
	@rm -f "$(TEST_LOG)" "$(COV_DB)"
	"$(VSIM)" -c -L "$(UVM_LIB)" -assertdebug $(COVER_RUN) \
		-sv_seed "$(seed)" -onfinish stop work.aes_sim \
		+UVM_TESTNAME=$(test) +UVM_VERBOSITY=$(uvm_verbosity) $(EXTRA_SIM_FLAGS) \
		-l "$(TEST_LOG)" -wlf "$(TEST_DIR)/waveform.wlf" \
		-do 'onerror {quit -code 1}; onbreak {quit -code 1}; log -r /hdl_top/*; $(COVER_SAVE) run -all; quit -f'
	$(PYTHON) ../check_sim_log.py "$(TEST_LOG)"

all:
	$(MAKE) --no-print-directory compile
	$(MAKE) --no-print-directory simulate

# Compile once; run every non-comment list entry and report aggregate failure.
# Indirect RUN_MAKE keeps make -n from executing the combined shell loop.
regression:
	@test -f "$(TESTLIST)" || { echo 'Regression list not found: $(TESTLIST)'; exit 2; }
	$(MAKE) --no-print-directory compile
	@mkdir -p logs
	@: > logs/regression_cov.list
	@passed=0; failed=0; total=0; \
	while IFS= read -r line || [ -n "$$line" ]; do \
		t=$${line%%\#*}; t=$$(printf '%s' "$$t" | tr -d '[:space:]'); \
		[ -n "$$t" ] || continue; total=$$((total+1)); \
		echo "Running $$t"; \
		if $(RUN_MAKE) --no-print-directory simulate test="$$t" test_folder="$${t}_$(seed)"; then \
			passed=$$((passed+1)); \
			if [ "$(coverage)" = 1 ]; then printf '%s\n' "results/$${t}_$(seed)/coverage.ucdb" >> logs/regression_cov.list; fi; \
		else failed=$$((failed+1)); fi; \
	done < "$(TESTLIST)"; \
	echo "Regression: $$passed passed, $$failed failed, $$total total"; \
	[ "$$total" -gt 0 ] && [ "$$failed" -eq 0 ]
ifeq ($(coverage),1)
	$(MAKE) --no-print-directory merge_cov_report
endif

coverage_report: check_run
	@test "$(coverage)" = 1 || { echo 'Coverage is disabled.'; exit 2; }
	@test -f "$(COV_DB)" || { echo 'No coverage database for the selected run.'; exit 2; }
	"$(VCOVER)" report -html "$(COV_DB)" -htmldir "$(TEST_DIR)/html_cov_report" -details

# Only databases from this regression are merged; old result folders are ignored.
merge_cov_report:
	@test "$(coverage)" = 1 || { echo 'Coverage is disabled.'; exit 2; }
	@test -s logs/regression_cov.list || { echo 'No successful regression coverage manifest.'; exit 2; }
	@set --; while IFS= read -r db; do \
		test -f "$$db" || { echo "Missing coverage: $$db"; exit 2; }; \
		set -- "$$@" "$$db"; \
	done < logs/regression_cov.list; \
	"$(VCOVER)" merge -checkinputs -ucdbchecks -fatal 6854 coverage_merged.ucdb "$$@"
	"$(VCOVER)" report -html coverage_merged.ucdb -htmldir coverage_report -details

compile_war_err:
	@grep -E 'Errors:|Warnings:|\*\* (Error|Warning|Fatal)' logs/questa_compile.log logs/questa_elaborate.log || true

simulate_war_err: check_run
	$(PYTHON) ../check_sim_log.py "$(TEST_LOG)"

# Remove fixed build/result locations only; never glob *_test* source names.
clean_compile:
	rm -rf ./work ./logs
	rm -f ./transcript ./vsim.wlf

clean_simulate:
	rm -rf ./results ./coverage_report
	rm -f ./coverage_merged.ucdb ./logs/regression_cov.list

clean clean_all:
	$(MAKE) --no-print-directory clean_simulate
	$(MAKE) --no-print-directory clean_compile
