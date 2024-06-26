///////////////////////////////////////////////////////////////////////////////
// Author: Will Chen
//
// Description:
//    * Manual testbench of image edge detector RTL design
//    * To be replaced with a SystemVerilog UVM testbench
///////////////////////////////////////////////////////////////////////////////


`timescale 1ns/1ns

module tb();
    // Clocks
    reg clk;
    initial begin
        clk <= 1'b0;  // Initial state
        forever #5ns clk = ~clk;  // 100 MHz
    end

    // Resets
    reg rst;
    initial begin
        rst <= 1'b0;  // Initial state
        @(posedge clk);
        rst <= 1'b1;  // Assert reset
        @(posedge clk);
        rst <= 1'b0;  // De-assert reset
    end

    // DUT
    reg run;
    reg done;
    top dut_top (
        .clk                       (clk),
        .rst_n                     (~rst),
        .run                       (run),
        .done                      (done),
        .frame_buf_in_wr_en        (),
        .frame_buf_in_wr_x         (),
        .frame_buf_in_wr_y         (),
        .frame_buf_in_wr_data_pxl  (),
        .frame_buf_out_rd_en       (),
        .frame_buf_out_rd_x        (),
        .frame_buf_out_rd_y        (),
        .frame_buf_out_rd_data_pxl ()
    );

    // Run simulation
    initial begin
        int timeout_ns;

        $display("%0t: Testbench start", $time);

        // Waveform dumping configuration
        $dumpfile("waves.vcd");
        $dumpvars();  // All
        $dumpon;

        // Force 5x5 input image into memory
        dut_top.frame_buf_in.img_buf[00][00] = 'd250;
        dut_top.frame_buf_in.img_buf[00][01] = 'd000;
        dut_top.frame_buf_in.img_buf[00][02] = 'd000;
        dut_top.frame_buf_in.img_buf[00][03] = 'd000;
        dut_top.frame_buf_in.img_buf[00][04] = 'd000;
        dut_top.frame_buf_in.img_buf[01][00] = 'd000;
        dut_top.frame_buf_in.img_buf[01][01] = 'd251;
        dut_top.frame_buf_in.img_buf[01][02] = 'd000;
        dut_top.frame_buf_in.img_buf[01][03] = 'd000;
        dut_top.frame_buf_in.img_buf[01][04] = 'd000;
        dut_top.frame_buf_in.img_buf[02][00] = 'd000;
        dut_top.frame_buf_in.img_buf[02][01] = 'd000;
        dut_top.frame_buf_in.img_buf[02][02] = 'd252;
        dut_top.frame_buf_in.img_buf[02][03] = 'd000;
        dut_top.frame_buf_in.img_buf[02][04] = 'd000;
        dut_top.frame_buf_in.img_buf[03][00] = 'd000;
        dut_top.frame_buf_in.img_buf[03][01] = 'd000;
        dut_top.frame_buf_in.img_buf[03][02] = 'd000;
        dut_top.frame_buf_in.img_buf[03][03] = 'd253;
        dut_top.frame_buf_in.img_buf[03][04] = 'd000;
        dut_top.frame_buf_in.img_buf[04][00] = 'd000;
        dut_top.frame_buf_in.img_buf[04][01] = 'd000;
        dut_top.frame_buf_in.img_buf[04][02] = 'd000;
        dut_top.frame_buf_in.img_buf[04][03] = 'd000;
        dut_top.frame_buf_in.img_buf[04][04] = 'd254;
        print_in_buf();

        // Begin processing
        run = 1'b1;

        // Wait for DUT to report processing complete
        fork
            begin
                wait (done);
                $display("%0t: DUT reports done after %0d ns", $time, $time);
            end
            begin
                timeout_ns = 1500;  // Maximum time, in ns, to wait for DUT to report done
                #(1ns * timeout_ns);
                $error("%0t: Timed out after waiting %0d ns for DUT to report done!",
                       $time, timeout_ns);
            end
        join_any
        disable fork;

        print_out_buf();
        $dumpflush;
        $finish;
    end

    // Prints contents of frame buffer containing input image
    function void print_in_buf();
        string row_str = "";

        for (int y = 0; y < 5; ++y) begin
            row_str = $sformatf("frame_buf_in.img_buf[%02d]:", y);
            for (int x = 0; x < 5; ++x) begin
                row_str = $sformatf("%s %03d",
                                    row_str, dut_top.frame_buf_in.img_buf[y][x]);
            end
            $display("%0t: %s", $time, row_str);
        end
    endfunction : print_in_buf

    // Prints contents of frame buffer containing output image
    function void print_out_buf();
        string row_str = "";

        for (int y = 0; y < 5; ++y) begin
            row_str = $sformatf("frame_buf_rectify_clip.img_buf[%02d]:", y);
            for (int x = 0; x < 5; ++x) begin
                row_str = $sformatf("%s %03d",
                                    row_str, dut_top.frame_buf_rectify_clip.img_buf[y][x]);
            end
            $display("%0t: %s", $time, row_str);
        end
    endfunction : print_out_buf
endmodule : tb

