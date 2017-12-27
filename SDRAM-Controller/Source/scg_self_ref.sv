// $Id: $
// File name:   scg_self_ref.sv
// Created:     4/24/2017
// Author:      Geoffrey Cramer
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Self-refresh command sequence FSM
module scg_self_ref (
	input wire start, clk, n_rst,
	output wire done,
	output wire [3:0] command
);

	typedef enum logic [2:0] {
		IDLE,
		START,
		ENTER1, ENTER2, ENTER3, ENTER4, ENTER5
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
			START: state_in = ENTER1;
			ENTER1: state_in = ENTER2;
			ENTER2: state_in = ENTER3;
			ENTER3: state_in = ENTER4;
			ENTER4: state_in = ENTER5;
			ENTER5: begin
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

	assign done = state_out == ENTER5;
	assign command = (state_out == IDLE)? 0: 6;

endmodule 