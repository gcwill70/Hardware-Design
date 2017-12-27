// $Id: $
// File name:   tb_chip_interface.sv
// Created:     4/17/2017
// Author:      Geoffrey Cramer
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Testbench for Chip Interface
`timescale 1ns / 100ps
module tb_chip_interface ();

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
	reg tb_burst;
	reg [1:0] tb_bank;
	reg [3:0] tb_command;
	reg [9:0] tb_col_addr;
	reg [12:0] tb_row_addr;
	reg [31:0] tb_c_wdata, tb_dq_out;
	reg tb_cke, tb_cs_n, tb_we_n, tb_ras_n, tb_cas_n, tb_dqmh, tb_dqml;
	reg [1:0] tb_ba;
	reg [12:0] tb_addr;
	reg [31:0] tb_dq_in, tb_c_rdata;

	chip_interface DUT (
		.burst(tb_burst),
		.clk(tb_clk),
		.n_rst(tb_n_rst),
		.bank(tb_bank),
		.command(tb_command),
		.col_addr(tb_col_addr),
		.row_addr(tb_row_addr),
		.c_wdata(tb_c_wdata),
		.dq_out(tb_dq_out),
		.cke(tb_cke),
		.cs_n(tb_cs_n),
		.we_n(tb_we_n),
		.ras_n(tb_ras_n),
		.cas_n(tb_cas_n),
		.dqmh(tb_dqmh),
		.dqml(tb_dqml),
		.ba(tb_ba),
		.addr(tb_addr),
		.dq_in(tb_dq_in),
		.c_rdata(tb_c_rdata)
	);

	initial begin
		//reset dut
		@(posedge tb_clk);
		@(negedge tb_clk);	
		tb_n_rst = 0;

		@(posedge tb_clk);
		@(negedge tb_clk);	
		tb_n_rst = 1;
		
		//initializations
		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_bank = '0;
		tb_row_addr = '0;
		tb_col_addr = '0;
		tb_command = 0;
		tb_burst = 0;
		tb_c_wdata = 0;
		tb_dq_out = 0;

		//Test Case 1: Command 0
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: command %1d", tb_test_case, tb_test_case - 1);
		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_command = tb_test_case - 1;
		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_cke != 1) begin
			$error("Error during command %1d: cke should be %b", tb_test_case - 1, !tb_cke);
		end
		if (tb_cs_n != 0) begin
			$error("Error during command %1d: cs_n should be %b", tb_test_case - 1, !tb_cs_n);
		end
		if (tb_we_n != 1) begin
			$error("Error during command %1d: we_n should be %b", tb_test_case - 1, !tb_we_n);
		end
		if (tb_ras_n != 1) begin
			$error("Error during command %1d: ras_n should be %b", tb_test_case - 1, !tb_ras_n);
		end
		if (tb_cas_n != 1) begin
			$error("Error during command %1d: cas_n should be %b", tb_test_case - 1, !tb_cas_n);
		end
		if (tb_dqmh != 1) begin
			$error("Error during command %1d: dqmh should be %b", tb_test_case - 1, !tb_dqmh);
		end
		if (tb_dqml != 1) begin
			$error("Error during command %1d: dqml should be %b", tb_test_case - 1, !tb_dqml);
		end
		if (tb_addr[9:0] != '0) begin
			$error("Error during command %1d: addr[9:0] should be %1d", tb_test_case - 1, 0);
		end
		if (tb_addr[10] != '0) begin
			$error("Error during command %1d: addr[10] should be %1d", tb_test_case - 1, 0);
		end
		if (tb_addr[12:11] != '0) begin
			$error("Error during command %1d: addr[12:11] should be %1d", tb_test_case - 1, 0);
		end
		if (tb_ba != '0) begin
			$error("Error during command %1d: ba should be %b", tb_test_case - 1, tb_bank);
		end

		//Test Case 2: Command 1
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: command %1d", tb_test_case, tb_test_case - 1);
		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_command = tb_test_case - 1;
		tb_bank = 3;
		tb_row_addr = 13'b1010110100011;
		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_cke != 1) begin
			$error("Error during command %1d: cke should be %b", tb_test_case - 1, !tb_cke);
		end
		if (tb_cs_n != 0) begin
			$error("Error during command %1d: cs_n should be %b", tb_test_case - 1, !tb_cs_n);
		end
		if (tb_we_n != 1) begin
			$error("Error during command %1d: we_n should be %b", tb_test_case - 1, !tb_we_n);
		end
		if (tb_ras_n != 0) begin
			$error("Error during command %1d: ras_n should be %b", tb_test_case - 1, !tb_ras_n);
		end
		if (tb_cas_n != 1) begin
			$error("Error during command %1d: cas_n should be %b", tb_test_case - 1, !tb_cas_n);
		end
		if (tb_dqmh != 1) begin
			$error("Error during command %1d: dqmh should be %b", tb_test_case - 1, !tb_dqmh);
		end
		if (tb_dqml != 1) begin
			$error("Error during command %1d: dqml should be %b", tb_test_case - 1, !tb_dqml);
		end
		if (tb_addr != tb_row_addr) begin
			$error("Error during command %1d: addr[9:0] should be %1d", tb_test_case - 1, tb_row_addr);
		end
		if (tb_ba != tb_bank) begin
			$error("Error during command %1d: ba should be %b", tb_test_case - 1, tb_bank);
		end

		//Test Case 3: Command 2
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: command %1d", tb_test_case, tb_test_case - 1);
		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_command = tb_test_case - 1;
		tb_col_addr = 10'b1011111111;
		tb_bank = 1;
		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_cke != 1) begin
			$error("Error during command %1d: cke should be %b", tb_test_case - 1, !tb_cke);
		end
		if (tb_cs_n != 0) begin
			$error("Error during command %1d: cs_n should be %b", tb_test_case - 1, !tb_cs_n);
		end
		if (tb_we_n != 1) begin
			$error("Error during command %1d: we_n should be %b", tb_test_case - 1, !tb_we_n);
		end
		if (tb_ras_n != 1) begin
			$error("Error during command %1d: ras_n should be %b", tb_test_case - 1, !tb_ras_n);
		end
		if (tb_cas_n != 0) begin
			$error("Error during command %1d: cas_n should be %b", tb_test_case - 1, !tb_cas_n);
		end
		if (tb_dqmh != 0) begin
			$error("Error during command %1d: dqmh should be %b", tb_test_case - 1, !tb_dqmh);
		end
		if (tb_dqml != 0) begin
			$error("Error during command %1d: dqml should be %b", tb_test_case - 1, !tb_dqml);
		end
		if (tb_addr[9:0] != tb_col_addr) begin
			$error("Error during command %1d: addr[9:0] should be %1d", tb_test_case - 1, tb_col_addr);
		end
		if (tb_addr[10] != 1) begin
			$error("Error during command %1d: addr[10] should be %1d", tb_test_case - 1, 1);
		end
		if (tb_ba != tb_bank) begin
			$error("Error during command %1d: ba should be %b", tb_test_case - 1, tb_bank);
		end

		//Test Case 4: Command 3
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: command %1d", tb_test_case, tb_test_case - 1);
		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_command = tb_test_case - 1;
		tb_col_addr = 10'd20;
		tb_bank = 2;
		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_cke != 1) begin
			$error("Error during command %1d: cke should be %b", tb_test_case - 1, !tb_cke);
		end
		if (tb_cs_n != 0) begin
			$error("Error during command %1d: cs_n should be %b", tb_test_case - 1, !tb_cs_n);
		end
		if (tb_we_n != 0) begin
			$error("Error during command %1d: we_n should be %b", tb_test_case - 1, !tb_we_n);
		end
		if (tb_ras_n != 1) begin
			$error("Error during command %1d: ras_n should be %b", tb_test_case - 1, !tb_ras_n);
		end
		if (tb_cas_n != 0) begin
			$error("Error during command %1d: cas_n should be %b", tb_test_case - 1, !tb_cas_n);
		end
		if (tb_dqmh != 0) begin
			$error("Error during command %1d: dqmh should be %b", tb_test_case - 1, !tb_dqmh);
		end
		if (tb_dqml != 0) begin
			$error("Error during command %1d: dqml should be %b", tb_test_case - 1, !tb_dqml);
		end
		if (tb_addr[9:0] != tb_col_addr) begin
			$error("Error during command %1d: addr[9:0] should be %1d", tb_test_case - 1, tb_col_addr);
		end
		if (tb_addr[10] != 1) begin
			$error("Error during command %1d: addr[10] should be %1d", tb_test_case - 1, 1);
		end
		if (tb_ba != tb_bank) begin
			$error("Error during command %1d: ba should be %b", tb_test_case - 1, tb_bank);
		end

		//Test Case 5: Command 4
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: command %1d", tb_test_case, tb_test_case - 1);
		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_command = tb_test_case - 1;
		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_cke != 1) begin
			$error("Error during command %1d: cke should be %b", tb_test_case - 1, !tb_cke);
		end
		if (tb_cs_n != 0) begin
			$error("Error during command %1d: cs_n should be %b", tb_test_case - 1, !tb_cs_n);
		end
		if (tb_we_n != 0) begin
			$error("Error during command %1d: we_n should be %b", tb_test_case - 1, !tb_we_n);
		end
		if (tb_ras_n != 0) begin
			$error("Error during command %1d: ras_n should be %b", tb_test_case - 1, !tb_ras_n);
		end
		if (tb_cas_n != 1) begin
			$error("Error during command %1d: cas_n should be %b", tb_test_case - 1, !tb_cas_n);
		end
		if (tb_dqmh != 1) begin
			$error("Error during command %1d: dqmh should be %b", tb_test_case - 1, !tb_dqmh);
		end
		if (tb_dqml != 1) begin
			$error("Error during command %1d: dqml should be %b", tb_test_case - 1, !tb_dqml);
		end
		if (tb_addr[10] != 1) begin
			$error("Error during command %1d: addr[10] should be %1d", tb_test_case - 1, 1);
		end

		//Test Case 6: Command 5
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: command %1d", tb_test_case, tb_test_case - 1);
		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_command = tb_test_case - 1;
		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_cke != 1) begin
			$error("Error during command %1d: cke should be %b", tb_test_case - 1, !tb_cke);
		end
		if (tb_cs_n != 0) begin
			$error("Error during command %1d: cs_n should be %b", tb_test_case - 1, !tb_cs_n);
		end
		if (tb_we_n != 1) begin
			$error("Error during command %1d: we_n should be %b", tb_test_case - 1, !tb_we_n);
		end
		if (tb_ras_n != 0) begin
			$error("Error during command %1d: ras_n should be %b", tb_test_case - 1, !tb_ras_n);
		end
		if (tb_cas_n != 0) begin
			$error("Error during command %1d: cas_n should be %b", tb_test_case - 1, !tb_cas_n);
		end
		if (tb_dqmh != 1) begin
			$error("Error during command %1d: dqmh should be %b", tb_test_case - 1, !tb_dqmh);
		end
		if (tb_dqml != 1) begin
			$error("Error during command %1d: dqml should be %b", tb_test_case - 1, !tb_dqml);
		end

		//Test Case 7: Command 6
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: command %1d", tb_test_case, tb_test_case - 1);
		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_command = tb_test_case - 1;
		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_cke != 0) begin
			$error("Error during command %1d: cke should be %b", tb_test_case - 1, !tb_cke);
		end
		if (tb_cs_n != 0) begin
			$error("Error during command %1d: cs_n should be %b", tb_test_case - 1, !tb_cs_n);
		end
		if (tb_we_n != 1) begin
			$error("Error during command %1d: we_n should be %b", tb_test_case - 1, !tb_we_n);
		end
		if (tb_ras_n != 0) begin
			$error("Error during command %1d: ras_n should be %b", tb_test_case - 1, !tb_ras_n);
		end
		if (tb_cas_n != 0) begin
			$error("Error during command %1d: cas_n should be %b", tb_test_case - 1, !tb_cas_n);
		end
		if (tb_dqmh != 1) begin
			$error("Error during command %1d: dqmh should be %b", tb_test_case - 1, !tb_dqmh);
		end
		if (tb_dqml != 1) begin
			$error("Error during command %1d: dqml should be %b", tb_test_case - 1, !tb_dqml);
		end

		//Test Case 8: Command 7
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: command %1d", tb_test_case, tb_test_case - 1);
		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_command = tb_test_case - 1;
		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_cke != 1) begin
			$error("Error during command %1d: cke should be %b", tb_test_case - 1, !tb_cke);
		end
		if (tb_cs_n != 0) begin
			$error("Error during command %1d: cs_n should be %b", tb_test_case - 1, !tb_cs_n);
		end
		if (tb_we_n != 0) begin
			$error("Error during command %1d: we_n should be %b", tb_test_case - 1, !tb_we_n);
		end
		if (tb_ras_n != 0) begin
			$error("Error during command %1d: ras_n should be %b", tb_test_case - 1, !tb_ras_n);
		end
		if (tb_cas_n != 0) begin
			$error("Error during command %1d: cas_n should be %b", tb_test_case - 1, !tb_cas_n);
		end
		if (tb_dqmh != 1) begin
			$error("Error during command %1d: dqmh should be %b", tb_test_case - 1, !tb_dqmh);
		end
		if (tb_dqml != 1) begin
			$error("Error during command %1d: dqml should be %b", tb_test_case - 1, !tb_dqml);
		end
		if (tb_addr[9:0] != 10'b0000110000) begin
			$error("Error during command %1d: addr[9:0] should be %1d", tb_test_case - 1, 10'b0000110000);
		end

		//Test Case 9: Command 8
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: command %1d", tb_test_case, tb_test_case - 1);
		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_command = tb_test_case - 1;
		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_cke != 1) begin
			$error("Error during command %1d: cke should be %b", tb_test_case - 1, !tb_cke);
		end
		if (tb_cs_n != 0) begin
			$error("Error during command %1d: cs_n should be %b", tb_test_case - 1, !tb_cs_n);
		end
		if (tb_we_n != 0) begin
			$error("Error during command %1d: we_n should be %b", tb_test_case - 1, !tb_we_n);
		end
		if (tb_ras_n != 0) begin
			$error("Error during command %1d: ras_n should be %b", tb_test_case - 1, !tb_ras_n);
		end
		if (tb_cas_n != 0) begin
			$error("Error during command %1d: cas_n should be %b", tb_test_case - 1, !tb_cas_n);
		end
		if (tb_dqmh != 1) begin
			$error("Error during command %1d: dqmh should be %b", tb_test_case - 1, !tb_dqmh);
		end
		if (tb_dqml != 1) begin
			$error("Error during command %1d: dqml should be %b", tb_test_case - 1, !tb_dqml);
		end
		if (tb_addr[9:0] != 10'b0000110010) begin
			$error("Error during command %1d: addr[9:0] should be %1d", tb_test_case - 1, 10'b0000110010);
		end
	end

endmodule 