// $Id: $
// File name:   scg_readap_nb.sv
// Created:     4/24/2017
// Author:      Geoffrey Cramer
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Single read w/ auto-precharge command sequence FSM
module scg_readap_nb(
	input wire start, clk, n_rst,
	output wire done, chip,
	output wire [3:0] command
);

	typedef enum logic [2:0] {
		IDLE,
		START,
		WAIT1, WAIT2, WAIT3,
		DATA
	} StateType;
	StateType state_in, state_out;

	always_comb
	begin: NEXT_STATE_LOGIC
		state_in = state_out;
		case (state_out)
			IDLE: begin
				if (start) begin
					state_in = START;
				end
			end
			START: state_in = WAIT1;
			WAIT1: state_in = WAIT2;
			WAIT2: state_in = WAIT3;
			WAIT3: state_in = DATA;
			DATA: begin
				if (!start) begin
					state_in = IDLE;
				end
			end
		endcase
	end

	always_ff @(posedge clk, negedge n_rst) begin
		if (n_rst == 1'b0) begin
			state_out <= IDLE;
		end else begin
			state_out <= state_in;
		end
	end

	assign done = state_out == DATA;
	assign command =(state_out == START)? 2: 0;
	assign chip = state_out == DATA;

endmodule 