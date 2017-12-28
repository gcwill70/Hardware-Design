// $Id: $
// File name:   tb_mcu.sv
// Created:     4/24/2017
// Author:      Geoffrey Cramer
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Test Bench for Main Control Unit
`timescale 1ns / 100ps
module tb_mcu;

	localparam CLOCK_PERIOD = 7;
	localparam CHECK_DELAY = 2;
	integer tb_test_case = 0;
	integer i = 0; //will iterate to make sure the refresh counter works

	reg tb_clk, tb_n_rst;
	always
	begin: CLK_GEN
		tb_clk = 0;
		#(CLOCK_PERIOD/2.0);
		tb_clk = 1;
		#(CLOCK_PERIOD/2.0);
	end

	//DUT testbench variables
	reg tb_r_enable, tb_w_enable, tb_select, tb_burst, tb_idle, tb_refresh_com;
	reg [2:0] tb_opcode;

	mcu DUT (
		.clk(tb_clk),
		.n_rst(tb_n_rst),
		.r_enable(tb_r_enable),
		.w_enable(tb_w_enable),
		.select(tb_select),
		.refresh_com(tb_refresh_com),
		.burst(tb_burst),
		.idle(tb_idle),
		.opcode(tb_opcode)
	);

	initial begin
		//reset
		@(negedge tb_clk);
		// Activate the design's reset (does not need to be synchronize with clock)
		tb_n_rst = 1;
		
		// Wait for a couple clock cycles
		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_n_rst = 0;
		
		// Release the reset
		@(negedge tb_clk);
		tb_n_rst = 1;

		//initialize inputs
		tb_r_enable = 0;
		tb_w_enable = 0;
		tb_select = 0;
		tb_burst = 0;
		tb_idle = 0;

		//Test Case 1: Initialization
		@(negedge tb_clk);
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: initialization.", tb_test_case);
		if (tb_opcode != 1) begin
			$error("Error: incorrect opcode.");
		end
		tb_idle = 1;

		//Test Case 2: Ready
		@(negedge tb_clk);
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: ready.", tb_test_case);
		if (tb_opcode != 0) begin
			$error("Error: incorrect opcode.");
		end
		tb_select = 0;

		//Test Case 3: Self-refresh
		@(negedge tb_clk);
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: self_refresh.", tb_test_case);
		if (tb_opcode != 2) begin
			$error("Error: incorrect opcode.");
		end
		//make sure counter is disabled
		for (i = 0; i < 1025; i++) begin
			@(posedge tb_clk);
		end
		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_refresh_com != 0) begin
			$error("Error: refresh counter is not disabled.");
		end
		tb_select = 1;

		@(negedge tb_clk);
		if (tb_opcode != 0) begin
			$error("Error: incorrect opcode.");
		end

		@(negedge tb_clk);
		tb_n_rst = 0;
		@(negedge tb_clk);
		tb_n_rst = 1;
		@(negedge tb_clk);

		//Test Case 4: Forced Auto-refresh
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: forced auto-refresh.", tb_test_case);
		tb_r_enable = 1;
		tb_idle = 1;
		for (i = 0; i < 1023; i++) begin
			@(negedge tb_clk);
			tb_idle = !tb_idle;
			if (tb_opcode == 3) begin
				$error("Error: didn't properly ignore refresh.");
			end
		end
		@(negedge tb_clk);
		if (tb_refresh_com != 1) begin
			$error("Error: refresh counter is not enabled.");
		end
		@(negedge tb_clk);
		if (tb_opcode != 3) begin
			$error("Error: incorrect opcode.");
		end
		tb_idle = 0;

		@(negedge tb_clk);
		if (tb_opcode != 3) begin
			$error("Error: incorrect opcode.");
		end
		//make sure counter is disabled
		for (i = 0; i < 1025; i++) begin
			@(posedge tb_clk);
		end
		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_refresh_com != 0) begin
			$error("Error: refresh counter is not disabled.");
		end
		tb_idle = 1;
		@(negedge tb_clk);
		if (tb_opcode != 0) begin
			$error("Error: incorrect opcode.");
		end

		//Test Case 5: Natural Auto-refresh
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: natural auto-refresh.", tb_test_case);
		tb_r_enable = 0;
		tb_w_enable = 0;
		tb_n_rst = 0;
		@(negedge tb_clk);
		tb_n_rst = 1;
		@(negedge tb_clk);
		for (i = 0; i < 513; i++) begin
			@(posedge tb_clk);
		end
		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_opcode != 3) begin
			$error("Error: incorrect opcode.");
		end
		tb_idle = 0;
		@(negedge tb_clk);
		if (tb_opcode != 3) begin
			$error("Error: incorrect opcode.");
		end
		tb_idle = 1;
		@(negedge tb_clk);
		if (tb_opcode != 0) begin
			$error("Error: incorrect opcode.");
		end

		//Test Case 6: Write Burst
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: write burst.", tb_test_case);
		tb_w_enable = 1;
		tb_burst = 1;
		@(negedge tb_clk);
		if (tb_opcode != 7) begin
			$error("Error: incorrect opcode.");
		end
		tb_idle = 0;
		@(negedge tb_clk);
		if (tb_opcode != 7) begin
			$error("Error: incorrect opcode.");
		end
		tb_idle = 1;
		@(negedge tb_clk);
		if (tb_opcode != 0) begin
			$error("Error: incorrect opcode.");
		end

		//Test Case 7: Single Write
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: single write.", tb_test_case);
		tb_r_enable = 0;
		tb_w_enable = 1;
		tb_select = 1;
		tb_burst = 0;
		tb_idle = 1;
		@(negedge tb_clk);
		if (tb_opcode != 6) begin
			$error("Error: incorrect opcode.");
		end
		tb_idle = 0;
		@(negedge tb_clk);
		if (tb_opcode != 6) begin
			$error("Error: incorrect opcode.");
		end
		tb_idle = 1;
		@(negedge tb_clk);
		if (tb_opcode != 0) begin
			$error("Error: incorrect opcode.");
		end

		//Test Case 8: Burst Read
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: burst read.", tb_test_case);
		tb_r_enable = 1;
		tb_w_enable = 0;
		tb_select = 1;
		tb_burst = 1;
		tb_idle = 1;
		@(negedge tb_clk);
		if (tb_opcode != 5) begin
			$error("Error: incorrect opcode.");
		end
		tb_idle = 0;
		@(negedge tb_clk);
		if (tb_opcode != 5) begin
			$error("Error: incorrect opcode.");
		end
		tb_idle = 1;
		@(negedge tb_clk);
		if (tb_opcode != 0) begin
			$error("Error: incorrect opcode.");
		end

		//Test Case 9: Single Read
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: single read.", tb_test_case);
		tb_r_enable = 1;
		tb_w_enable = 0;
		tb_select = 1;
		tb_burst = 0;
		tb_idle = 1;
		@(negedge tb_clk);
		if (tb_opcode != 4) begin
			$error("Error: incorrect opcode.");
		end
		tb_idle = 0;
		@(negedge tb_clk);
		if (tb_opcode != 4) begin
			$error("Error: incorrect opcode.");
		end
		tb_idle = 1;
		@(negedge tb_clk);
		if (tb_opcode != 0) begin
			$error("Error: incorrect opcode.");
		end
	end

endmodule 