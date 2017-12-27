// $Id: $
// File name:   scg_auto_ref.sv
// Created:     4/24/2017
// Author:      Geoffrey Cramer
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Auto Refresh command sequence FSM
module scg_auto_ref (
	input wire start, clk, n_rst,
	output wire done,
	output wire [3:0] command
);

	typedef enum logic [1:0] {
		IDLE,
		START,
		NOP1, NOP2
	} StateType;
	StateType state_in, state_out;

	wire cnt_start, cnt_done;

	always_comb
	begin: NEXT_STATE_LOGIC
		state_in = state_out;
		case (state_out)
			IDLE: begin
				if (start) begin
					state_in = START;
				end
			end
			START: state_in = NOP1;
			NOP1: begin
				if (cnt_done) begin
					state_in = NOP2;
				end
			end
			NOP2: state_in = IDLE;
		endcase
	end

	always_ff @(posedge clk, negedge n_rst) begin
		if (n_rst == 1'b0) begin
			state_out <= IDLE;
		end else begin
			state_out <= state_in;
		end
	end

	flex_counter #(.NUM_CNT_BITS(4))
	AUTO_REF_COUNT (
		.clear(done),
		.count_enable(cnt_start),
		.clk(clk),
		.n_rst(n_rst),
		.rollover_flag(cnt_done),
		.rollover_val(4'd7)
	);

	assign cnt_start = state_out == START || state_out == NOP1;
	assign done = state_out == NOP2;
	assign command = (state_out == START)? 5: 0;

endmodule 