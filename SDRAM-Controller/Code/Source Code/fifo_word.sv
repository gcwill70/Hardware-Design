// $Id: $
// File name:   fifo_word.sv
// Created:     4/22/2017
// Author:      Geoffrey Cramer
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: 32-bit fifo
module fifo_word (
	input wire clk, n_rst, read_enable, write_enable,
	input wire [31:0] wdata,
	output wire full, empty,
	output reg [31:0] rdata
);
	reg [1:0] write_ptr, read_ptr;

	reg [31:0] wdata1;
	reg [31:0] wdata2;
	reg [31:0] wdata3;
	reg [31:0] wdata4;

	reg [31:0] rdata1;
	reg [31:0] rdata2;
	reg [31:0] rdata3;
	reg [31:0] rdata4;
	reg [31:0] rdata_in;
	reg [31:0] wdata_out;


	typedef enum logic [2:0] {
		DATA0,
		DATA1,
		DATA2,
		DATA3,
		DATA4
	} StateType;
	StateType write_state_in, write_state_out, read_state_in, read_state_out, fe_state_in, fe_state_out;

	always_comb
	begin: FULL_EMPTY_FSM_LOGIC
		fe_state_in = fe_state_out;
		case (fe_state_out)
			DATA0: begin
				if (write_enable && !read_enable) begin
					fe_state_in = DATA1;
				end
			end
			DATA1: begin
				if (write_enable && !read_enable) begin
					fe_state_in = DATA2;
				end else if (read_enable && !write_enable) begin
					fe_state_in = DATA0;
				end
			end
			DATA2: begin
				if (write_enable && !read_enable) begin
					fe_state_in = DATA3;
				end else if (read_enable && !write_enable) begin
					fe_state_in = DATA1;
				end
			end
			DATA3: begin
				if (write_enable && !read_enable) begin
					fe_state_in = DATA4;
				end else if (read_enable && !write_enable) begin
					fe_state_in = DATA2;
				end
			end
			DATA4: begin
				if (read_enable && !write_enable) begin
					fe_state_in = DATA3;
				end
			end
		endcase
	end

	//Full Empty Output Logic
	assign empty = fe_state_out == DATA0;
	assign full = fe_state_out == DATA4;

	always_comb
	begin: WRITE_FSM_LOGIC
		write_state_in = write_state_out;
		write_ptr = 0;
		case (write_state_out)
			DATA0: begin
				write_ptr = 0;
				if (write_enable) begin
					write_state_in = DATA1;
				end
			end
			DATA1: begin
				write_ptr = 1;
				if (write_enable) begin
					write_state_in = DATA2;
				end
			end
			DATA2: begin
				write_ptr = 2;
				if (write_enable) begin
					write_state_in = DATA3;
				end
			end
			DATA3: begin
				write_ptr = 3;
				if (write_enable) begin
					write_state_in = DATA0;
				end
			end
		endcase
	end

	always_comb
	begin: READ_FSM_LOGIC
		read_state_in = read_state_out;
		read_ptr = 0;
		case (read_state_out)
			DATA0: begin
				read_ptr = 0;
				if (read_enable) begin
					read_state_in = DATA1;
				end
			end
			DATA1: begin
				read_ptr = 1;
				if (read_enable) begin
					read_state_in = DATA2;
				end
			end
			DATA2: begin
				read_ptr = 2;
				if (read_enable) begin
					read_state_in = DATA3;
				end
			end
			DATA3: begin
				read_ptr = 3;
				if (read_enable) begin
					read_state_in = DATA0;
				end
			end
		endcase
	end

	always_ff @(posedge clk, negedge n_rst)
	begin: FSM_STATE_REGISTERS
			if (n_rst == 0) begin
				fe_state_out <= DATA0;
				read_state_out <= DATA0;
				write_state_out <= DATA0;
			end else begin
				fe_state_out <= fe_state_in;
				read_state_out <= read_state_in;
				write_state_out <= write_state_in;
			end
	end

	always_comb
	begin: WRITE_NS_LOGIC
		wdata1 = rdata1;
		wdata2 = rdata2;
		wdata3 = rdata3;
		wdata4 = rdata4;
		if (write_enable) begin
			case (write_ptr)
				0: wdata1 = wdata;
				1: wdata2 = wdata;
				2: wdata3 = wdata;
				3: wdata4 = wdata;
			endcase
		end
	end

	always_ff @(posedge clk, negedge n_rst)
	begin: DATA_REGISTERS
		if (n_rst == 0) begin
			rdata <= 0;
			rdata1 <= 0;
			rdata2 <= 0;
			rdata3 <= 0;
			rdata4 <= 0;
		end else begin
			rdata <= rdata_in;
			rdata1 <= wdata1;
			rdata2 <= wdata2;
			rdata3 <= wdata3;
			rdata4 <= wdata4;
		end
	end

	always_comb
	begin: READ_NS_LOGIC
		rdata_in = rdata;
		if (read_enable) begin
			case (read_ptr)
				0: rdata_in = rdata1;
				1: rdata_in = rdata2;
				2: rdata_in = rdata3;
				3: rdata_in = rdata4;
			endcase
		end
	end

endmodule 