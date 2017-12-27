// $Id: $
// File name:   bus_interface.sv
// Created:     4/17/2017
// Author:      Geoffrey Cramer
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: AHB bus interface
module bus_interface (
	input wire clk, n_rst, h_ready, h_write, h_sel, idle, chip, refresh_com,
	input wire [1:0] h_trans,
	input wire [2:0] h_burst,
	input wire [24:0] h_addr,
	input wire [31:0] h_wdata, b_rdata,
	output reg h_readyout, h_resp, select, burst, r_enable, w_enable, bus,
	output reg mode,
	output reg [1:0] bank,
	output reg [9:0] col_addr,
	output reg [12:0] row_addr,
	output reg [31:0] h_rdata, b_wdata
);
	typedef enum logic [4:0] {
		RESET,
		SELF_REF1, SELF_REF2, SELF_REF3,
		FORCED_REF1, FORCED_REF2,
		LOCKED,
		READY,
		AUTO_REF,
		WRITE_NB1, WRITE_NB2, WRITE_NB3, WRITE_NB4,
		WRITE_BRST1, WRITE_BRST2, WRITE_BRST3, WRITE_BRST4,
		READ_NB1, READ_NB2, READ_NB3, READ_NB4, READ_NB5,
		READ_BRST1, READ_BRST2, READ_BRST3, READ_BRST4, READ_BRST5
	} StateType;

	StateType state_in, state_out;
	reg mode_in, h_sel_reg;
	reg [24:0] b_addr_in, b_addr;
	wire sel_rise, start;

	assign start = h_sel && h_ready && idle;

	always_comb
	begin: NEXT_STATE_LOGIC
		if (refresh_com && idle) begin
			state_in = FORCED_REF1;
		end else begin
			state_in = state_out;
			case (state_out)
				RESET: begin
					if (idle) begin
						state_in = READY;
					end
				end
				SELF_REF1: begin
					if (!idle) begin
						state_in = SELF_REF2;
					end
				end
				SELF_REF2: begin
					if (h_sel) begin
						state_in = SELF_REF3;
					end
				end
				SELF_REF3: begin
					if (idle) begin
						state_in = READY;
					end
				end
				FORCED_REF1: begin
					if (idle) begin
						state_in = FORCED_REF2;
					end
				end
				FORCED_REF2: begin
					if (h_ready) begin
						state_in = READY;
					end
				end

				READY: begin
					if (start && !h_write && !h_burst[1] && idle && h_trans == 2) begin
						state_in = READ_NB1;
					end else if (start && !h_write && h_burst[1] && idle && h_trans == 2) begin
						state_in = READ_BRST1;
					end else if (start && h_write && !h_burst[1] && idle && h_trans == 2) begin
						state_in = WRITE_NB1;
					end else if (start && h_write && h_burst[1] && idle && h_trans == 2) begin
						state_in = WRITE_BRST1;
					end else if (!h_sel && idle) begin
						state_in = SELF_REF1;	
					end else if (!idle && h_trans == 0) begin
						state_in = AUTO_REF;
					end
				end

				LOCKED: begin
					if (start && !h_write && !h_burst[1] && idle && h_trans == 2) begin
						state_in = READ_NB1;
					end else if (start && !h_write && h_burst[1] && idle && h_trans == 2) begin
						state_in = READ_BRST1;
					end else if (start && h_write && !h_burst[1] && idle && h_trans == 2) begin
						state_in = WRITE_NB1;
					end else if (start && h_write && h_burst[1] && idle && h_trans == 2) begin
						state_in = WRITE_BRST1;
					end else if (!h_sel && idle) begin
						state_in = SELF_REF1;
					end
				end
	
				READ_NB1: begin
					if (chip) begin
						state_in = READ_NB2;
					end
				end
				READ_NB2: state_in = READ_NB3;
				READ_NB3: state_in = READ_NB4;
				READ_NB4: begin
					if (h_ready && h_trans != 2) begin
						state_in = READ_NB5;
					end
				end
				READ_NB5: begin
					if (idle && h_trans == 0) begin
						state_in = READY;
					end else if (idle && h_trans != 0) begin
						state_in = LOCKED;
					end
				end
	
				READ_BRST1: begin
					if (chip) begin
						state_in = READ_BRST2;
					end
				end
				READ_BRST2: state_in = READ_BRST3;
				READ_BRST3: state_in = READ_BRST4;
				READ_BRST4: begin
					if (h_ready) begin
						if (h_trans == 3) begin
							state_in = READ_BRST2;
						end else begin
							state_in = READ_BRST5;
						end
					end
				end
				READ_BRST5: begin
					if (idle && h_trans == 0) begin
						state_in = READY;
					end else if (idle && h_trans != 0) begin
						state_in = LOCKED;
					end
				end
	
				AUTO_REF: begin
					if (idle) begin
						state_in = READY;
					end
				end
	
				WRITE_NB1: state_in = WRITE_NB2;
				WRITE_NB2: state_in = WRITE_NB3;
				WRITE_NB3: begin
					if (h_ready && h_trans != 2) begin
						state_in = WRITE_NB4;
					end
				end
				WRITE_NB4: begin
					if (idle && h_trans == 0) begin
						state_in = READY;
					end else if (idle && h_trans != 0) begin
						state_in = LOCKED;
					end
				end
	
				WRITE_BRST1: begin
					if (h_ready && h_trans == 3) begin
						state_in = WRITE_BRST2;
					end
				end
				WRITE_BRST2: begin
					if (h_ready && h_trans != 3) begin
						state_in = WRITE_BRST4;
					end else if (!h_ready) begin
						state_in = WRITE_BRST3;
					end
				end
				WRITE_BRST3: begin
					if (h_ready) begin
						if (h_trans == 3) begin
							state_in = WRITE_BRST2;
						end else begin
							state_in = WRITE_BRST4;
						end
					end
				end
				WRITE_BRST4: begin
					if (idle && h_trans == 0) begin
						state_in = READY;
					end else if (idle && h_trans != 0) begin
						state_in = LOCKED;
					end
				end
			endcase
		end
	end

	always_ff @(posedge clk, negedge n_rst) begin
		if (n_rst == 1'b0) begin
			state_out <= RESET;
		end else begin
			state_out <= state_in;
		end
	end

	always_comb
	begin: OUTPUT_LOGIC
		select = 1;
		w_enable = 0;
		r_enable = 0;
		h_readyout = 1;
		burst = 0;
		bus = 0;
		h_resp = 0;
		case (state_out)
			RESET: h_readyout = 0;
			SELF_REF1: begin
				select = 0;
				h_readyout = 0;
			end
			SELF_REF2: begin
				select = 0;
				h_readyout = 0;
			end
			SELF_REF3: h_readyout = 0;
			FORCED_REF1: begin
				h_readyout = 0;
				h_resp = 1;
			end
			FORCED_REF2: h_resp = 1;
			LOCKED: begin
				r_enable = 1;
				w_enable = 1;
			end
			AUTO_REF: h_readyout = 0;
			WRITE_NB1: w_enable = 1;
			WRITE_NB2: begin
				bus = 1;
				h_readyout = 0;
				w_enable = 1;
				r_enable = 1;
			end
			WRITE_NB3: begin
				w_enable = 1;
				r_enable = 1;
			end
			WRITE_NB4: begin
				h_readyout = 0;
				r_enable = 1;
				w_enable = 1;
			end
			WRITE_BRST1: begin
				w_enable = 1;
				burst = 1;
			end
			WRITE_BRST2: begin
				bus = 1;
				r_enable = 1;
				w_enable = 1;
			end
			WRITE_BRST3: begin
				r_enable = 1;
				w_enable = 1;
			end
			WRITE_BRST4: begin
				h_readyout = 0;
				r_enable = 1;
				w_enable = 1;
			end
			READ_NB1: begin
				r_enable = 1;
				h_readyout = 0;
			end
			READ_NB2: begin
				bus = 1;
				h_readyout = 0;
				r_enable = 1;
				w_enable = 1;
			end
			READ_NB3: begin
				h_readyout = 0;
				r_enable = 1;
				w_enable = 1;
			end
			READ_NB4: begin
				r_enable = 1;
				w_enable = 1;
			end
			READ_NB5: begin
				h_readyout = 0;
				r_enable = 1;
				w_enable = 1;
			end
			READ_BRST1: begin
				h_readyout = 0;
				r_enable = 1;
				burst = 1;
			end
			READ_BRST2: begin
				bus = 1;
				h_readyout = 0;
				r_enable = 1;
				w_enable = 1;
			end
			READ_BRST3: begin
				h_readyout = 0;
				r_enable = 1;
				w_enable = 1;
			end
			READ_BRST4: begin
				r_enable = 1;
				w_enable = 1;
			end
			READ_BRST5: begin
				h_readyout = 0;
				r_enable = 1;
				w_enable = 1;
			end
		endcase
	end

	//Write Data
	always_ff @(posedge clk, negedge n_rst)
	begin: WDATA_REGISTER
		if (n_rst == 1'b0) begin
			b_wdata <= '0;
		end else begin
			b_wdata <= h_wdata;
		end
	end

	//Read Data
	always_ff @(posedge clk, negedge n_rst)
	begin: RDATA_REGISTER
		if (n_rst == 1'b0) begin
			h_rdata <= '0;
		end else begin
			h_rdata <= b_rdata;
		end
	end

	//Memory Mapping
	always_comb
	begin: ADDR_NSLOGIC
		if (start) begin
			b_addr_in = h_addr[24:0];
		end else begin
			b_addr_in = b_addr;
		end
	end
	always_ff @(posedge clk, negedge n_rst)
	begin: ADDR_REGISTER
		if (n_rst == 1'b0) begin
			b_addr <= '0;
		end else begin
			b_addr <= b_addr_in;
		end
	end
	assign bank = b_addr[24:23];
	assign row_addr = b_addr[22:10];
	assign col_addr = b_addr[9:0];

	//Mode Logic
	always_ff @(posedge clk, negedge n_rst)
	begin: MODE_REGISTER
		if (n_rst == 1'b0) begin
			mode <= 0;
		end else begin
			mode <= mode_in;
		end
	end
	always_comb
	begin: MODE_NSLOGIC
		if (sel_rise) begin
			mode_in = h_burst[0];
		end else begin
			mode_in = mode;
		end
	end
	
	//h_sel snych. edge detector
	always_ff @(posedge clk, negedge n_rst) begin
		if (n_rst == 0) begin
			h_sel_reg <= 0;
		end else begin
			h_sel_reg <= h_sel;
		end
	end
	assign sel_rise = !h_sel_reg && h_sel;

endmodule 