# Run from this directory, or use: make -C sim/synopsys_sim <target>
SHELL := sh
.SHELLFLAGS := -ec
.DEFAULT_GOAL := usage
.NOTPARALLEL:
ifneq ($(notdir $(CURDIR)),synopsys_sim)
$(error Run this makefile with make -C sim/synopsys_sim)
endif

.PHONY: usage help compile simulate all regression check_run coverage_report merge_cov_report \
        compile_war_err simulate_war_err clean_compile clean_simulate clean clean_all

# Tool paths may be overridden when VCS is installed outside PATH.
VCS ?= vcs
URG ?= urg
PYTHON ?= python3
UVM_VERSION ?= uvm-1.2
EXTRA_VCS_FLAGS ?=
EXTRA_SIM_FLAGS ?=

test ?= aes_encrypt_test
seed ?= 1
uvm_verbosity ?= UVM_MEDIUM
test_folder ?= $(test)_$(seed)
testlist_name ?= apb_regression.list
coverage ?= 1
CM_METRICS ?= line+cond+tgl+fsm+branch+assert

FILELIST := ../apb_compile.f
RUN_MAKE = $(MAKE)
SIMV := $(abspath .build/simv)
COMPILE_COV := $(abspath .build/compile.vdb)
TEST_DIR = $(abspath results/$(test_folder))
TEST_LOG = $(TEST_DIR)/sim.log
TEST_COV = $(TEST_DIR)/coverage.vdb
REGRESSION_COV := $(abspath .build/regression_cov.list)

ifeq ($(coverage),1)
CM_COMPILE_FLAGS = -cm $(CM_METRICS) -cm_dir "$(COMPILE_COV)"
CM_RUN_FLAGS = -cm $(CM_METRICS) -cm_dir "$(TEST_COV)" -cm_name $(test)_$(seed)
else ifeq ($(coverage),0)
CM_COMPILE_FLAGS :=
CM_RUN_FLAGS :=
else
$(error coverage must be 0 or 1)
endif

usage help:
	@echo "AES-128 accelerator - Synopsys VCS (Linux / GNU make)"
	@echo "make compile"
	@echo "make simulate test=aes_encrypt_test seed=1 uvm_verbosity=UVM_MEDIUM"
	@echo "make all test=aes_decrypt_test coverage=1"
	@echo "make regression testlist_name=apb_regression.list"
	@echo "make coverage_report test=aes_encrypt_test seed=1"
	@echo "make merge_cov_report"
	@echo "make clean_compile | clean_simulate | clean"
	@echo "VCS, URG, PYTHON, UVM_VERSION and EXTRA_*_FLAGS may be overridden."

# Keep the file-list working directory here: its paths start with ../../src.
# Use the vendor UVM package selected by -ntb_opts; do not compile another copy.
compile:
	@mkdir -p .build logs
	@rm -rf .build/compile.vdb
	"$(VCS)" -full64 -sverilog -ntb_opts $(UVM_VERSION) \
		-debug_access+all -timescale=1ns/1ps \
		-f $(FILELIST) -top hdl_top -top hvl_top \
		-Mdir="$(abspath .build/csrc)" -o "$(SIMV)" \
		$(CM_COMPILE_FLAGS) $(EXTRA_VCS_FLAGS) \
		-l "$(abspath logs/vcs_compile.log)"
	@$(MAKE) --no-print-directory compile_war_err

# Each test has its own log and coverage database. The compiled database supplies
# design metadata; VCS records this test under the explicit test/seed run name.
check_run:
	@case "$(test_folder)" in ''|*[!A-Za-z0-9_-]*) echo 'test_folder may contain only letters, digits, _ and -.'; exit 2;; esac

simulate: check_run
	@test -x "$(SIMV)" || { echo "ERROR: Run make compile first."; exit 2; }
	@mkdir -p "$(TEST_DIR)"
	@rm -f "$(TEST_LOG)"
ifeq ($(coverage),1)
	@test -d "$(COMPILE_COV)" || { echo "ERROR: Recompile with coverage=1."; exit 2; }
	@cd "$(TEST_DIR)" && rm -rf ./coverage.vdb
	@mkdir -p "$(TEST_COV)"
	@cp -R "$(COMPILE_COV)/." "$(TEST_COV)/"
endif
	@echo "Running $(test), seed=$(seed), verbosity=$(uvm_verbosity)"
	@run_status=0; \
		"$(SIMV)" +UVM_TESTNAME=$(test) +UVM_VERBOSITY=$(uvm_verbosity) \
		+ntb_random_seed=$(seed) $(CM_RUN_FLAGS) $(EXTRA_SIM_FLAGS) \
		-l "$(TEST_LOG)" || run_status=$$?; \
		$(PYTHON) ../check_sim_log.py "$(TEST_LOG)" || run_status=1; \
		exit $$run_status

