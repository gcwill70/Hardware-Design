// $Id: $
// File name:   scg_writeap_brst.sv
// Created:     4/24/2017
// Author:      Geoffrey Cramer
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Burst write w/ auto-precharge command sequence FSM
module scg_writeap_brst(
	input wire start, clk, n_rst,
	output wire done, chip,
	output wire [3:0] command
);

	typedef enum logic [2:0] {
		IDLE,
		DATA1, DATA2, DATA3, DATA4,
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
					state_in = DATA1;
				end
			end
			DATA1: state_in = DATA2;
			DATA2: state_in = DATA3;
			DATA3: state_in = DATA4;
			DATA4: state_in = WAIT;
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
	assign command =(state_out == DATA3)? 3: 0;
	assign chip = 	(state_out == DATA1) || (state_out == DATA2) || (state_out == DATA3) || (state_out == DATA4);

endmodule 