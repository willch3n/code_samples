#!/usr/bin/env python3

################################################################################
# Description:
#    * Generates a 'divisible by N' finite state machine in Verilog
#
# Arguments:
#    * divisor (positional)
#      Fixed integer divisor N of generated 'divisible by N' Verilog module
#    * out_file_name (positional)
#      Desired name of generated Verilog source file
#    * --help (optional)
#      Displays help message
#
# Output:
#    * A file, named according to the 'out_file_name' positional argument, that
#      contains a 'divisible by N' Verilog module
#    * Prints to standard output whether the script succeeded
#
# Examples:
#    * gen_divisible_by_N_fsm.py 3 divisible_by_3.v
#      Generates an FSM in a file named "divisible_by_3.v" that outputs '1'
#      whenever its input bitstream thus far is divisible by 3, and '0'
#      otherwise
#    * gen_divisible_by_N_fsm.py 5 divisible_by_5.v
#      Generates an FSM in a file named "divisible_by_5.v" that outputs '1'
#      whenever its input bitstream thus far is divisible by 5, and '0'
#      otherwise
#    * gen_divisible_by_N_fsm.py --help
#      Prints description of this script and its arguments, then exits
#
# Limitations:
#    * Imposes no upper bound on N, allowing user to go wild
################################################################################


# Modules
import argparse
import math
import os
import sys
import time
import warnings

# Main function
def main(argv):
    # Configure argument parser
    desc_str = "Generates a Verilog module that takes a bitstream as input, " \
               "and outputs whether the bitstream thus far is divisible by " \
               "a fixed integer divisor N"
    parser = argparse.ArgumentParser(description=desc_str)
    parser.add_argument(
        "divisor",  # Positional argument
        type=int,
        action="store",
        help="Fixed integer divisor N of generated 'divisible by N' Verilog " \
             "module",
    )
    parser.add_argument(
        "out_file_name",  # Positional argument
        type=str,
        action="store",
        help="Desired name of generated Verilog source file",
    )

    # Print current time
    print(time.strftime("%a %Y-%m-%d %I:%M:%S %p"))
    print("")

    # Store complete command line string for inclusion in header of generated
    # Verilog source file
    orig_cmd_str = sys.argv[0] + " " + " ".join(sys.argv[1:])

    # Parse arguments
    print("Parsing arguments...")
    args = parser.parse_args()
    for (arg, val) in sorted(vars(args).items()):
        print("   * {}: {}".format(arg, val))
    print("")

    # Perform some sanity checks and input sanitation
    validate_args(args)

    # Check whether output file already exists, open file handle, generate and
    # write Verilog source code, and close file handle
    if os.path.exists(args.out_file_name):
        msg = f"Overwriting existing file '{args.out_file_name}'"
        warnings.warn(msg, RuntimeWarning)
    out_fh = open(args.out_file_name, "w")
    gen_verilog_src(orig_cmd_str, args.divisor, out_fh)
    out_fh.close()
    print("")

    # Exit
    print("Done.")
    print("")
    sys.exit(0)  # Success

# Performs some sanity checks and input sanitation
def validate_args(args):
    if args.divisor <= 0:
        msg = f"Given divisor {args.divisor}, but divisor must be a " \
               "non-negative and non-zero number"
        raise Exception(msg)

    if args.divisor == 1:
        msg = f"Given divisor {args.divisor}, but all numbers are divisible " \
               "by 1; a 'divisible by 1' FSM would be pointless"
        raise Exception(msg)

# Generates and writes Verilog source to given output file handle
def gen_verilog_src(orig_cmd_str, divisor, out_fh):
    # File header
    timestamp = time.strftime("%a %Y-%m-%d %I:%M:%S %p")
    out_fh.write(f"///////////////////////////////////////////////////////////////////////////////\n")
    out_fh.write(f"// Generated by the following command on {timestamp}:\n")
    out_fh.write(f"// {orig_cmd_str}\n")
    out_fh.write(f"//\n")
    out_fh.write(f"// Description:\n")
    out_fh.write(f"//    * Takes a bitstream as input\n")
    out_fh.write(f"//    * Outputs whether the bitstream thus far is divisible by {divisor}\n")
    out_fh.write(f"//    * Both input and output are qualified by 'valid' signals\n")
    out_fh.write(f"///////////////////////////////////////////////////////////////////////////////\n")
    out_fh.write(f"\n")
    out_fh.write(f"\n")

    # Module declaration
    out_fh.write(f"// \"Divisible by {divisor}\" finite state machine\n")
    out_fh.write(f"module divisible_by_N(clk, rst_n, in, in_val, out, out_val);\n")

    # State enumerations
    num_state_bits = math.ceil(math.log2(divisor))  # Bits required to encode N states
    for i in range(divisor):
        i_bin_padded = "{:b}".format(i).zfill(num_state_bits)
        out_fh.write(f"    localparam s_mod{i} = {num_state_bits}'b{i_bin_padded};\n")
    out_fh.write(f"\n")

    # Input, output, wire, reg declarations
    out_fh.write(f"    input wire clk, rst_n, in, in_val;\n")
    out_fh.write(f"    output wire out, out_val;\n")
    out_fh.write(f"\n")
    out_fh.write(f"    reg [{num_state_bits - 1}:0] cs, ns;\n")
    out_fh.write(f"    reg val_d1;\n")
    out_fh.write(f"\n")

    # Sequential logic
    out_fh.write(f"    always @(posedge clk) begin\n")
    out_fh.write(f"        if (~rst_n) begin\n")
    out_fh.write(f"            cs     <= 'd0;\n")
    out_fh.write(f"            val_d1 <= 'd0;\n")
    out_fh.write(f"        end\n")
    out_fh.write(f"        else begin\n")
    out_fh.write(f"            if (in_val) cs <= ns;  // Advance state machine only when input bitstream is valid\n")
    out_fh.write(f"            val_d1 <= in_val;      // Indicates that output result is valid\n")
    out_fh.write(f"        end\n")
    out_fh.write(f"    end\n")
    out_fh.write(f"\n")

    # State transition combinational logic
    out_fh.write(f"    always @(*) begin\n")
    out_fh.write(f"        case (cs)\n")
    for i in range(divisor):
        one_transition  = ((i * 2) + 1) % divisor  # Transition to take if next bit in bitstream is a '1'
        zero_transition = ((i * 2)    ) % divisor  # Transition to take if next bit in bitstream is a '0'
        out_fh.write(f"            s_mod{i}:  ns = (in) ? s_mod{one_transition} : s_mod{zero_transition};\n")
    out_fh.write(f"            default: ns = cs;\n")
    out_fh.write(f"        endcase\n")
    out_fh.write(f"    end\n")
    out_fh.write(f"\n")

    # Output wire assignments
    out_fh.write(f"    assign out     = (cs == s_mod0);  // If in state 's_mod0', bitstream so far is divisible by {divisor}\n")
    out_fh.write(f"    assign out_val = val_d1;          // Output delay is always exactly 1 clock\n")

    # End module declaration
    out_fh.write(f"endmodule : divisible_by_N\n")
    out_fh.write(f"\n")

# Execute 'main()' function
if (__name__ == "__main__"):
    main(sys.argv)

