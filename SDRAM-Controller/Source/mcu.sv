// $Id: $
// File name:   mcu1.sv
// Created:     4/26/2017
// Author:      Geoffrey Cramer
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Main Control Unit
/*
OPCODES
0 - ready
1 - initialize
2 - self-refresh
3 - auto-refresh
4 - single read
5 - burst read
6 - single write
7 - burst write
*/
module mcu (
	input wire r_enable, w_enable, select, burst, idle, clk, n_rst,
	output wire refresh_com,
	output reg [2:0] opcode
);
	typedef enum logic [3:0] {
		SELF_REF,
		READY,
		INIT,
		AUTO_REF1, AUTO_REF2,
		WRITE_BRST1, WRITE_BRST2,
		WRITE_NB1, WRITE_NB2,
		READ_BRST1, READ_BRST2,
		READ_NB1, READ_NB2
	} StateType;
	StateType state_in, state_out;

	wire refresh_req, count_enable;
	wire [10:0] count_out;

	always_comb
	begin: NEXT_STATE_LOGIC
		state_in = state_out;
		case (state_out)
			INIT: begin
				if (idle) begin
					state_in = READY;
				end
			end
			SELF_REF: begin
				if (select) begin
					state_in = READY;
				end
			end
			READY: begin
				if (!select && idle) begin
					state_in = SELF_REF;
				end else if (select && ((refresh_com) || (refresh_req&&!r_enable&&!w_enable))) begin
					state_in = AUTO_REF1;
				end else if (r_enable && !w_enable && !burst && !refresh_com && select) begin
					state_in = READ_NB1;
				end else if (r_enable && !w_enable && burst && !refresh_com && select) begin
					state_in = READ_BRST1;
				end else if (w_enable && !r_enable && !burst && !refresh_com && select) begin
					state_in = WRITE_NB1;
				end else if (w_enable && !r_enable && burst && !refresh_com && select) begin
					state_in = WRITE_BRST1;
				end
			end

			AUTO_REF1: begin
				if (!idle) begin
					state_in = AUTO_REF2;
				end
			end
			AUTO_REF2: begin
				if (idle) begin
					state_in = READY;
				end
			end

			WRITE_BRST1: begin
				if (!idle) begin
					state_in = WRITE_BRST2;
				end
			end
			WRITE_BRST2: begin
				if (idle) begin
					state_in = READY;
				end
			end

			WRITE_NB1: begin
				if (!idle) begin
					state_in = WRITE_NB2;
				end
			end
			WRITE_NB2: begin
				if (idle) begin
					state_in = READY;
				end
			end
			
			READ_BRST1: begin
				if (!idle) begin
					state_in = READ_BRST2;
				end
			end
			READ_BRST2: begin
				if (idle) begin
					state_in = READY;
				end
			end
		
			READ_NB1: begin
				if (!idle) begin
					state_in = READ_NB2;
				end
			end
			READ_NB2: begin
				if (idle) begin
					state_in = READY;
				end
			end
		endcase
	end

	always_ff @(posedge clk, negedge n_rst) begin
		if (n_rst == 1'b0) begin
			state_out <= INIT;
		end else begin
			state_out <= state_in;
		end
	end

	always_comb
	begin: OPCODE_LOGIC
		opcode = 3'd0;
		case(state_out)
			READY: opcode =		3'd0;
			INIT: opcode = 		3'd1;
			SELF_REF: opcode = 	3'd2;
			AUTO_REF1: opcode = 	3'd3;
			READ_NB1: opcode = 	3'd4;
			READ_BRST1: opcode = 	3'd5;
			WRITE_NB1: opcode = 	3'd6;
			WRITE_BRST1: opcode = 	3'd7;
		endcase
	end

	flex_counter #(.NUM_CNT_BITS(11))
	REF_COUNT(
		.clear(sync_rst),
		.count_enable(count_enable),
		.clk(clk),
		.n_rst(n_rst),
		.count_out(count_out)
	);

	assign count_enable = 1;

	assign sync_rst = (state_out == SELF_REF) || (state_out == AUTO_REF2) || (state_out == INIT);

	//COUNT LOGIC
	assign refresh_com = count_out[10];
	assign refresh_req = !count_out[10]&&count_out[9];

endmodule 