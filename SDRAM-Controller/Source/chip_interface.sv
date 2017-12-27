// $Id: $
// File name:   chip_interface.sv
// Created:     4/17/2017
// Author:      Geoffrey Cramer
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: SDRAM chip interface
/*
COMMANDS
0 - nop
1 - active
2 - read w/ auto-precharge
3 - write w/ auto-precharge
4 - precharge all banks
5 - auto-refresh
6 - self-refresh
7 - mode register set: non-burst mode
8 - mode register set: burst mode
*/
module chip_interface (
	input wire burst, clk, n_rst,
	input wire [1:0] bank,
	input wire [3:0] command,
	input wire [9:0] col_addr,
	input wire [12:0] row_addr,
	input wire [31:0] c_wdata, dq_out,
	output reg cke, cs_n, we_n, ras_n, cas_n, dqmh, dqml,
	output reg [1:0] ba,
	output reg [12:0] addr,
	output reg [31:0] dq_in, c_rdata
);

	always_ff @(posedge clk, negedge n_rst) begin
		if (n_rst == 1'b0) begin
			dq_in <= '0;
			c_rdata <= '0;
		end else begin
			dq_in <= c_wdata;
			c_rdata <= dq_out;
		end
	end

	always_comb
	begin: COMMAND_DECODER
		cke = 1;
		cs_n = 0;
		we_n = 1;
		ras_n = 1;
		cas_n = 1;
		dqmh = 1;
		dqml = 1;
		addr[12:0] = '0;
		ba = '0;
		case (command)
			4'd1: begin
				ras_n = 0;
				ba = bank;
				addr = row_addr;
			end
			4'd2: begin
				dqml = 0;
				dqmh = 0;
				cas_n = 0;
				ba = bank;
				addr[10] = 1;
				addr[9:0] = col_addr;
			end
			4'd3: begin
				dqml = 0;
				dqmh = 0;
				cas_n = 0;
				we_n = 0;
				ba = bank;
				addr[10] = 1;
				addr[9:0] = col_addr;
			end
			4'd4: begin
				ras_n = 0;
				we_n = 0;
				addr[10] = 1;
			end
			4'd5: begin
				ras_n = 0;
				cas_n = 0;
			end
			4'd6: begin
				cke = 0;
				ras_n = 0;
				cas_n = 0;
			end
			4'd7: begin
				ras_n = 0;
				cas_n = 0;
				we_n = 0;
				addr[9:0] = 10'b0000110000;
			end
			4'd8: begin
				ras_n = 0;
				cas_n = 0;
				we_n = 0;
				addr[9:0] = 10'b0000110010;
			end
		endcase
	end

endmodule 