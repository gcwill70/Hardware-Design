// $Id: $
// File name:   scg_writeap_nb.sv
// Created:     4/24/2017
// Author:      Geoffrey Cramer
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Single write w/ auto-precharge command sequence FSM
module scg_writeap_nb(
	input wire start, clk, n_rst,
	output wire done, chip,
	output wire [3:0] command
);

	typedef enum logic [1:0] {
		IDLE,
		DATA,
		WAIT,
		DONE
	} StateType;
	StateType state_in, state_out;

	always_comb
	begin: NEXT_STATE_LOGIC
		state_in = state_out;
		case (state_out)
			IDLE: begin
				if (start) begin
					state_in = DATA;
				end
			end
			DATA: state_in = WAIT;
			WAIT: state_in = DONE;
			DONE: begin
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

	assign done = state_out == DONE;
	assign command =(state_out == DONE)? 3: 0;

	assign chip = state_out == DATA;

endmodule 