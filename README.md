# Learning UVM with Verilator  

## About Me  

My background is in RTL design using Verilog and SystemVerilog from AMD. I wrote synthesizable logic, built pipelines and state machines, and thinking in terms of timing,area and hardware behavior. Most of my experience has been strictly at the RTL Level.

Now I’m shifting my focus toward verification. Why?
1. Job
2. Be a better RTL Designer based on verification corner cases
3. I got bored after midterms 

---

## What I'm Doing  

I’m learning **Universal Verification Methodology (UVM)** from the ground up.  

The goal isn’t just to “use UVM,” but to deeply understand how real verification environments are architected:

- How sequences generate stimulus  
- How drivers translate transactions into pin-level activity  
- How monitors reconstruct transactions  
- How scoreboards validate correctness  
- How coverage ensures we’re not missing edge cases  

Long term, I want to build reusable, scalable verification environments similar to what’s used in real SoC/IP development.

---

## Tools  

| Tool | Purpose |
|------|----------|
| **Verilator 5.044** | Open-source SystemVerilog simulator (compiles SV to C++ and executes it) |
| **UVM 2020.3.1** | Accellera’s Universal Verification Methodology class library |
| **GTKWave** | Waveform viewer for VCD traces |
| **GNU Make** | Build system — `make` to run, `make SEED=N` for reproducibility |

---

## Project Structure  

Each chapter is a focused, self-contained exercise.  
All chapters share a common build system through `.support/common.mk` — no per-project boilerplate needed.

```bash
.support/              # Shared Makefile rules + UVM DPI glue (included by every chapter)
chapter0_template/     # Example chapter — copy this to start a new one
    Makefile           # Only needs TOP and optionally INCDIRS/TRACE
    *.sv               # Your design + testbench files
```

Every chapter Makefile looks like this:

```makefile
TOP    := my_design.sv my_tb.sv   # source files (space-separated, top module last)
INCDIRS := +incdir+rtl +incdir+tb # optional include directories
TRACE  := 0                       # set to 1 to generate a VCD waveform
include ../.support/common.mk
```

---

## Build & Run  

### Prerequisites

- Verilator installed  
- UVM installed at `~/uvm-core`  
  *(or override with `UVM_HOME=/your/path make`)*  

### Commands

```bash
make                        # build and run simulation
make SEED=12345             # reproduce a specific randomized run
make TRACE=1                # dump VCD waveform (then: make wave)
make top=other.sv           # override which file(s) to compile
make SEED=12345 TRACE=1     # combine flags freely
make clean                  # delete build artifacts
make wave                   # open waveform in GTKWave (requires TRACE=1 first)
```