# Recursive make keeps command-line overrides and ensures compile precedes run.
all:
	@$(MAKE) --no-print-directory compile
	@$(MAKE) --no-print-directory simulate

# Compile once, then run every listed test even if an earlier test fails.
# Each selected run gets fresh coverage; the manifest excludes old result folders.
# Indirect RUN_MAKE keeps make -n from executing the combined shell loop.
regression:
	@set -eu; \
		list="$(testlist_name)"; \
		if [ ! -f "$$list" ]; then list="../../src/hvl_top/testlists/$(testlist_name)"; fi; \
		if [ ! -f "$$list" ]; then echo "ERROR: Test list not found: $(testlist_name)"; exit 2; fi; \
		$(RUN_MAKE) --no-print-directory compile; \
		: > "$(REGRESSION_COV)"; \
		passed=0; failed=0; \
		while IFS= read -r line || [ -n "$$line" ]; do \
			test_name=$$(printf '%s' "$$line" | sed 's/#.*//' | tr -d '[:space:]'); \
			[ -n "$$test_name" ] || continue; \
			if $(RUN_MAKE) --no-print-directory simulate test="$$test_name" test_folder="$${test_name}_$(seed)"; then \
				passed=$$((passed + 1)); \
				database="$(abspath results)/$${test_name}_$(seed)/coverage.vdb"; \
				if [ "$(coverage)" = 1 ] && [ -d "$$database" ]; then \
					printf '%s\n' "$$database" >> "$(REGRESSION_COV)"; \
				fi; \
			else \
				failed=$$((failed + 1)); \
				echo "FAILED: $$test_name"; \
			fi; \
		done < "$$list"; \
		echo "Regression summary: $$passed passed, $$failed failed"; \
		if [ $$((passed + failed)) -eq 0 ]; then echo "ERROR: Test list is empty."; exit 2; fi; \
		coverage_failed=0; \
		if [ "$(coverage)" = 1 ] && [ "$$failed" -eq 0 ]; then \
			$(RUN_MAKE) --no-print-directory merge_cov_report || coverage_failed=1; \
		fi; \
		[ "$$failed" -eq 0 ] && [ "$$coverage_failed" -eq 0 ]

# Report just the selected test, independently of the last regression.
coverage_report: check_run
	@test "$(coverage)" = 1 || { echo "ERROR: Coverage is disabled."; exit 2; }
	@test -d "$(TEST_COV)" || { echo "ERROR: No coverage database for $(test_folder)."; exit 2; }
	"$(URG)" -dir "$(TEST_COV)" -format both \
		-report "$(TEST_DIR)/html_cov_report" > "$(TEST_DIR)/urg.log" 2>&1
	@echo "Coverage: $(TEST_DIR)/html_cov_report/dashboard.html"

# Merge only databases recorded by the latest regression, never results/* globs.
merge_cov_report:
	@test "$(coverage)" = 1 || { echo "ERROR: Coverage is disabled."; exit 2; }
	@test -s "$(REGRESSION_COV)" || { echo "ERROR: No regression coverage manifest."; exit 2; }
	@mkdir -p logs
	@set -eu; set --; \
		while IFS= read -r database || [ -n "$$database" ]; do \
			[ -n "$$database" ] || continue; \
			test -d "$$database" || { echo "ERROR: Missing coverage database: $$database"; exit 2; }; \
			set -- "$$@" "$$database"; \
		done < "$(REGRESSION_COV)"; \
		[ "$$#" -gt 0 ] || { echo "ERROR: Coverage manifest is empty."; exit 2; }; \
		"$(URG)" -dir "$$@" -format both -report coverage_report > logs/urg.log 2>&1
	@echo "Merged coverage: coverage_report/dashboard.html"

compile_war_err:
	@test -f logs/vcs_compile.log || { echo "ERROR: No compilation log."; exit 2; }
	@echo "Compilation log: logs/vcs_compile.log"
	@grep -E '(Error-|Warning-|\*\* Error|\*\* Warning)' logs/vcs_compile.log | head -n 30 || true

simulate_war_err: check_run
	@echo "Simulation log: $(TEST_LOG)"
	@$(PYTHON) ../check_sim_log.py "$(TEST_LOG)"

# Delete only fixed generated directories in this guarded vendor working folder.
clean_compile:
	rm -rf .build
	rm -f logs/vcs_compile.log

clean_simulate:
	rm -rf results coverage_report
	rm -f logs/urg.log .build/regression_cov.list

clean clean_all:
	@$(MAKE) --no-print-directory clean_compile
	@$(MAKE) --no-print-directory clean_simulate
