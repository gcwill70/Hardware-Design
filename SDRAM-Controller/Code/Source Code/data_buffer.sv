// $Id: $
// File name:   data_buffer.sv
// Created:     4/22/2017
// Author:      Geoffrey Cramer
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Data I/O Buffer
module data_buffer (
	input wire clk, n_rst, r_enable, w_enable, bus, chip,
	input wire [31:0] c_rdata, b_wdata,
	output wire full, empty,
	output wire [31:0] b_rdata, c_wdata
);

	typedef enum logic {
		READ,
		WRITE
	} StateType;
	StateType state_in, state_out;

	wire rw, r_full, r_empty, w_full, w_empty; //write = 1, read = 0
	reg r_in, r_out, w_in, w_out;

	always_ff @(posedge clk, negedge n_rst) begin
		if (n_rst == 0) begin
			state_out <= READ;
		end else begin
			state_out <= state_in;
		end
	end

	always_comb
	begin: DATAFLOW_FSM_NS_LOGIC
		state_in = state_out;
		case (state_out)
			READ: begin
				if (!r_enable && w_enable) begin
					state_in = WRITE;
				end
			end
			WRITE: begin
				if (r_enable && !w_enable) begin
					state_in = READ;
				end
			end
		endcase
	end

	assign rw = (state_out == WRITE);

	always_comb
	begin: CONTROL_LOGIC
		r_in = 0;
		r_out = 0;
		w_in = 0;
		w_out = 0;
		if (rw) begin
			w_in = bus;
			w_out = chip;
		end else begin
			r_in = chip;
			r_out = bus;
		end
	end

	fifo_word READ_FIFO (
		.clk(clk),
		.n_rst(n_rst),
		.read_enable(r_out),
		.write_enable(r_in),
		.wdata(c_rdata),
		.full(r_full),
		.empty(r_empty),
		.rdata(b_rdata)
	);

	fifo_word WRITE_FIFO (
		.clk(clk),
		.n_rst(n_rst),
		.read_enable(w_out),
		.write_enable(w_in),
		.wdata(b_wdata),
		.full(w_full),
		.empty(w_empty),
		.rdata(c_wdata)
	);

	assign full = r_full || w_full;
	assign empty = r_empty || w_empty;

endmodule 