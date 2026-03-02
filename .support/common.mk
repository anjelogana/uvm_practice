# =======================================================================
# common.mk — shared UVM + Verilator build rules
# Usage in any test directory:
#
#   TOP    := file1.sv file2.sv ...   # all SV sources (last = top module)
#   INCDIRS := +incdir+rtl +incdir+tb  # optional extra include dirs
#   TRACE  := 1                        # optional: generate VCD waveform
#   include ../.support/common.mk
#
# Override TOP from the command line (lowercase alias also accepted):
#   make top=packet.sv
#   make top="packet.sv hello.sv"
#   make TOP=packet.sv
# =======================================================================

# Allow lowercase: make top=file.sv (overrides the local Makefile's TOP)
ifdef top
  TOP := $(top)
endif

ifndef TOP
$(error TOP is not set — define it before including common.mk)
endif

UVM_HOME    ?= /Users/anjelo/uvm-core
VERILATOR   := verilator
BUILD_DIR   := build
TRACE       ?= 0

# Absolute path to this file's directory (.support/), regardless of where
# make is invoked from.  $(dir …) always ends with a trailing slash.
SUPPORT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

UVM_INCDIRS := $(shell find $(UVM_HOME)/src -type d | sed 's/^/+incdir+/')

_TRACE_FLAG :=
ifeq ($(TRACE),1)
  _TRACE_FLAG := --trace
endif

# Number of parallel C++ compile jobs (all cores).
JOBS := $(shell sysctl -n hw.logicalcpu 2>/dev/null || nproc)

# --cc  : generate C++ + Vtop.mk only (no internal build step → no PCH race)
# --exe : tell Verilator to emit a main() wrapper so we get a binary
# Compilation is done by a separate $(MAKE) call below, fully parallel.
SIM_FLAGS := --cc --main --exe --timing \
             -j 0 \
             -Wno-fatal \
             --converge-limit 1000000 \
             $(_TRACE_FLAG) \
             +define+UVM_NO_WAIT_FOR_NBA \
             +define+UVM_POUND_ZERO_COUNT=1 \
             $(UVM_INCDIRS) \
             $(INCDIRS) \
             -CFLAGS "-O0 -I$(SUPPORT_DIR)include -I$(UVM_HOME)/src/dpi -I$(BUILD_DIR) -include svdpi.h -include limits.h" \
             $(UVM_HOME)/src/uvm_pkg.sv \
             $(TOP) \
             $(SUPPORT_DIR)uvm_dpi_verilator.cpp \
             --top-module top \
             --Mdir $(BUILD_DIR)

.PHONY: all sim clean wave
.DEFAULT_GOAL := sim

$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/uvm_dpi_srcs.h: | $(BUILD_DIR)
	@printf '#pragma once\n#include "%s"\n#include "%s"\n#include "%s"\n' \
		"$(UVM_HOME)/src/dpi/uvm_svcmd_dpi.c" \
		"$(UVM_HOME)/src/dpi/uvm_common.c" \
		"$(UVM_HOME)/src/dpi/uvm_regex.cc" > $@

# Random seed — override with: make SEED=12345
# Clamped to [1, 2147483647] (Verilator signed-32-bit limit)
SEED ?= $(shell od -A n -t u4 -N 4 /dev/urandom | tr -d ' \n')

sim: $(BUILD_DIR)/uvm_dpi_srcs.h
	@seed=$$(( $(SEED) % 2147483647 )); [ $$seed -le 0 ] && seed=1; \
	 t0=$$(date +%s); \
	 echo "[1/3] Verilating..."; \
	 $(VERILATOR) $(SIM_FLAGS) 2>&1 | tee $(BUILD_DIR)/build.log; \
	 t1=$$(date +%s); \
	 echo "[2/3] Compiling C++..."; \
	 $(MAKE) -C $(BUILD_DIR) -f Vtop.mk -j$(JOBS) 2>&1 | tee -a $(BUILD_DIR)/build.log; \
	 t2=$$(date +%s); \
	 echo "[3/3] Running simulation (seed=$$seed)..."; \
	 echo "Seed: $$seed" > sim.log; \
	 ./$(BUILD_DIR)/Vtop +verilator+seed+$$seed 2>&1 | tee -a sim.log; \
	 t3=$$(date +%s); \
	 e1=$$((t1-t0)); e2=$$((t2-t1)); e3=$$((t3-t2)); tot=$$((t3-t0)); \
	 printf "\n┌────────────────────────────────────┐\n"; \
	 printf   "│           Build Summary            │\n"; \
	 printf   "├────────────────────────────────────┤\n"; \
	 printf   "│  %-14s  %2dm %02ds           │\n" "Verilating:"    $$((e1/60)) $$((e1%60)); \
	 printf   "│  %-14s  %2dm %02ds           │\n" "Compiling C++:" $$((e2/60)) $$((e2%60)); \
	 printf   "│  %-14s  %2dm %02ds           │\n" "Simulation:"    $$((e3/60)) $$((e3%60)); \
	 printf   "├────────────────────────────────────┤\n"; \
	 printf   "│  %-14s  %2dm %02ds           │\n" "Total:"         $$((tot/60)) $$((tot%60)); \
	 printf   "│  Seed: %-28s│\n" "$$seed"; \
	 printf   "└────────────────────────────────────┘\n"
ifeq ($(TRACE),1)
	@echo ""
	@echo "  Waveform written to build/sim.vcd"
	@echo "  Open with: make wave   (or: gtkwave build/sim.vcd)"
endif

wave:
	gtkwave build/sim.vcd &

clean:
	rm -rf $(BUILD_DIR)
	@if [ -f sim.log ]; then \
		printf "Delete sim.log? [y/N] "; \
		read ans; \
		case "$$ans" in [yY]) rm -f sim.log; echo "Deleted sim.log.";; \
		*) echo "Kept sim.log.";; esac; \
	fi
