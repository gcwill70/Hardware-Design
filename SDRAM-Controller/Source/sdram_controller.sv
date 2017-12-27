// $Id: $
// File name:   sdram_controller.sv
// Created:     4/23/2017
// Author:      Geoffrey Cramer
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Top-level block for SDRAM controller
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
module sdram_controller (
	//Global
	input wire n_rst, clk,
	//Bus
	input wire h_sel, h_ready, h_write,
	input wire [1:0] h_trans,
	input wire [2:0] h_burst,
	input wire [31:0] h_wdata,
	input wire [24:0] h_addr,
	output wire h_readyout, h_resp,
	output wire [31:0] h_rdata,
	//Chip
	input wire [31:0] dq_out,
	output wire cke, cs_n, we_n, ras_n, cas_n, dqmh, dqml,
	output wire [1:0] ba,
	output wire [12:0] addr,
	output wire [31:0] dq_in
);

	wire idle, chip, refresh_com, select, burst, r_enable, w_enable, bus, mode, full, empty; //full & empty?
	wire [1:0] bank;
	wire [2:0] opcode;
	wire [3:0] command;
	wire [9:0] col_addr;
	wire [12:0] row_addr;
	wire [31:0] b_rdata, b_wdata, c_rdata, c_wdata;

	//Bus
	bus_interface bus_interface (
		.clk(clk),
		.n_rst(n_rst),
		.h_ready(h_ready),
		.h_write(h_write),
		.h_sel(h_sel),
		.idle(idle),
		.chip(chip),
		.refresh_com(refresh_com),
		.h_trans(h_trans),
		.h_burst(h_burst),
		.h_addr(h_addr),
		.h_wdata(h_wdata),
		.b_rdata(b_rdata),
		.h_readyout(h_readyout),
		.h_resp(h_resp),
		.select(select),
		.burst(burst),
		.r_enable(r_enable),
		.w_enable(w_enable),
		.bus(bus),
		.mode(mode),
		.bank(bank),
		.col_addr(col_addr),
		.row_addr(row_addr),
		.h_rdata(h_rdata),
		.b_wdata(b_wdata)
	);

	//Main Control Unit
	mcu mcu (
		.clk(clk),
		.n_rst(n_rst),
		.r_enable(r_enable),
		.w_enable(w_enable),
		.select(select),
		.refresh_com(refresh_com),
		.burst(burst),
		.idle(idle),
		.opcode(opcode)
	);

	//Subroutine Command Generation
	scg scg (
		.clk(clk),
		.n_rst(n_rst),
		.opcode(opcode),
		.command(command),
		.chip(chip),
		.idle(idle),
		.mode(mode)
	);

	//Data Buffer
	data_buffer buffer (
		.clk(clk),
		.n_rst(n_rst),
		.r_enable(r_enable),
		.w_enable(w_enable),
		.bus(bus),
		.chip(chip),
		.c_rdata(c_rdata),
		.b_wdata(b_wdata),
		.b_rdata(b_rdata),
		.c_wdata(c_wdata),
		.full(full),
		.empty(empty)
	);

	//Chip Interface
	chip_interface chip_interface (
		.burst(burst),
		.clk(clk),
		.n_rst(n_rst),
		.bank(bank),
		.command(command),
		.col_addr(col_addr),
		.row_addr(row_addr),
		.c_wdata(c_wdata),
		.dq_out(dq_out),
		.cke(cke),
		.cs_n(cs_n),
		.we_n(we_n),
		.ras_n(ras_n),
		.cas_n(cas_n),
		.dqmh(dqmh),
		.dqml(dqml),
		.ba(ba),
		.addr(addr),
		.dq_in(dq_in),
		.c_rdata(c_rdata)
	);

endmodule 