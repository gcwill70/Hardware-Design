// $Id: $
// File name:   tb_scg_self_ref_exit.sv
// Created:     4/26/2017
// Author:      Geoffrey Cramer
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Test bench for self-refresh exit FSM
`timescale 1ns / 100ps
module tb_scg_self_ref_exit;
	localparam CLOCK_PERIOD = 7;
	localparam CHECK_DELAY = 2;
	integer i = 0;


	reg tb_start, tb_clk, tb_n_rst;
	reg tb_done;
	reg [3:0] tb_command;

	always
	begin: CLK_GEN
		tb_clk = 0;
		#(CLOCK_PERIOD/2.0);
		tb_clk = 1;
		#(CLOCK_PERIOD/2.0);
	end

	scg_self_ref_exit DUT (
		.start(tb_start),
		.clk(tb_clk),
		.n_rst(tb_n_rst),
		.done(tb_done),
		.command(tb_command)
	);

	initial begin
		@(negedge tb_clk);
		tb_n_rst = 0;
		@(negedge tb_clk);
		tb_n_rst = 1;

		//First run
		@(negedge tb_clk);
		tb_start = 0;
		@(negedge tb_clk);
		tb_start = 1;
		if (tb_command != 0) begin
			$error("command incorrect");
		end
		for (i = 0; i < 10; i++) begin
			@(negedge tb_clk);
			if (tb_command != 0) begin
				$error("command incorrect");
			end
		end
		tb_start = 0;
		@(negedge tb_clk);
		if (tb_command != 0) begin
			$error("command incorrect");
		end
		if (tb_done != 1) begin
			$error("done incorrect");
		end

		//second run
		@(negedge tb_clk);
		tb_start = 0;
		@(negedge tb_clk);
		tb_start = 1;
		if (tb_command != 0) begin
			$error("command incorrect");
		end
		for (i = 0; i < 10; i++) begin
			@(negedge tb_clk);
			if (tb_command != 0) begin
				$error("command incorrect");
			end
		end
		tb_start = 0;
		@(negedge tb_clk);
		if (tb_command != 0) begin
			$error("command incorrect");
		end
		if (tb_done != 1) begin
			$error("done incorrect");
		end
	end

endmodule 