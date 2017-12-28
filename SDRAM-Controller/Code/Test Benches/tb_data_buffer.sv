// $Id: $
// File name:   tb_data_buffer.sv
// Created:     4/22/2017
// Author:      Geoffrey Cramer
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Test Bench for 32-bit data buffer
`timescale 1ns / 100ps
module tb_data_buffer;

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
	reg tb_r_enable, tb_w_enable, tb_bus, tb_chip, tb_full, tb_empty;
	reg [31:0] tb_c_rdata, tb_b_wdata;
	reg [31:0] tb_b_rdata, tb_c_wdata;

	data_buffer DUT (
		.clk(tb_clk),
		.n_rst(tb_n_rst),
		.r_enable(tb_r_enable),
		.w_enable(tb_w_enable),
		.bus(tb_bus),
		.chip(tb_chip),
		.c_rdata(tb_c_rdata),
		.b_wdata(tb_b_wdata),
		.b_rdata(tb_b_rdata),
		.c_wdata(tb_c_wdata),
		.full(tb_full),
		.empty(tb_empty)
	);

	task reset_dut;
	begin
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
	end
	endtask

	initial begin
		//reset dut
		reset_dut();

		//initialize inputs
		tb_r_enable = 0;
		tb_w_enable = 0;
		tb_bus = 0;
		tb_chip = 0;
		tb_c_rdata = '0;
		tb_b_wdata = '0;

		//Test Case 1: Read burst
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: burst read.", tb_test_case);
		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_r_enable = 1;
		if (tb_empty != 1) begin
			$error("Error during read: FIFO did not preperly assert its empty signal on reset.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_r_enable = 0;
		tb_chip = 1;
		tb_c_rdata = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_c_rdata = 2;

		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_c_rdata = 3;

		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_c_rdata = 4;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_full != 1) begin
			$error("Error during read: FIFO did not preperly assert its full signal.");
		end
		tb_chip = 0;

		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_bus = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_b_rdata != 1) begin
			$error("Error during read: first word of output data is not correct.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_b_rdata != 2) begin
			$error("Error during read: second word of output data is not correct.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_b_rdata != 3) begin
			$error("Error during read: third word of output data is not correct.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_b_rdata != 4) begin
			$error("Error during read: fourth word of output data is not correct.");
		end
		if (tb_empty != 1) begin
			$error("Error during read: FIFO did not preperly assert its empty signal.");
		end
		tb_bus = 0;

		//Test Case 2: Write burst
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: burst write.", tb_test_case);
		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_w_enable = 1;
		if (tb_empty != 1) begin
			$error("Error during write: FIFO did not preperly assert its empty signal.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_w_enable = 0;
		tb_bus = 1;
		tb_b_wdata = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_b_wdata = 2;

		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_b_wdata = 3;

		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_b_wdata = 4;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_full != 1) begin
			$error("Error during write: FIFO did not preperly assert its full signal.");
		end
		tb_bus = 0;

		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_chip = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_c_wdata != 1) begin
			$error("Error during write: first word of output data is not correct.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_c_wdata != 2) begin
			$error("Error during write: second word of output data is not correct.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_c_wdata != 3) begin
			$error("Error during write: third word of output data is not correct.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_c_wdata != 4) begin
			$error("Error during write: fourth word of output data is not correct.");
		end
		if (tb_empty != 1) begin
			$error("Error during write: FIFO did not preperly assert its empty signal.");
		end
		tb_chip = 0;

		//Test Case 3: Read burst - simultaneous I/O
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: burst read w/ simultaneous I/O.", tb_test_case);
		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_r_enable = 1;
		if (tb_empty != 1) begin
			$error("Error during read: FIFO did not preperly assert its empty signal on reset.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_r_enable = 0;
		tb_chip = 1;
		tb_c_rdata = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_bus = 1;
		tb_c_rdata = 2;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_b_rdata != 1) begin
			$error("Error: during read: FIFO did not output first word properly.");
		end
		tb_c_rdata = 3;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_b_rdata != 2) begin
			$error("Error: during read: FIFO did not output second word properly.");
		end
		tb_c_rdata = 4;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_b_rdata != 3) begin
			$error("Error: during read: FIFO did not output third word properly.");
		end
		tb_c_rdata = 5;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_b_rdata != 4) begin
			$error("Error: during read: FIFO did not output fourth word properly.");
		end
		tb_chip = 0;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_b_rdata != 5) begin
			$error("Error: during read: FIFO did not output fifth word properly.");
		end
		if (tb_empty != 1) begin
			$error("Error during read: FIFO did not preperly assert its empty signal.");
		end
		tb_bus = 0;

		//Test Case 4: Write burst - simultaneous I/O
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: burst write w/ simultaneous I/O.", tb_test_case);
		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_w_enable = 1;
		if (tb_empty != 1) begin
			$error("Error during write: FIFO did not preperly assert its empty signal.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_w_enable = 0;
		tb_bus = 1;
		tb_b_wdata = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_chip = 1;
		tb_b_wdata = 2;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_c_wdata != 1) begin
			$error("Error during write: FIFO did not output first word properly.");
		end
		tb_b_wdata = 3;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_c_wdata != 2) begin
			$error("Error during write: FIFO did not output second word properly.");
		end
		tb_b_wdata = 4;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_c_wdata != 3) begin
			$error("Error during write: FIFO did not output third word properly.");
		end
		tb_b_wdata = 5;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_c_wdata != 4) begin
			$error("Error during write: FIFO did not output fourth word properly.");
		end
		tb_bus = 0;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_c_wdata != 5) begin
			$error("Error during write: FIFO did not output fifth word properly.");
		end
		if (tb_empty != 1) begin
			$error("Error during read: FIFO did not preperly assert its empty signal.");
		end
		tb_chip = 0;
	end

endmodule 