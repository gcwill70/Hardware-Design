// $Id: $
// File name:   tb_sdram_controller.sv
// Created:     4/23/2017
// Author:      Geoffrey Cramer
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Test bench for SDRAM controller
`timescale 1ns / 100ps
module tb_sdram_controller ;

	localparam CLOCK_PERIOD = 7;
	localparam CHECK_DELAY = 2;
	integer tb_test_case = 0;
	integer timeout = 0; //timeout variable used in testing
	integer data_num = 0; //will keep track of amount of words sent during a burst (useful if data has to be simultaneously input and output)
	integer ref_counter = 0; //keeps track of refresh time

	typedef enum logic [2:0] {
		RESET,
		SELECT,
		WRITE_NB,
		WRITE_BRST,
		READ_NB,
		READ_BRST,
		DESELECT
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
	reg tb_h_sel, tb_h_ready, tb_h_write;
	reg [1:0] tb_h_trans;
	reg [2:0] tb_h_burst;
	reg [31:0] tb_h_wdata;
	reg [24:0] tb_h_addr;
	reg tb_h_readyout, tb_h_resp;
	reg [31:0] tb_h_rdata;
	reg [31:0] tb_dq_out;
	reg tb_cke, tb_cs_n, tb_we_n, tb_ras_n, tb_cas_n, tb_dqmh, tb_dqml;
	reg [1:0] tb_ba;
	reg [12:0] tb_addr;
	reg [31:0] tb_dq_in;

	sdram_controller DUT (
		.n_rst(tb_n_rst),
		.clk(tb_clk),
		.h_sel(tb_h_sel),
		.h_ready(tb_h_ready),
		.h_write(tb_h_write),
		.h_trans(tb_h_trans),
		.h_burst(tb_h_burst),
		.h_addr(tb_h_addr),
		.h_wdata(tb_h_wdata),
		.h_readyout(tb_h_readyout),
		.h_resp(tb_h_resp),
		.h_rdata(tb_h_rdata),
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
		.dq_in(tb_dq_in)
	);

	task reset_dut;
	begin
		@(negedge tb_clk);
		tb_process = RESET;
		//Initialize inputs
		tb_h_sel = 0;
		tb_h_ready = 0;
		tb_h_write = 0;
		tb_h_trans = 0;
		tb_h_burst = 0;
		tb_h_addr = 0;
		tb_h_wdata = 0;
		tb_dq_out = 0;
		tb_n_rst = 1;
		
		@(posedge tb_clk);
		@(posedge tb_clk);
		tb_n_rst = 0;
		
		// Release the reset
		@(negedge tb_clk);
		tb_n_rst = 1;
		
		@(negedge tb_clk);
		//wait for design to be ready
		wait(tb_h_readyout == 1);
	end
	endtask

	task select; //master selects the slave
	begin
		tb_process = SELECT;
		@(negedge tb_clk);
		tb_h_sel = 1;
		
		//wait for design to be ready
		wait(tb_h_readyout == 1);
	end
	endtask

	task deselect;
	begin
		tb_process = DESELECT;
		@(negedge tb_clk);
		tb_h_sel = 0;
		//wait for design to enter self-refresh
		wait(tb_h_readyout == 0);
	end
	endtask

	task read_nb;
		input [31:0] data;
	begin
		@(negedge tb_clk);
		tb_process = READ_NB;

		//initialize master and bus signals
		tb_h_trans = 2;
		tb_h_write = 0;
		tb_h_burst[1] = 0;
		tb_h_ready = 1;

		//wait for process to start
		while (DUT.mcu.opcode != 4) begin
			@(negedge tb_clk);
			timeout++;
			if (timeout > 100) begin
				$error("Error: design took too long. Stopping.");
				$stop;
			end
		end
		timeout = 0;
		$info("Info: correct opcode found for single read.");

		//active
		while (DUT.scg.command != 1) begin
			@(negedge tb_clk);
			timeout++;
			if (timeout > 100) begin
				$error("Error: design took too long. Stopping.");
				$stop;
			end
		end
		timeout = 0;
		$info("Info: active command found for single read.");

		//read_ap
		while (DUT.scg.command != 2) begin
			@(posedge tb_clk);
			timeout++;
			if (timeout > 100) begin
				$error("Error: design took too long. Stopping.");
				$stop;
			end
		end
		timeout = 0;
		$info("Info: read w/ auto-precharge command found for single read.");
		
		//CAS Latency
		@(posedge tb_clk);
		@(posedge tb_clk);
		@(negedge tb_clk);
		#(CHECK_DELAY);
		tb_dq_out = data;
		@(negedge tb_clk);
		tb_dq_out = 0;

		wait(tb_h_readyout == 1); //wait for design to be ready
		@(negedge tb_clk);
		if (tb_h_rdata != data) begin
			$error("Error during single read: data not retrieved properly. Stopping...");
			$stop;
		end
		@(negedge tb_clk);
		tb_h_trans = 0;
		tb_h_addr = 0;
		@(negedge tb_clk);
		tb_h_ready = 0;
		wait(tb_h_readyout == 1); //wait for design to finish
	end
	endtask

	task read_brst;
		input [31:0] data1, data2, data3, data4;
	begin
		tb_process = READ_BRST;
		@(negedge tb_clk);

		//initialize master and bus signals
		tb_h_trans = 2;
		tb_h_write = 0;
		tb_h_burst[1] = 1;
		tb_h_ready = 1;
		tb_dq_out = 0;
		data_num = 0;

		while (DUT.mcu.opcode != 5) begin
			@(negedge tb_clk);
			timeout++;
			if (timeout > 100) begin
				$error("Error: design took too long. Stopping.");
				$stop;
			end
		end
		timeout = 0;
		$info("Info: correct opcode found for burst read.");

		//active
		while (DUT.scg.command != 1) begin
			@(negedge tb_clk);
			timeout++;
			if (timeout > 100) begin
				$error("Error: design took too long. Stopping.");
				$stop;
			end
		end
		timeout = 0;
		$info("Info: active command found for burst read.");

		//read_ap
		while (DUT.scg.command != 2) begin
			@(posedge tb_clk);
			timeout++;
			if (timeout > 100) begin
				$error("Error: design took too long. Stopping.");
				$stop;
			end
		end
		timeout = 0;
		$info("Info: read w/ auto-precharge command found for burst read.");

		fork
		DATA_IN: begin
			//CAS Latency
			@(posedge tb_clk);
			@(negedge tb_clk);
			tb_h_trans = 3;
			@(posedge tb_clk);
			@(negedge tb_clk);
			#(CHECK_DELAY);
			tb_dq_out = data1;
			@(negedge tb_clk);
			#(CHECK_DELAY);
			tb_dq_out = data2;
			@(negedge tb_clk);
			if (tb_h_readyout) begin
				data_num = data_num + 1;
			end
			#(CHECK_DELAY);
			tb_dq_out = data3;
			@(negedge tb_clk);
			if (tb_h_readyout) begin
				data_num = data_num + 1;
			end
			#(CHECK_DELAY);
			tb_dq_out = data4;
			@(negedge tb_clk);
			tb_dq_out = 0;
		end

		DATA_OUT: begin
			while (data_num < 4) begin
				if (tb_h_readyout) begin
					case (data_num)
						0: begin
							if (tb_h_rdata != data1) begin
								$error("Error during burst read: data not retrieved properly. Stopping.");
								$stop;
							end
						end
						1: begin
							if (tb_h_rdata != data2) begin
								$error("Error during burst read: data not retrieved properly. Stopping.");
								$stop;
							end
						end
						2: begin
							if (tb_h_rdata != data3) begin
								$error("Error during burst read: data not retrieved properly. Stopping.");
								$stop;
							end
						end
						3: begin
							if (tb_h_rdata != data4) begin
								$error("Error during burst read: data not retrieved properly. Stopping.");
								$stop;
							end
							tb_h_trans = 0;
						end
					endcase
					data_num = data_num + 1;
				end
				@(negedge tb_clk);
			end
		end
		join



/*

		//CAS Latency
		@(posedge tb_clk);
		@(negedge tb_clk);
		tb_h_trans = 3;
		@(posedge tb_clk);
		@(negedge tb_clk);
		#(CHECK_DELAY);
		tb_dq_out = data1;
		@(negedge tb_clk);
		//This section is tricky because data could potentially be sent out to the SoC bus while data is still begin sent in.
		//So after each word is sent, it is necessary to check if data was sent out as well as the number of words that have been sent out.

		if (tb_h_readyout) begin //check if data is being sent
			//only need to check the first word because only 1 cycle has passed since input has started.
			if (tb_h_rdata != data1) begin
				$error("Error during burst read: data not retrieved properly. Stopping.");
				$stop;
			end
			data_num = data_num + 1; //one more word of data was outputted
		end
		#(CHECK_DELAY);
		tb_dq_out = data2;
		@(negedge tb_clk);
		if (tb_h_readyout) begin //check if data is being sent
			if (data_num == 1) begin //check if first word has been sent yet
				if (tb_h_rdata != data2) begin //if the first word has already been sent, then the data on the bus should be the second word
					$error("Error during burst read: data not retrieved properly. Stopping.");
					$stop;
				end
			end else begin //in this case, data on the bus should be the first word
				if (tb_h_rdata != data1) begin
					$error("Error during burst read: data not retrieved properly. Stopping.");
					$stop;
				end
			end
			data_num = data_num + 1; //one more word of data was outputted
		end
		#(CHECK_DELAY);
		tb_dq_out = data3;
		@(negedge tb_clk);
		if (tb_h_readyout) begin //check if data is being sent
			if (data_num == 2) begin //check if second word has been sent yet
				if (tb_h_rdata != data3) begin
					$error("Error during burst read: data not retrieved properly. Stopping.");
					$stop;
				end
			end else if (data_num == 1) begin  //check if first word has been sent yet
				if (tb_h_rdata != data2) begin
					$error("Error during burst read: data not retrieved properly. Stopping.");
					$stop;
				end
			end else begin //in this case, data on the bus should be the first word
				if (tb_h_rdata != data1) begin
					$error("Error during burst read: data not retrieved properly. Stopping.");
					$stop;
				end
			end
			data_num = data_num + 1; //one more word of data was outputted
		end
		#(CHECK_DELAY);
		tb_dq_out = data4;
		@(negedge tb_clk);
		tb_dq_out = 0;

		//All data has been sent from the chip so we are now free to focus on checking output data
		while (data_num < 4) begin
			if (tb_h_readyout) begin
				case (data_num)
					0: begin
						if (tb_h_rdata != data1) begin
							$error("Error during burst read: data not retrieved properly. Stopping.");
							$stop;
						end
					end
					1: begin
						if (tb_h_rdata != data2) begin
							$error("Error during burst read: data not retrieved properly. Stopping.");
							$stop;
						end
					end
					2: begin
						if (tb_h_rdata != data3) begin
							$error("Error during burst read: data not retrieved properly. Stopping.");
							$stop;
						end
					end
					3: begin
						if (tb_h_rdata != data4) begin
							$error("Error during burst read: data not retrieved properly. Stopping.");
							$stop;
						end
						tb_h_trans = 0;
					end
				endcase
				data_num = data_num + 1;
			end
			@(negedge tb_clk);
		end*/
		tb_h_addr = 0;

		@(negedge tb_clk);
		tb_h_ready = 0;
		wait(tb_h_readyout == 1); //wait for design to finish
	end
	endtask

	task write_nb;
	begin
		tb_process = WRITE_NB;
		@(negedge tb_clk);

		//initialize master and bus signals
		tb_h_trans = 2;
		tb_h_write = 1;
		tb_h_burst[1] = 0;
		tb_h_ready = 1;

		//wait for process to start
		while (DUT.mcu.opcode != 6) begin
			@(negedge tb_clk);
			timeout++;
			if (timeout > 100) begin
				$error("Error: design took too long. Stopping.");
				$stop;
			end
		end
		timeout = 0;
		$info("Info: correct opcode found for single write.");

		//active
		while (DUT.scg.command != 1) begin
			@(negedge tb_clk);
			timeout++;
			if (timeout > 100) begin
				$error("Error: design took too long. Stopping.");
				$stop;
			end
		end
		timeout = 0;
		$info("Info: active command found for single write.");

		//write_ap
		while (DUT.scg.command != 3) begin
			@(negedge tb_clk);
			timeout++;
			if (timeout > 100) begin
				$error("Error: design took too long. Stopping.");
				$stop;
			end
		end
		timeout = 0;
		$info("Info: write w/ auto-precharge command found for single write.");
		if (tb_dq_in != tb_h_wdata) begin
			$error("Error during single write: data not stored properly. Stopping...");
			$stop;
		end

		wait(tb_h_readyout == 1); //wait for design to be ready
		@(negedge tb_clk);
		tb_h_trans = 0;
		tb_h_addr = 0;
		@(negedge tb_clk);
		tb_h_ready = 0;
		wait(tb_h_readyout == 1); //wait for design to finish
	end
	endtask

	task write_brst;
		input [31:0] data1, data2, data3, data4;
	begin
		tb_process = WRITE_BRST;
		@(negedge tb_clk);

		//initialize master and bus signals
		tb_h_trans = 2;
		tb_h_write = 1;
		tb_h_burst[1] = 1;
		tb_h_ready = 1;
		tb_h_wdata = 0;

		//wait for process to start
		//@(posedge DUT.bus_interface.w_enable);
		@(negedge tb_clk);

		@(negedge tb_clk);
		tb_h_trans = 3;
		tb_h_wdata = data1;
		@(negedge tb_clk);
		tb_h_wdata = data2;
		@(negedge tb_clk);
		tb_h_wdata = data3;
		@(negedge tb_clk);
		tb_h_wdata = data4;
		@(negedge tb_clk);
		tb_h_trans = 0;
		tb_h_wdata = 0;
		@(negedge tb_clk);
		tb_h_ready = 0;
		tb_h_addr = 0;

		//write_ap
		while (DUT.scg.command != 3) begin
			@(negedge tb_clk);
			timeout++;
			if (timeout > 100) begin
				$error("Error: design took too long. Stopping.");
				$stop;
			end
		end
		timeout = 0;
		$info("Info: write w/ auto-precharge command found for burst write.");
		if (tb_dq_in != data1) begin
			$error("Error during burst write: data not stored properly. Stopping...");
			$stop;
		end

		@(negedge tb_clk);
		if (tb_dq_in != data2) begin
			$error("Error during burst write: data not stored properly. Stopping...");
			$stop;
		end

		@(negedge tb_clk);
		if (tb_dq_in != data3) begin
			$error("Error during burst write: data not stored properly. Stopping...");
			$stop;
		end

		@(negedge tb_clk);
		if (tb_dq_in != data4) begin
			$error("Error during burst write: data not stored properly. Stopping...");
			$stop;
		end

		wait(tb_h_readyout == 1); //wait for design to be ready
	end
	endtask

	task locked; //master will keep generating requests until error signal is obeserved
	begin
		ref_counter = 0;
		fork
		RUN: begin
			while (ref_counter != 100) begin
				read_brst_locked(32'hfaabeb00, 32'h9, 32'h7, 32'h1123ffab);
				ref_counter = ref_counter + 1;
				if (ref_counter == 50) begin
					$error("Error: design took too long. Stopping.");
					$stop;
				end
			end
		end
		WAIT: begin
			wait(tb_h_resp == 1);
		end
		join_any
		disable fork;
		wait(tb_h_readyout == 1);
		@(negedge tb_clk);
		tb_h_ready = 1;
		wait(tb_h_readyout == 1);
		$info("Found error response during continuous transfer.");
	end
	endtask

	task read_brst_locked; //same as read_brst task but h_trans will go to BUSY afterwards instead of IDLE
		input [31:0] data1, data2, data3, data4;
	begin
		tb_process = READ_BRST;
		@(negedge tb_clk);

		//initialize master and bus signals
		tb_h_trans = 2;
		tb_h_write = 0;
		tb_h_burst[1] = 1;
		tb_h_ready = 1;
		tb_dq_out = 0;
		data_num = 0;

		while (DUT.mcu.opcode != 5) begin
			@(negedge tb_clk);
			timeout++;
			if (timeout > 100) begin
				$error("Error: design took too long. Stopping.");
				$stop;
			end
		end
		timeout = 0;

		//active
		while (DUT.scg.command != 1) begin
			@(negedge tb_clk);
			timeout++;
			if (timeout > 100) begin
				$error("Error: design took too long. Stopping.");
				$stop;
			end
		end
		timeout = 0;

		//read_ap
		while (DUT.scg.command != 2) begin
			@(posedge tb_clk);
			timeout++;
			if (timeout > 100) begin
				$error("Error: design took too long. Stopping.");
				$stop;
			end
		end
		timeout = 0;
		
		fork
		DATA_IN: begin
			//CAS Latency
			@(posedge tb_clk);
			@(negedge tb_clk);
			tb_h_trans = 3;
			@(posedge tb_clk);
			@(negedge tb_clk);
			#(CHECK_DELAY);
			tb_dq_out = data1;
			@(negedge tb_clk);
			#(CHECK_DELAY);
			tb_dq_out = data2;
			@(negedge tb_clk);
			if (tb_h_readyout) begin
				data_num = data_num + 1;
			end
			#(CHECK_DELAY);
			tb_dq_out = data3;
			@(negedge tb_clk);
			if (tb_h_readyout) begin
				data_num = data_num + 1;
			end
			#(CHECK_DELAY);
			tb_dq_out = data4;
			@(negedge tb_clk);
			tb_dq_out = 0;
		end
		DATA_OUT: begin
			while (data_num < 4) begin
				if (tb_h_readyout) begin
					if (data_num == 3) begin
						tb_h_trans = 1;
					end
					data_num = data_num + 1;
				end
				@(negedge tb_clk);
			end
		end
		join
		tb_h_addr = 0;

		@(negedge tb_clk);
		tb_h_ready = 0;
		wait(tb_h_readyout == 1); //wait for design to finish
	end
	endtask

	initial begin
		reset_dut;

		//Test Case 1: Single Write
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: single write", tb_test_case);

		///Part 1: Non-burst mode
		$info("Part 1: non-burst mode");
		tb_h_burst[0] = 0;
		select;
		//Data 1
		$info("Data 1");
		tb_h_addr = 25'h1011101;
		tb_h_wdata = 32'hffecab;
		write_nb;
		//Data 2
		$info("Data 2");
		tb_h_addr = 25'hffedd00;
		tb_h_wdata = 32'h1101f8;
		write_nb;
		
		deselect;

		//Part 2: Burst mode
		$info("Part 2: burst mode");
		tb_h_burst[0] = 1;
		select;
		//Data 1
		$info("Data 1");
		tb_h_addr = 25'h1000002;
		tb_h_wdata = 32'hff234ee;
		write_nb;
		//Data 2
		$info("Data 2");
		tb_h_addr = 25'hfefdd01;
		tb_h_wdata = 32'h1f;
		write_nb;


		//Test Case 2: Single Read
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: single read", tb_test_case);
		reset_dut;

		///Part 1: Non-burst mode
		$info("Part 1: non-burst mode");
		tb_h_burst[0] = 0;
		select;
		//Data 1
		$info("Data 1");
		tb_h_addr = 25'h2;
		read_nb(32'hffff);
		//Data 2
		$info("Data 2");
		tb_h_addr = 25'haaabc;
		read_nb(32'h1);

		deselect;

		//Part 2: Burst mode
		$info("Part 2: burst mode");
		tb_h_burst[0] = 1;
		select;
		//Data 1
		$info("Data 1");
		tb_h_addr = 25'h10101;
		read_nb(32'hdef);
		//Data 2
		$info("Data 2");
		tb_h_addr = 25'hfab;
		read_nb(32'hba1);


		//Test Case 3: Burst Write
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: burst write", tb_test_case);
		reset_dut;

		///Part 1: Non-burst mode
		$info("Part 1: non-burst mode");
		tb_h_burst[0] = 0;
		select;
		//Data 1
		$info("Data 1");
		tb_h_addr = 25'h101;
		write_brst(32'h10101111, 32'hffe, 32'hfed, 32'habab);
		//Data 2
		$info("Data 2");
		tb_h_addr = 25'h0;
		write_brst(32'haafff, 32'hafa00, 32'hdeaff, 32'h10000);

		deselect;

		//Part 2: Burst mode
		$info("Part 2: burst mode");
		tb_h_burst[0] = 1;
		select;
		//Data 1
		$info("Data 1");
		tb_h_addr = 25'hfffffff;
		write_brst(32'haa0, 32'h101, 32'hfadaf, 32'heeee);
		//Data 2
		$info("Data 2");
		tb_h_addr = 25'hfaed456;
		write_brst(32'hfafafff, 32'h56437, 32'h63347890, 32'h12345678);


		//Test Case 4: Burst Read
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: burst read", tb_test_case);
		reset_dut;

		///Part 1: Non-burst mode
		$info("Part 1: non-burst mode");
		tb_h_burst[0] = 0;
		select;
		//Data 1
		$info("Data 1");
		tb_h_addr = 25'h11111ff;
		read_brst(32'h9958547, 32'hf10ffa74, 32'hffff0000, 32'hfabbe0);
		//Data 2
		$info("Data 2");
		tb_h_addr = 25'hbabe;
		read_brst(32'hfaaaafe6, 32'h00898763, 32'h95943431, 32'haf949467);

		deselect;

		//Part 2: Burst mode
		$info("Part 2: burst mode");
		tb_h_burst[0] = 1;
		select;
		//Data 1
		$info("Data 1");
		tb_h_addr = 25'h54321;
		read_brst(32'haafef659, 32'hfeeffa46, 32'h4, 32'hffae88);
		//Data 2
		$info("Data 2");
		tb_h_addr = 25'hf5566a;
		read_brst(32'hfaabeb00, 32'h9, 32'h7, 32'h1123ffab);

		deselect;

		//Test Case 5: Natural Auto-refresh
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: natural auto-refresh", tb_test_case);
		reset_dut;
		tb_h_burst[0] = 0;
		select;

		//Test Case 6: Forced Auto-refresh
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: forced auto-refresh", tb_test_case);
		reset_dut;
		tb_h_burst[0] = 0;
		select;
		tb_h_addr = 25'hfaed456;
		locked; //master will keep generating requests until error signal is obeserved

		//Test Case 7: Self-refresh
		tb_test_case = tb_test_case + 1;
		$info("Test Case %1d: self-refresh", tb_test_case);
		reset_dut;
		deselect;
	end

endmodule