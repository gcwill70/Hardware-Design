// $Id: $
// File name:   scg_active.sv
// Created:     4/24/2017
// Author:      Geoffrey Cramer
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Active Command sequence FSM
module scg_active (
	input wire start, clk, n_rst,
	output wire done,
	output reg [3:0] command
);

	typedef enum logic [2:0] {
		IDLE,
		START,
		NOP,
		DONE
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
			START: state_in = NOP;
			NOP: state_in = DONE;
			DONE: state_in = IDLE;
		endcase
	end

	always_ff @(posedge clk, negedge n_rst) begin
		if (n_rst == 1'b0) begin
			state_out <= IDLE;
		end else begin
			state_out <= state_in;
		end
	end

	assign done = state_out == DONE;
	assign command =(state_out == START)? 1: 0;

endmodule 