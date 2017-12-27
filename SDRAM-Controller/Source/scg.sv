// $Id: $
// File name:   scg.sv
// Created:     4/24/2017
// Author:      Geoffrey Cramer
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Subroutine Command Generation
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
OPCODES
0 - ready
1 - initialize
2 - self-refresh
3 - auto-refresh
4 - single read
5 - burst read
6 - single write
7 - burst write
SELECT
0 - nop
1 - active
2 - single read
3 - burst read
4 - single write
5 - burst write
6 - auto-refresh
7 - self-refresh
8 - self-refresh exit sequence
9 - precharge all banks
10 - mode register set: non-burst mode
11 - mode register set: burst mode
*/
module scg (
	input wire mode, clk, n_rst,
	input wire [2:0] opcode,
	output reg chip, idle,
	output reg [3:0] command
);
	
	reg nop, act, read_nb, read_brst, write_nb, write_brst, auto_ref, self_ref, self_ref_exit, pre_all, mrs_nb, mrs_brst;
	reg [3:0] select, select_nb, select_brst;
	reg start, start_nb, start_brst;
	reg idle_nb, idle_brst;
	reg [2:0] opcode_brst, opcode_nb;
	reg cnt_done;
	reg done;
	reg pre_all_done;
	reg [3:0] pre_all_command;
	reg act_done;
	reg [3:0] act_command;
	reg self_ref_done;
	reg [3:0] self_ref_command;
	reg nop_done;
	reg [3:0] nop_command;
	reg mrs_brst_done;
	reg [3:0] mrs_brst_command;
	reg mrs_nb_done;
	reg [3:0] mrs_nb_command;
	reg write_nb_done, write_nb_chip;
	reg [3:0] write_nb_command;
	reg write_brst_done, write_brst_chip;
	reg [3:0] write_brst_command;
	reg read_nb_done, read_nb_chip;
	reg [3:0] read_nb_command;
	reg read_brst_done, read_brst_chip;
	reg [3:0] read_brst_command;
	reg auto_ref_done;
	reg [3:0] auto_ref_command;
	reg self_ref_exit_done;
	reg [3:0] self_ref_exit_command;

	//OpcodeNB
	scg_opcode_nb opcode_nonburst (
		.done(done),
		.cnt_done(cnt_done),		
		.clk(clk),
		.n_rst(n_rst),
		.opcode(opcode_nb),
		.start(start_nb),
		.idle(idle_nb),
		.select(select_nb)
	);

	//OpcodeBRST
	scg_opcode_brst opcode_burst (
		.done(done),
		.cnt_done(cnt_done),		
		.clk(clk),
		.n_rst(n_rst),
		.opcode(opcode_brst),
		.start(start_brst),
		.idle(idle_brst),
		.select(select_brst)
	);

	//Mode Selection
	always_comb
	begin: MODE_SEL
		if (mode) begin
			select = select_brst;
			idle = idle_brst;
			start = start_brst;
			opcode_brst = opcode;
			opcode_nb = 0;
		end else begin
			select = select_nb;
			idle = idle_nb;
			start = start_nb;
			opcode_nb = opcode;
			opcode_brst = 0;
		end
	end

	//Selection Decoder
	always_comb
	begin: SEL_DECODER
		nop = 0;
		act = 0;
		read_nb = 0;
		read_brst = 0;
		write_nb = 0;
		write_brst = 0;
		auto_ref = 0;
		self_ref = 0;
		self_ref_exit = 0;
		pre_all = 0;
		mrs_nb = 0;
		mrs_brst = 0;
		case (select)
			0: nop = 1;
			1: act = 1;
			2: read_nb = 1;
			3: read_brst = 1;
			4: write_nb = 1;
			5: write_brst = 1;
			6: auto_ref = 1;
			7: self_ref = 1;
			8: self_ref_exit = 1;
			9: pre_all = 1;
			10: mrs_nb = 1;
			11: mrs_brst = 1;
		endcase
	end

	//Self-refresh Exit FSM
	scg_self_ref_exit self_refresh_exit (
		.start(self_ref_exit),
		.clk(clk),
		.n_rst(n_rst),
		.done(self_ref_exit_done),
		.command(self_ref_exit_command)
	);

	//Precharge All FSM
	scg_pall precharge_all (
		.start(pre_all),
		.clk(clk),
		.n_rst(n_rst),
		.done(pre_all_done),
		.command(pre_all_command)
	);

	//Active FSM
	scg_active active (
		.start(act),
		.clk(clk),
		.n_rst(n_rst),
		.done(act_done),
		.command(act_command)
	);

	//Self-refresh FSM
	scg_self_ref self_refresh (
		.start(self_ref), 
		.clk(clk),
		.n_rst(n_rst),
		.done(self_ref_done),
		.command(self_ref_command)
	);

	//Nop
	always_comb
	begin: NOP_BLOCK
		if (nop) begin
			nop_command = 0;
			nop_done = 1;
		end
	end

	//MRS Burst FSM
	scg_mrs_brst mrs_burst (
		.start(mrs_brst),
		.clk(clk),
		.n_rst(n_rst),
		.done(mrs_brst_done),
		.command(mrs_brst_command)
	);

	//MRS Non-burst FSM
	scg_mrs_nb mrs_nonburst (
		.start(mrs_nb),
		.clk(clk),
		.n_rst(n_rst),
		.done(mrs_nb_done),
		.command(mrs_nb_command)
	);

	//Write Burst FSM
	scg_writeap_brst write_burst (
		.start(write_brst),
		.clk(clk),
		.n_rst(n_rst),
		.done(write_brst_done),
		.chip(write_brst_chip),
		.command(write_brst_command)
	);

	//Write Non-burst FSM
	scg_writeap_nb write_nonburst (
		.start(write_nb),
		.clk(clk),
		.n_rst(n_rst),
		.done(write_nb_done),
		.chip(write_nb_chip),
		.command(write_nb_command)
	);

	//Read Burst FSM
	scg_readap_brst read_burst (
		.start(read_brst),
		.clk(clk),
		.n_rst(n_rst),
		.done(read_brst_done),
		.chip(read_brst_chip),
		.command(read_brst_command)
	);

	//Read Non-burst FSM
	scg_readap_nb read_nonburst (
		.start(read_nb),
		.clk(clk),
		.n_rst(n_rst),
		.done(read_nb_done),
		.chip(read_nb_chip),
		.command(read_nb_command)
	);

	//Auto-refresh FSM
	scg_auto_ref auto_refresh (
		.start(auto_ref),
		.clk(clk),
		.n_rst(n_rst),
		.done(auto_ref_done),
		.command(auto_ref_command)
	);

	//Command Selection
	always_comb 
	begin: COM_SEL
		command = 0;
		chip = 0;
		done = 0;
		case (select)
			0: begin
				command = nop_command;
				done = nop_done;
			end
			1: begin
				command = act_command;
				done = act_done;
			end
			2: begin
				command = read_nb_command;
				chip = read_nb_chip;
				done = read_nb_done;
			end
			3: begin
				command = read_brst_command;
				chip = read_brst_chip;
				done = read_brst_done;
			end
			4: begin
				command = write_nb_command;
				chip = write_nb_chip;
				done = write_nb_done;
			end
			5: begin
				command = write_brst_command;
				chip = write_brst_chip;
				done = write_brst_done;
			end
			6: begin
				command = auto_ref_command;
				done = auto_ref_done;
			end
			7: begin
				command = self_ref_command;
				done = self_ref_done;
			end
			8: begin
				command = self_ref_exit_command;
				done = self_ref_exit_done;
			end
			9: begin
				command = pre_all_command;
				done = pre_all_done;
			end
			10: begin
				command = mrs_nb_command;
				done = mrs_nb_done;
			end
			11: begin
				command = mrs_brst_command;
				done = mrs_brst_done;
			end
		endcase
	end

	//Init Counter
	flex_counter #(.NUM_CNT_BITS(14))
	INIT_COUNT (
		.clear(1'b0),
		.count_enable(start),
		.clk(clk),
		.n_rst(n_rst),
		.rollover_flag(cnt_done),
		.rollover_val(14'd14286)
	);

endmodule 
