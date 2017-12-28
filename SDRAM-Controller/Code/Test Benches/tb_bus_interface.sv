// $Id: $
// File name:   tb_bus_interface.sv
// Created:     4/17/2017
// Author:      Geoffrey Cramer
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Test bench for bus interface
`timescale 1ns / 100ps
module tb_bus_interface;

	localparam CLOCK_PERIOD = 7;
	localparam CHECK_DELAY = 2;
	integer tb_test_case = 0;

	typedef enum logic [2:0] {
		RESET,
		SELECT,
		WRITE_NB,
		WRITE_BRST,
		READ_NB,
		READ_BRST,
		DESELECT
	} ProcessType;
	ProcessType tb_process; //label for current task being run

	reg tb_clk, tb_n_rst;
	always
	begin: CLK_GEN
		tb_clk = 0;
		#(CLOCK_PERIOD/2.0);
		tb_clk = 1;
		#(CLOCK_PERIOD/2.0);
	end

	//DUT testbench variables
	reg tb_h_ready, tb_h_write, tb_h_sel, tb_idle, tb_chip, tb_refresh_com, tb_h_resp;
	reg [1:0] tb_h_trans;
	reg [2:0] tb_h_burst;
	reg [24:0] tb_h_addr;
	reg [31:0] tb_h_wdata, tb_b_rdata;
	reg tb_h_readyout, tb_h_resp, tb_select, tb_burst, tb_r_enable, tb_w_enable, tb_bus;
	reg tb_mode;
	reg [1:0] tb_bank;
	reg [9:0] tb_col_addr;
	reg [12:0] tb_row_addr;
	reg [31:0] tb_h_rdata, tb_b_wdata;

	bus_interface DUT (
		.clk(tb_clk),
		.n_rst(tb_n_rst),
		.h_ready(tb_h_ready),
		.h_write(tb_h_write),
		.h_sel(tb_h_sel),
		.idle(tb_idle),
		.chip(tb_chip),
		.refresh_com(tb_refresh_com),
		.h_trans(tb_h_trans),
		.h_burst(tb_h_burst),
		.h_addr(tb_h_addr),
		.h_wdata(tb_h_wdata),
		.b_rdata(tb_b_rdata),
		.h_readyout(tb_h_readyout),
		.h_resp(tb_h_resp),
		.select(tb_select),
		.burst(tb_burst),
		.r_enable(tb_r_enable),
		.w_enable(tb_w_enable),
		.bus(tb_bus),
		.mode(tb_mode),
		.bank(tb_bank),
		.col_addr(tb_col_addr),
		.row_addr(tb_row_addr),
		.h_rdata(tb_h_rdata),
		.b_wdata(tb_b_wdata),
		.h_resp(tb_h_resp)
	);

	task reset_dut;
	begin
		tb_process = RESET;
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
		
		// Wait for a while before activating the design
		@(posedge tb_clk);
		@(posedge tb_clk);
	end
	endtask

	task select; //master selects the slave
		input burst;
	begin
		tb_process = SELECT;
		@(negedge tb_clk);

		//initialize select signal
		tb_h_ready = 1;
		tb_h_sel = 0;
		@(posedge tb_clk);
		@(posedge tb_clk);

		//set burst bit
		@(negedge tb_clk);
		tb_h_burst[0] = burst;
		@(posedge tb_clk);

		//assert select
		@(negedge tb_clk);
		tb_h_sel = 1;
		@(posedge tb_clk);

		@(negedge tb_clk);
		if (tb_mode != burst) begin
			$error("Error during slave select: mode was read incorrectly.");
		end
	end
	endtask

	task deselect; //master deselects the slave
	begin
		tb_process = DESELECT;
		@(negedge tb_clk);

		//initialize select signal
		tb_h_sel = 0;
		@(posedge tb_clk);
		@(posedge tb_clk);
	end
	endtask

	task write_nb;	
		input [31:0] addr;
	begin
		tb_process = WRITE_NB;
		@(negedge tb_clk);

		//initialize master and bus signals
		tb_h_addr = addr;
		tb_h_trans = 2;
		tb_h_write = 1;
		tb_h_burst[1] = 0;
		tb_h_ready = 1;
		tb_idle = 1;
		
		//clock in master & bus signals then check new state
		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_w_enable != 1) begin
			$error("Error during single write: slave did not properly assert write enable.");
		end
		if (tb_bank != tb_h_addr[24:23] || tb_row_addr != tb_h_addr[22:10] || tb_col_addr != tb_h_addr[9:0]) begin
			$error("Error during single write: address not mapped properly.");
		end
		
		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_bus!= 1) begin
			$error("Error during single write: slave did not properly assert write enable.");
		end
		tb_idle = 0;

		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_h_trans = 0;

		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_idle = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_refresh_com) begin
			if (tb_h_readyout != 0) begin
				$error("Error during single write: slave did not properly deassert readyout.");
			end
			tb_refresh_com = 0;

			@(posedge tb_clk);
			@(negedge tb_clk);
			if (tb_h_readyout != 1) begin
				$error("Error during single write: slave did not properly assert readyout.");
			end
		end else begin
			if (tb_h_readyout != 1) begin
				$error("Error during single write: slave did not properly assert readyout.");
			end
		end
		tb_h_trans = 0;
		tb_h_addr = 0;
		tb_h_ready = 0;
	end
	endtask

	task read_nb;
		input [31:0] addr;
	begin
		tb_process = READ_NB;
		@(negedge tb_clk);

		//initialize master and bus signals
		tb_h_addr = addr;
		tb_h_trans = 2;
		tb_h_write = 0;
		tb_h_burst[1] = 0;
		tb_h_ready = 1;
		tb_idle = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_r_enable != 1 || tb_burst != 0) begin
			$error("Error during single read: slave did not properly assert read enable and/or deassert burst.");
		end
		if (tb_bank != tb_h_addr[24:23] || tb_row_addr != tb_h_addr[22:10] || tb_col_addr != tb_h_addr[9:0]) begin
			$error("Error during single read: address not mapped properly.");
		end
		tb_chip = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_bus != 1) begin
			$error("Error during single read: slave did not properly assert bus signal.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 0) begin
			$error("Error during single read: slave did not properly deassert readyout signal.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 1) begin
			$error("Error during single read: slave did not properly assert readyout signal.");
		end
		tb_h_ready = 1;
		tb_h_trans = 0;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 0) begin
			$error("Error during single read: slave did not properly deassert readyout signal.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_refresh_com) begin
			if (tb_h_readyout != 0) begin
				$error("Error during single read: slave did not properly deassert readyout.");
			end
			tb_refresh_com = 0;

			@(posedge tb_clk);
			@(negedge tb_clk);
			if (tb_h_readyout != 1) begin
				$error("Error during single read: slave did not properly assert readyout.");
			end
		end else begin
			if (tb_h_readyout != 1) begin
				$error("Error during single read: slave did not properly assert readyout.");
			end
		end
		tb_h_trans = 0;
		tb_h_addr = 0;
		tb_h_ready = 0;
	end
	endtask

	task write_brst;
		input [31:0] addr;
	begin
		tb_process = WRITE_BRST;
		@(negedge tb_clk);

		//initialize master and bus signals
		tb_h_addr = addr;
		tb_h_trans = 2;
		tb_h_write = 1;
		tb_h_burst[1] = 1;
		tb_h_ready = 1;
		tb_idle = 1;
		
		//clock in master & bus signals then check new state
		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_w_enable != 1 || tb_burst != 1) begin
			$error("Error during burst write: slave did not properly assert write enable/burst.");
		end
		if (tb_bank != tb_h_addr[24:23] || tb_row_addr != tb_h_addr[22:10] || tb_col_addr != tb_h_addr[9:0]) begin
			$error("Error during burst write: address not mapped properly.");
		end
		tb_h_trans = 3;
		
		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_bus != 1) begin
			$error("Error during burst write: slave did not properly deassert bus signal.");
		end
		tb_idle = 0;
		tb_h_ready = 0;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_bus != 0) begin
			$error("Error during burst write: slave did not properly assert bus signal.");
		end
		tb_h_ready = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_bus != 1) begin
			$error("Error during burst write: slave did not properly assert bus signal.");
		end
		tb_idle = 1;
		tb_h_trans = 0;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 0) begin
			$error("Error during burst write: slave did not properly deassert ready signal.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_refresh_com) begin
			if (tb_h_readyout != 0) begin
				$error("Error during burst write: slave did not properly deassert readyout.");
			end
			tb_refresh_com = 0;

			@(posedge tb_clk);
			@(negedge tb_clk);
			if (tb_h_readyout != 1) begin
				$error("Error during burst write: slave did not properly assert readyout.");
			end
		end else begin
			if (tb_h_readyout != 1) begin
				$error("Error during burst write: slave did not properly assert readyout.");
			end
		end
		tb_h_trans = 0;
		tb_h_addr = 0;
		tb_h_ready = 0;
	end
	endtask

	task read_brst;
		input [31:0] addr;
	begin
		tb_process = READ_BRST;
		@(negedge tb_clk);

		//initialize master and bus signals
		tb_h_addr = addr;
		tb_h_trans = 2;
		tb_h_write = 0;
		tb_h_burst[1] = 1;
		tb_h_ready = 1;
		tb_idle = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_r_enable != 1 || tb_burst != 1) begin
			$error("Error during burst read: slave did not properly assert read enable and/or burst.");
		end
		if (tb_bank != tb_h_addr[24:23] || tb_row_addr != tb_h_addr[22:10] || tb_col_addr != tb_h_addr[9:0]) begin
			$error("Error during burst read: address not mapped properly.");
		end
		tb_chip = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_bus != 1) begin
			$error("Error during burst read: slave did not properly assert bus signal.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 0) begin
			$error("Error during burst read: slave did not properly deassert readyout signal.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 1) begin
			$error("Error during burst read: slave did not properly assert readyout signal.");
		end
		tb_h_trans = 3;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_bus != 1) begin
			$error("Error during burst read: slave did not properly assert bus signal.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 0) begin
			$error("Error during burst read: slave did not properly deassert readyout signal.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 1) begin
			$error("Error during burst read: slave did not properly assert readyout signal.");
		end
		tb_h_trans = 0;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 0) begin
			$error("Error during burst read: slave did not properly deassert readyout signal.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_refresh_com) begin
			if (tb_h_readyout != 0) begin
				$error("Error during burst read: slave did not properly deassert readyout.");
			end
			tb_refresh_com = 0;

			@(posedge tb_clk);
			@(negedge tb_clk);
			if (tb_h_readyout != 1) begin
				$error("Error during burst read: slave did not properly assert readyout.");
			end
		end else begin
			if (tb_h_readyout != 1) begin
				$error("Error during burst read: slave did not properly assert readyout.");
			end
		end
		tb_h_trans = 0;
		tb_h_addr = 0;
		tb_h_ready = 0;
	end
	endtask



	initial begin
		//Reset
		reset_dut();

		//Test Case 1: Slave Select - Non-burst
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: slave select in non-burst mode.", tb_test_case);
		tb_idle = 1;
		tb_chip = 0;
		tb_refresh_com = 0;
		tb_h_burst = 0;
		select(tb_h_burst[0]);
		if (tb_h_readyout != 1) begin
			$error("Test %1d failed: slave did not properly assert readyout.");
		end
		deselect;

		//Test Case 2: Single Write
		tb_h_burst[0] = 1;
		select(tb_h_burst[0]);
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: single write", tb_test_case);
		tb_h_addr = 32'h30;
		tb_h_wdata = 32'h1013200;
		write_nb (tb_h_addr);

		//Test Case 3: Single Read
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: single read", tb_test_case);
		tb_h_addr = 32'h10300;
		tb_b_rdata = 32'haa2f;
		read_nb (tb_h_addr);

		//Test Case 4: Burst Write
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: burst write", tb_test_case);
		tb_h_addr = 32'habcde;
		tb_b_rdata = 32'hfffffffe;
		write_brst (tb_h_addr);

		//test Case 5: Burst Read
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: burst read", tb_test_case);
		tb_h_addr = 32'habcde;
		tb_b_rdata = 32'haaaaaaea;
		read_brst (tb_h_addr);

		//Test Case 6: natural auto refresh
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: natural auto refresh", tb_test_case);
		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_idle = 0;
		tb_refresh_com = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 0) begin
			$error("Error during auto refresh: slave did not properly deassert readyout.");
		end
		tb_idle = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 0) begin
			$error("Error during auto refresh: slave did not properly deassert readyout.");
		end
		tb_refresh_com = 0;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 1) begin
			$error("Error during auto refresh: slave did not properly assert readyout.");
		end
		tb_h_ready = 0;

		//Test Case 7: Forced auto refresh
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: forced auto refresh", tb_test_case);
		
		@(negedge tb_clk);
		//initialize master and bus signals
		tb_h_addr = 32'd1000;
		tb_h_trans = 2;
		tb_h_write = 1;
		tb_h_burst[1] = 0;
		tb_h_ready = 1;
		tb_idle = 1;
		tb_refresh_com = 1;
		
		//clock in master & bus signals then check new state
		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 0) begin
			$error("Error during forced refresh: slave did not properly deassert readyout.");
		end
		
		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_idle = 0;
		tb_refresh_com = 0;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 0) begin
			$error("Error during forced refresh: slave did not properly deassert readyout.");
		end
		tb_idle = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 1) begin
			$error("Error during forced refresh: slave did not properly assert readyout.");
		end
		tb_h_trans = 0;
		tb_h_addr = 0;
		tb_h_ready = 0;
		tb_refresh_com = 0;
	end

endmodule 












/*
// $Id: $
// File name:   tb_bus_interface.sv
// Created:     4/17/2017
// Author:      Geoffrey Cramer
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Test bench for bus interface
`timescale 1ns / 100ps
module tb_bus_interface;

	localparam CLOCK_PERIOD = 7;
	localparam CHECK_DELAY = 2;
	integer tb_test_case = 0;

	typedef enum logic [2:0] {
		RESET,
		SELECT,
		WRITE_NB,
		WRITE_BRST,
		READ_NB,
		READ_BRST,
		DESELECT
	} ProcessType;
	ProcessType tb_process; //label for current task being run

	reg tb_clk, tb_n_rst;
	always
	begin: CLK_GEN
		tb_clk = 0;
		#(CLOCK_PERIOD/2.0);
		tb_clk = 1;
		#(CLOCK_PERIOD/2.0);
	end

	//DUT testbench variables
	reg tb_h_ready, tb_h_write, tb_h_sel, tb_idle, tb_chip, tb_refresh_com;
	reg [1:0] tb_h_trans;
	reg [2:0] tb_h_burst;
	reg [31:0] tb_h_addr, tb_h_wdata, tb_b_rdata;
	reg tb_h_readyout, tb_h_resp, tb_select, tb_burst, tb_r_enable, tb_w_enable, tb_bus;
	reg tb_mode;
	reg [1:0] tb_bank;
	reg [9:0] tb_col_addr;
	reg [12:0] tb_row_addr;
	reg [31:0] tb_h_rdata, tb_b_wdata;

	bus_interface DUT (
		.clk(tb_clk),
		.n_rst(tb_n_rst),
		.h_ready(tb_h_ready),
		.h_write(tb_h_write),
		.h_sel(tb_h_sel),
		.idle(tb_idle),
		.chip(tb_chip),
		.refresh_com(tb_refresh_com),
		.h_trans(tb_h_trans),
		.h_burst(tb_h_burst),
		.h_addr(tb_h_addr),
		.h_wdata(tb_h_wdata),
		.b_rdata(tb_b_rdata),
		.h_readyout(tb_h_readyout),
		.h_resp(tb_h_resp),
		.select(tb_select),
		.burst(tb_burst),
		.r_enable(tb_r_enable),
		.w_enable(tb_w_enable),
		.bus(tb_bus),
		.mode(tb_mode),
		.bank(tb_bank),
		.col_addr(tb_col_addr),
		.row_addr(tb_row_addr),
		.h_rdata(tb_h_rdata),
		.b_wdata(tb_b_wdata)
	);

	task reset_dut;
	begin
		tb_process = RESET;
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

	task select; //master selects the slave
		input burst;
	begin
		tb_process = SELECT;
		@(negedge tb_clk);

		//initialize select signal
		tb_h_ready = 1;
		tb_h_sel = 0;
		@(posedge tb_clk);
		@(posedge tb_clk);

		//set burst bit
		@(negedge tb_clk);
		tb_h_burst[0] = burst;
		@(posedge tb_clk);

		//assert select
		@(negedge tb_clk);
		tb_h_sel = 1;
		@(posedge tb_clk);

		@(negedge tb_clk);
		if (tb_mode != burst) begin
			$error("Error during slave select: mode was read incorrectly.");
		end
	end
	endtask

	task deselect; //master deselects the slave
	begin
		tb_process = DESELECT;
		@(negedge tb_clk);

		//initialize select signal
		tb_h_sel = 0;
		@(posedge tb_clk);
		@(posedge tb_clk);
	end
	endtask

	task write_nb;	
		input [31:0] addr;
	begin
		tb_process = WRITE_NB;
		@(negedge tb_clk);

		//initialize master and bus signals
		tb_h_addr = addr;
		tb_h_trans = 2;
		tb_h_write = 1;
		tb_h_burst[1] = 0;
		tb_h_ready = 1;
		tb_idle = 1;
		
		//clock in master & bus signals then check new state
		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_w_enable != 1) begin
			$error("Error during single write: slave did not properly assert write enable.");
		end
		if (tb_bank != tb_h_addr[24:23] || tb_row_addr != tb_h_addr[22:10] || tb_col_addr != tb_h_addr[9:0]) begin
			$error("Error during single write: address not mapped properly.");
		end
		
		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_bus!= 1) begin
			$error("Error during single write: slave did not properly assert write enable.");
		end
		tb_idle = 0;

		@(posedge tb_clk);
		@(negedge tb_clk);

		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_idle = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_refresh_com) begin
			if (tb_h_readyout != 0) begin
				$error("Error during single write: slave did not properly deassert readyout.");
			end
			tb_refresh_com = 0;

			@(posedge tb_clk);
			@(negedge tb_clk);
			if (tb_h_readyout != 1) begin
				$error("Error during single write: slave did not properly assert readyout.");
			end
		end else begin
			if (tb_h_readyout != 1) begin
				$error("Error during single write: slave did not properly assert readyout.");
			end
		end
		tb_h_trans = 0;
		tb_h_addr = 0;
		tb_h_ready = 0;
	end
	endtask

	task read_nb;
		input [31:0] addr;
	begin
		tb_process = READ_NB;
		@(negedge tb_clk);

		//initialize master and bus signals
		tb_h_addr = addr;
		tb_h_trans = 2;
		tb_h_write = 0;
		tb_h_burst[1] = 0;
		tb_h_ready = 1;
		tb_idle = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_r_enable != 1 || tb_burst != 0) begin
			$error("Error during single read: slave did not properly assert read enable and/or deassert burst.");
		end
		if (tb_bank != tb_h_addr[24:23] || tb_row_addr != tb_h_addr[22:10] || tb_col_addr != tb_h_addr[9:0]) begin
			$error("Error during single read: address not mapped properly.");
		end
		tb_chip = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_bus != 1) begin
			$error("Error during single read: slave did not properly assert bus signal.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 0) begin
			$error("Error during single read: slave did not properly deassert readyout signal.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 1) begin
			$error("Error during single read: slave did not properly assert readyout signal.");
		end
		tb_h_ready = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 0) begin
			$error("Error during single read: slave did not properly deassert readyout signal.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_refresh_com) begin
			if (tb_h_readyout != 0) begin
				$error("Error during single read: slave did not properly deassert readyout.");
			end
			tb_refresh_com = 0;

			@(posedge tb_clk);
			@(negedge tb_clk);
			if (tb_h_readyout != 1) begin
				$error("Error during single read: slave did not properly assert readyout.");
			end
		end else begin
			if (tb_h_readyout != 1) begin
				$error("Error during single read: slave did not properly assert readyout.");
			end
		end
		tb_h_trans = 0;
		tb_h_addr = 0;
		tb_h_ready = 0;
	end
	endtask

	task write_brst;
		input [31:0] addr;
	begin
		tb_process = WRITE_BRST;
		@(negedge tb_clk);

		//initialize master and bus signals
		tb_h_addr = addr;
		tb_h_trans = 2;
		tb_h_write = 1;
		tb_h_burst[1] = 1;
		tb_h_ready = 1;
		tb_idle = 1;
		
		//clock in master & bus signals then check new state
		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_w_enable != 1 || tb_burst != 1) begin
			$error("Error during burst write: slave did not properly assert write enable/burst.");
		end
		if (tb_bank != tb_h_addr[24:23] || tb_row_addr != tb_h_addr[22:10] || tb_col_addr != tb_h_addr[9:0]) begin
			$error("Error during burst write: address not mapped properly.");
		end
		tb_h_trans = 3;
		
		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_bus != 1) begin
			$error("Error during burst write: slave did not properly deassert bus signal.");
		end
		tb_idle = 0;
		tb_h_ready = 0;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_bus != 0) begin
			$error("Error during burst write: slave did not properly assert bus signal.");
		end
		tb_h_ready = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_bus != 1) begin
			$error("Error during burst write: slave did not properly assert bus signal.");
		end
		tb_idle = 1;
		tb_h_trans = 0;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 0) begin
			$error("Error during burst write: slave did not properly deassert ready signal.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_refresh_com) begin
			if (tb_h_readyout != 0) begin
				$error("Error during burst write: slave did not properly deassert readyout.");
			end
			tb_refresh_com = 0;

			@(posedge tb_clk);
			@(negedge tb_clk);
			if (tb_h_readyout != 1) begin
				$error("Error during burst write: slave did not properly assert readyout.");
			end
		end else begin
			if (tb_h_readyout != 1) begin
				$error("Error during burst write: slave did not properly assert readyout.");
			end
		end
		tb_h_trans = 0;
		tb_h_addr = 0;
		tb_h_ready = 0;
	end
	endtask

	task read_brst;
		input [31:0] addr;
	begin
		tb_process = READ_BRST;
		@(negedge tb_clk);

		//initialize master and bus signals
		tb_h_addr = addr;
		tb_h_trans = 2;
		tb_h_write = 0;
		tb_h_burst[1] = 1;
		tb_h_ready = 1;
		tb_idle = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_r_enable != 1 || tb_burst != 1) begin
			$error("Error during burst read: slave did not properly assert read enable and/or burst.");
		end
		if (tb_bank != tb_h_addr[24:23] || tb_row_addr != tb_h_addr[22:10] || tb_col_addr != tb_h_addr[9:0]) begin
			$error("Error during burst read: address not mapped properly.");
		end
		tb_chip = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_bus != 1) begin
			$error("Error during burst read: slave did not properly assert bus signal.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 0) begin
			$error("Error during burst read: slave did not properly deassert readyout signal.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 1) begin
			$error("Error during burst read: slave did not properly assert readyout signal.");
		end
		tb_h_trans = 3;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_bus != 1) begin
			$error("Error during burst read: slave did not properly assert bus signal.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 0) begin
			$error("Error during burst read: slave did not properly deassert readyout signal.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 1) begin
			$error("Error during burst read: slave did not properly assert readyout signal.");
		end
		tb_h_trans = 0;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 0) begin
			$error("Error during burst read: slave did not properly deassert readyout signal.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_refresh_com) begin
			if (tb_h_readyout != 0) begin
				$error("Error during burst read: slave did not properly deassert readyout.");
			end
			tb_refresh_com = 0;

			@(posedge tb_clk);
			@(negedge tb_clk);
			if (tb_h_readyout != 1) begin
				$error("Error during burst read: slave did not properly assert readyout.");
			end
		end else begin
			if (tb_h_readyout != 1) begin
				$error("Error during burst read: slave did not properly assert readyout.");
			end
		end
		tb_h_trans = 0;
		tb_h_addr = 0;
		tb_h_ready = 0;
	end
	endtask



	initial begin
		//Reset
		reset_dut();

		//Test Case 1: Slave Select - Non-burst
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: slave select in non-burst mode.", tb_test_case);
		tb_idle = 1;
		tb_chip = 0;
		tb_refresh_com = 0;
		tb_h_burst = 0;
		select(tb_h_burst[0]);
		if (tb_h_readyout != 1) begin
			$error("Test %1d failed: slave did not properly assert readyout.");
		end

		//Test Case 2: Single Write
		reset_dut();
		tb_h_burst[0] = 1;
		select(tb_h_burst[0]);
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: single write", tb_test_case);
		tb_h_addr = 32'h30;
		tb_h_wdata = 32'h1013200;
		write_nb (tb_h_addr);

		//Test Case 3: Single Read
		reset_dut();
		select(tb_h_burst[0]);
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: single read", tb_test_case);
		tb_h_addr = 32'h10300;
		tb_b_rdata = 32'haa2f;
		read_nb (tb_h_addr);

		//Test Case 4: Burst Write
		reset_dut();
		select(tb_h_burst[0]);
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: burst write", tb_test_case);
		tb_h_addr = 32'habcde;
		tb_b_rdata = 32'hfffffffe;
		write_brst (tb_h_addr);

		//test Case 5: Burst Read
		reset_dut();
		select(tb_h_burst[0]);
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: burst read", tb_test_case);
		tb_h_addr = 32'habcde;
		tb_b_rdata = 32'haaaaaaea;
		read_brst (tb_h_addr);

		//Test Case 6: natural auto refresh
		reset_dut();
		select(tb_h_burst[0]);
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: natural auto refresh", tb_test_case);
		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_idle = 0;
		tb_refresh_com = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 0) begin
			$error("Error during auto refresh: slave did not properly deassert readyout.");
		end
		tb_idle = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 0) begin
			$error("Error during auto refresh: slave did not properly deassert readyout.");
		end
		tb_refresh_com = 0;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 1) begin
			$error("Error during auto refresh: slave did not properly assert readyout.");
		end

		//Test Case 7: Forced auto refresh
		reset_dut();
		select(tb_h_burst[0]);
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: forced auto refresh", tb_test_case);
		
		@(negedge tb_clk);
		//initialize master and bus signals
		tb_h_addr = 32'd1000;
		tb_h_trans = 2;
		tb_h_write = 1;
		tb_h_burst[1] = 0;
		tb_h_ready = 1;
		tb_idle = 1;
		tb_refresh_com = 1;
		
		//clock in master & bus signals then check new state
		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 0) begin
			$error("Error during forced refresh: slave did not properly deassert readyout.");
		end
		
		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_idle = 0;
		tb_refresh_com = 0;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 0) begin
			$error("Error during forced refresh: slave did not properly deassert readyout.");
		end
		tb_idle = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 1) begin
			$error("Error during forced refresh: slave did not properly assert readyout.");
		end
		tb_h_trans = 0;
		tb_h_addr = 0;
		tb_h_ready = 0;
		tb_refresh_com = 0;

		//Test Case 8: Bad address
		reset_dut();
		select(tb_h_burst[0]);
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: bad address", tb_test_case);
		tb_h_addr = 32'hffffffff;
		tb_h_trans = 2;
		tb_h_write = 0;
		tb_h_burst[1] = 1;
		tb_h_ready = 1;
		tb_idle = 1;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_resp != 1) begin
			$error("Error during bad address: slave did not properly assert error response.");
		end

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_resp != 1 || tb_h_readyout != 1) begin
			$error("Error during bad address: slave did not properly assert error response and/or readyout.");
		end
		tb_h_addr = 0;

		@(posedge tb_clk);
		@(negedge tb_clk);
		if (tb_h_readyout != 1) begin
			$error("Error during bad address: slave did not properly assert readyout.");
		end

		//Test Case 9: Deselect
		reset_dut();
		select(tb_h_burst[0]);
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: slave deselect", tb_test_case);
		deselect();
	end

endmodule */