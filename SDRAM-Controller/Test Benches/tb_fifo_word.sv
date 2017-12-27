// $Id: $
// File name:   tb_fifo_word.sv
// Created:     4/22/2017
// Author:      Geoffrey Cramer
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Test bench for 32-bit fifo
`timescale 1ns / 100ps
module tb_fifo_word ();
	localparam CLOCK_PERIOD = 7;
	localparam CHECK_DELAY = 2;
	integer tb_test_case = 0;

	reg tb_clk, tb_n_rst;
	always
	begin: CLK_GEN
		tb_clk = 0;
		#(CLOCK_PERIOD/2.0);
		tb_clk = 1;
		#(CLOCK_PERIOD/2.0);
	end

	//DUT testbench variables
	reg tb_read_enable, tb_write_enable;
	reg [31:0] tb_wdata;
	reg tb_full, tb_empty;
	reg [31:0] tb_rdata;

	fifo_word DUT (
		.clk(tb_clk),
		.n_rst(tb_n_rst),
		.read_enable(tb_read_enable),
		.write_enable(tb_write_enable),
		.wdata(tb_wdata),
		.full(tb_full),
		.empty(tb_empty),
		.rdata(tb_rdata)
	);

	initial begin
		@(negedge tb_clk);
		// Activate the design's reset (does not need to be synchronize with clock)
		tb_n_rst = 1;
		
		// Wait for a couple clock cycles
		@(posedge tb_clk);
		@(posedge tb_clk);
		tb_n_rst = 0;
		
		// Release the reset
		@(negedge tb_clk);
		tb_n_rst = 1;
		
		// Wait for a while before activating the design
		@(posedge tb_clk);
		@(posedge tb_clk);
		tb_read_enable = 0;
		tb_write_enable = 0;
		tb_wdata = 0;

		//Test Case 1: Data In
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: data in.", tb_test_case);
		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_write_enable = 1;
		if (tb_empty != 1) begin
			$error("Error: FIFO did not preperly assert its empty signal on reset.");
		end
		tb_wdata = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_wdata = 2;

		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_wdata = 3;

		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_wdata = 4;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_full != 1) begin
			$error("Error: FIFO did not preperly assert its full signal.");
		end
		tb_write_enable = 0;

		//Test Case 2: Data Out
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: data out.", tb_test_case);
		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_read_enable = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_rdata != 1) begin
			$error("Error: first word was not output properly.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_rdata != 2) begin
			$error("Error: second word was not output properly.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_rdata != 3) begin
			$error("Error: third word was not output properly.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_rdata != 4) begin
			$error("Error: fourth word was not output properly.");
		end
		tb_read_enable = 0;

		//Test Case 3: Simultaneous I/O
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: data in and out.", tb_test_case);
		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_write_enable = 1;
		if (tb_empty != 1) begin
			$error("Error: FIFO did not preperly assert its empty signal on reset.");
		end
		tb_wdata = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_read_enable = 1;
		tb_wdata = 2;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_rdata != 1) begin
			$error("Error: first word was not output properly.");
		end
		tb_wdata = 3;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_rdata != 2) begin
			$error("Error: second word was not output properly.");
		end
		tb_wdata = 4;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_rdata != 3) begin
			$error("Error: second word was not output properly.");
		end
		tb_wdata = 5;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_rdata != 4) begin
			$error("Error: fourth word was not output properly.");
		end
		tb_write_enable = 0;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_rdata != 5) begin
			$error("Error: fourth word was not output properly.");
		end
		if (tb_empty != 1) begin
			$error("Error: FIFO did not preperly assert its empty signal.");
		end
		tb_read_enable = 0;
	end
endmodule 