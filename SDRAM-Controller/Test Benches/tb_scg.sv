// $Id: $
// File name:   tb_scg.sv
// Created:     4/24/2017
// Author:      Geoffrey Cramer
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Test Bench for Subroutine Command Generation
`timescale 1ns / 100ps
module tb_scg;

	localparam CLOCK_PERIOD = 7;
	localparam CHECK_DELAY = 2;
	integer tb_test_case = 0;
	integer i = 0; //will iterate to make sure counters work

	typedef enum logic [2:0] {
		READY,
		INIT,
		SELF_REF,
		AUTO_REF,
		READ_NB,
		READ_BRST,
		WRITE_NB,
		WRITE_BRST
	} ProcessType;
	ProcessType tb_process;

	reg tb_clk, tb_n_rst;
	always
	begin: CLK_GEN
		tb_clk = 0;
		#(CLOCK_PERIOD/2.0);
		tb_clk = 1;
		#(CLOCK_PERIOD/2.0);
	end

	//DUT testbench variables
	reg tb_chip, tb_idle, tb_mode;
	reg [2:0] tb_opcode;
	reg [3:0] tb_command;

	scg DUT (
		.clk(tb_clk),
		.n_rst(tb_n_rst),
		.opcode(tb_opcode),
		.command(tb_command),
		.chip(tb_chip),
		.idle(tb_idle),
		.mode(tb_mode)
	);

	task com; //tests command value
		input [3:0] command;
	begin
		@(negedge tb_clk);
		if (tb_command != command) begin
			$error("Error: command is %1d but should be %1d.", tb_command, command);
		end
	end
	endtask	

	//SINGLE SUBROUTINE COMMAND SEQUENCE CHECKERS
	task nop;
	begin
		com(0);
	end
	endtask

	task active;
	begin
		com(0);
		com(1);
		com(0);
		com(0);
	end
	endtask

	task auto_ref;
	begin
		com(0);
		com(5);
		//wait 60 ns (9 cycles)
		for (i = 0; i < 8; i++) begin
			com(0);
		end
	end
	endtask

	task mrs_brst;
	begin
		com(0);
		com(8);
		com(0);
	end
	endtask

	task mrs_nb;
	begin
		com(0);
		com(7);
		com(0);
	end
	endtask

	task pre_all;
	begin
		com(0);
		com(4);
		com(0);
	end
	endtask

	task read_ap_brst; //burst read w/ auto-precharge
	begin
		com(0);
		com(2);
		com(0);
		com(0);
		com(0);
		if (tb_chip != 1) begin
			$error("Error: chip signal not asserted properly during read burst.");
		end
		com(0);
		if (tb_chip != 1) begin
			$error("Error: chip signal not asserted properly during read burst.");
		end
		com(0);
		if (tb_chip != 1) begin
			$error("Error: chip signal not asserted properly during read burst.");
		end
		com(0);
		if (tb_chip != 1) begin
			$error("Error: chip signal not asserted properly during read burst.");
		end
		com(0);
	end
	endtask

	task read_ap_nb; //non-burst read w/ auto-precharge
	begin
		com(0);
		com(2);
		com(0);
		com(0);
		com(0);
		if (tb_chip != 1) begin
			$error("Error: chip signal not asserted properly during single read.");
		end
	end
	endtask

	task self_ref;
	begin
		com(0);
		com(6);
		com(6);
		com(6);
		com(6);
		com(6);
		com(6);
	end
	endtask

	task self_ref_exit;
	begin
		com(0);
		//wait 10 cycles (67ns exit time)
		for (i = 0; i < 9; i++) begin
			com(0);
		end
		com(0);
	end
	endtask

	task write_ap_brst; //burst write w/ auto-precharge command sequence checker
	begin
		com(0);
		com(3);
		if (tb_chip != 1) begin
			$error("Error: chip signal not asserted properly during burst write.");
		end
		com(0);
		if (tb_chip != 1) begin
			$error("Error: chip signal not asserted properly during burst write.");
		end
		com(0);
		if (tb_chip != 1) begin
			$error("Error: chip signal not asserted properly during burst write.");
		end
		com(0);
		if (tb_chip != 1) begin
			$error("Error: chip signal not asserted properly during burst write.");
		end
		com(0);
		com(0);
	end
	endtask

	task write_ap_nb; //single write w/ auto-precharge command sequence checker
	begin
		com(0);
		com(3);
		if (tb_chip != 1) begin
			$error("Error: chip signal not asserted properly during burst write.");
		end
		com(0);
		com(0);
	end
	endtask

	//SUBROUTINE SELECTION SEQUENCE CHECKERS
	task nbm_init_seq; //Non-burst mode initialization sequence checker
	begin
		@(negedge tb_clk);
		tb_process = INIT;
		tb_n_rst = 0;
		@(negedge tb_clk);
		tb_n_rst = 1;
		@(negedge tb_clk);
		tb_opcode = 1;
		nop;
		for (i = 0; i < 14284; i++) begin
			@(negedge tb_clk);
		end
		pre_all;
		auto_ref;
		auto_ref;
		mrs_nb;
		nop;
	end
	endtask

	task bm_init_seq; //Burst mode initialization sequence checker
	begin
		@(negedge tb_clk);
		tb_process = INIT;
		tb_n_rst = 0;
		@(negedge tb_clk);
		tb_n_rst = 1;
		@(negedge tb_clk);
		tb_opcode = 1;
		nop;
		for (i = 0; i < 14284; i++) begin
			@(negedge tb_clk);
		end
		pre_all;
		auto_ref;
		auto_ref;
		mrs_brst;
		nop;
	end
	endtask

	task self_ref_seq;
	begin
		tb_process = SELF_REF;
		tb_opcode = 2;
		pre_all;
		self_ref;
		nop;
	end
	endtask
	
	task self_ref_exit_seq;
	begin
		tb_process = SELF_REF;
		tb_opcode = 0;
		self_ref_exit;
		nop;
	end
	endtask

	task auto_ref_seq;
	begin
		tb_process = AUTO_REF;
		tb_opcode = 3;
		auto_ref;
		nop;
	end
	endtask

	task nbm_write_nb_seq; //Non-burst mode single write sequence checker
	begin
		tb_process = WRITE_NB;
		tb_opcode = 6;
		active;
		write_ap_nb;
		nop;
	end
	endtask

	task bm_write_nb_seq; //Burst mode single write sequence checker
	begin
		tb_process = WRITE_NB;
		tb_opcode = 6;
		mrs_nb;
		active;
		write_ap_nb;
		mrs_brst;
		nop;
	end
	endtask

	task nbm_write_brst_seq; //Non-burst mode burst write sequence checker
	begin
		tb_process = WRITE_BRST;
		tb_opcode = 7;
		mrs_brst;
		active;
		write_ap_brst;
		mrs_nb;
		nop;
	end
	endtask

	task bm_write_brst_seq; //Burst mode single write sequence checker
	begin
		tb_process = WRITE_BRST;
		tb_opcode = 7;
		active;
		write_ap_brst;
		nop;
	end
	endtask

	task nbm_read_nb_seq; //Non-burst mode single read sequence checker
	begin
		tb_process = READ_NB;
		tb_opcode = 4;
		active;
		read_ap_nb;
		nop;
	end
	endtask

	task bm_read_nb_seq; //Burst mode single read sequence checker
	begin
		tb_process = READ_NB;
		tb_opcode = 4;
		mrs_nb;
		active;
		read_ap_nb;
		mrs_brst;
		nop;
	end
	endtask

	task nbm_read_brst_seq; //Non-burst mode burst read sequence checker
	begin
		tb_process = READ_BRST;
		tb_opcode = 5;
		mrs_brst;
		active;
		read_ap_brst;
		mrs_nb;
		nop;
	end
	endtask

	task bm_read_brst_seq; //Burst mode burst read sequence checker
	begin
		tb_process = READ_BRST;
		tb_opcode = 5;
		active;
		read_ap_brst;
		nop;
	end
	endtask

	initial begin
		//Non-burst
		tb_mode = 0;

		//Test Case 1: Non-burst mode initialization
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: non-burst mode initialization sequence.", tb_test_case);
		nbm_init_seq();

		//Test Case 2: Non-burst mode self-refresh
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: non-burst mode self-refresh sequence.", tb_test_case);
		self_ref_seq();

		//Test Case 3: Non-burst mode self-refresh exit
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: non-burst mode self-refresh exit sequence.", tb_test_case);
		self_ref_exit_seq();

		//Test Case 4: Non-burst mode auto-refresh
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: non-burst mode auto-refresh sequence.", tb_test_case);
		auto_ref_seq();

		//Test Case 5: Non-burst mode single write
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: non-burst mode single write sequence.", tb_test_case);
		nbm_write_nb_seq();

		//Test Case 6: Non-burst mode burst write
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: non-burst mode burst write sequence.", tb_test_case);
		nbm_write_brst_seq();

		//Test Case 7: Non-burst mode burst read
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: non-burst mode burst read sequence.", tb_test_case);
		nbm_read_brst_seq();
		
		//Test Case 8: Non-burst mode single read
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: non-burst mode single read sequence.", tb_test_case);
		nbm_read_nb_seq();

		//Burst
		tb_mode = 1;

		//Test Case 9: Burst mode initialization
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: burst mode initialization sequence.", tb_test_case);
		bm_init_seq();

		//Test Case 10: Burst mode self-refresh
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: burst mode self-refresh sequence.", tb_test_case);
		self_ref_seq();

		//Test Case 11: Burst mode self-refresh exit
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: burst mode self-refresh exit sequence.", tb_test_case);
		self_ref_exit_seq();

		//Test Case 12: Burst mode auto-refresh
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: burst mode auto-refresh sequence.", tb_test_case);
		auto_ref_seq();

		//Test Case 13: Burst mode single write
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: burst mode single write sequence.", tb_test_case);
		bm_write_nb_seq();

		//Test Case 14: Burst mode burst write
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: burst mode burst write sequence.", tb_test_case);
		bm_write_brst_seq();

		//Test Case 15: Burst mode burst read
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: burst mode burst read sequence.", tb_test_case);
		bm_read_brst_seq();
		
		//Test Case 16: Burst mode single read
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: burst mode single read sequence.", tb_test_case);
		bm_read_nb_seq();


		//Burst to non-burst switch
		tb_mode = 0;

		//Test Case 17: Switch back to non-burst mode and issue single read
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: burst mode single read sequence.", tb_test_case);
		nbm_read_nb_seq;
	end
endmodule 