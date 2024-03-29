# Streaming divisibility checker RTL generator and UVM testbench

* [Overview](#Overview)
* [State transition diagrams](#State-transition-diagrams)
* [Structure](#Structure)
    * [Design IP](#Design-IP)
    * [Verification IP](#Verification-IP)
* [Tests](#Tests)
* [Register verification](#Register-verification)
* [Running](#Running)
* [Other commands](#Other-commands)

## Overview

* Takes a bitstream as input, and outputs whether the bitstream thus far is divisible by a fixed integer divisor N
* Inspired by a state diagram interview question I once received long ago.  I later decided to:
    * Implement the concept into a functional Verilog module
    * Generalise it by writing a script that generates the Verilog module for any user-specified divisor, programmatically computing all state transitions
    * Construct a SystemVerilog UVM testbench around it
    * Write tests that verify the DUT and collect coverage
    * Wrap it all in a [Makefile](Makefile)

## State transition diagrams

Divisor of 3:<br/>
![Divisor of 3](images/div_by_3_state_transition_diagram.jpg)

Divisor of 5:<br/>
![Divisor of 5](images/div_by_5_state_transition_diagram.jpg)

## Structure

### Design IP

* [`design/`](design/) ("IP"):
    * [`rtl/`](design/rtl/):
        * [`top.v`](design/rtl/top.v): Top RTL module that instantiates below two modules
        * `divisible_by_N.v`: Takes a bitstream as input, and outputs whether the bitstream thus far is divisible by a fixed integer divisor N (generated from scratch by [`gen_divisible_by_N_fsm.py`](design/gen_divisible_by_N_fsm.py) script)
        * [`div_counter.v`](design/rtl/div_counter.v): Counts the number of times that a positive and valid 'divisible' result was encountered; counter is exposed as a register
    * [`gen_divisible_by_N_fsm.py`](design/gen_divisible_by_N_fsm.py): Script that generates `divisible_by_N.v` for an arbitrary user-specified divisor

### Verification IP

* [`verif/`](verif/) ("VIP"):
    * Complete SystemVerilog UVM testbench for streaming divisibility checker
    * Testbench is static, aside from a one-line `div_by_define.svh` file (generated by `make vip`) containing a `define of the fixed integer divisor that the DUT was generated for
    * Testbench source file include list is in [`div_uvm_tb.svh`](verif/div_uvm_tb.svh)

## Tests

Tests reside in [`test_lib.sv`](verif/test_lib.sv):
* `test_base`: Sends stimulus whose values should, over time, cover an even distribution of possible input bitstream values, without regard to divisibility
* `test_mostly_divisible`: Derived from `test_base`; uses a factory override to send stimulus whose values are mostly evenly divisible by N, rather than evenly distributed
* `test_reg_built_in`: Runs all applicable built-in UVM register functionality tests, such as checking reset values, walking 1s and 0s, writing via front door then checking value via back door, and vice versa

## Register verification

[`reg_predictors.sv`](verif/reg_predictors.sv) contains two register predictor components that update register model mirror values based on transactions explicitly observed on physical busses:
* `rst2reg_predict`: Upon each observed reset application, resets mirror of counter register to 0
* `div2reg_predict`: Upon each observed positive and valid 'divisible' result, increments mirror value of counter register

In the post-shutdown phase of `test_base` (and any test derived from it), the register abstraction layer is used to `mirror()`, using both front door and back door, the aforementioned counter of the number of times that a positive and valid 'divisible' result was encountered since the last reset.  This action automatically checks the observed register read value against the register model predicted mirror value.

## Running

Synopsys VCS:
* `git clone git@github.com:willch3n/code_samples.git`
* `cd divisible_by_n_ip_vip`
* `make all DIV_BY=5` or `make all DIV_BY=5 TEST=test_reg_built_in`

Other simulators, such as Aldec Riviera Pro on EDA Playground:
* `git clone git@github.com:willch3n/code_samples.git`
* `cd divisible_by_n_ip_vip`
* `make ip DIV_BY=5`
* `make vip DIV_BY=5`
* Compile and run according to your simulator's instructions, with option `+UVM_TESTNAME=test_base`

## Other commands

Copied from output of `make help`:
```
# Target: all     - [Default] Makes and compiles "IP" and "VIP", runs sim, generates coverage report
# Target: ip      - Generates a divisibility checker FSM for fixed integer divisor N in Verilog
# Target: vip     - Writes a 'DIV_BY' `define to inform testbench of divisor that DUT was generated for
# Target: compile - Compiles design and testbench
# Target: sim     - Runs a simulation using VCS
# Target: cov     - Generates a coverage report in HTML format
# Target: clean   - Removes all generated files for starting over
# Target: help    - Lists each available make target and its purpose
# Target: debug   - Prints all macros and their values, for debugging purposes
```

