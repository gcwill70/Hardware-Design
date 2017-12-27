// $Id: $
// File name:   scg_opcode_brst.sv
// Created:     4/24/2017
// Author:      Geoffrey Cramer
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Burst mode opcode FSM
module scg_opcode_brst (
	input wire done, cnt_done, clk, n_rst,
	input reg [2:0] opcode,
	output wire start, idle,
	output reg [3:0] select
);

	typedef enum logic [4:0] {
		READY,
		INIT1, INIT2, INIT3, INIT4, INIT5,
		SELF_REF1, SELF_REF2, SELF_REF3,
		SELF_REF_EXIT,
		AUTO_REF,
		READ_NB1, READ_NB2, READ_NB3, READ_NB4,
		READ_BRST1, READ_BRST2,
		WRITE_NB1, WRITE_NB2, WRITE_NB3, WRITE_NB4,
		WRITE_BRST1, WRITE_BRST2
	} StateType;
	StateType state_in, state_out;

	always_comb
	begin: NEXTSTATE_LOGIC
		state_in = state_out;
		case (state_out)
			READY: begin
				if (opcode == 3'd2) begin
					state_in = SELF_REF1;
				end else if (opcode == 3'd3) begin
					state_in = AUTO_REF;
				end else if (opcode == 3'd4) begin
					state_in = READ_NB1;
				end else if (opcode == 3'd5) begin
					state_in = READ_BRST1;
				end else if (opcode == 3'd6) begin
					state_in = WRITE_NB1;
				end else if (opcode == 3'd7) begin
					state_in = WRITE_BRST1;
				end
			end
			INIT1: begin
				if (cnt_done) begin
					state_in = INIT2;
				end
			end
			INIT2: begin
				if (done) begin
					state_in = INIT3;
				end
			end
			INIT3: begin
				if (done) begin
					state_in = INIT4;
				end
			end
			INIT4: begin
				if (done) begin
					state_in = INIT5;
				end
			end
			INIT5: begin
				if (done) begin
					state_in = READY;
				end
			end
			SELF_REF1: begin
				if (done) begin
					state_in = SELF_REF2;
				end
			end
			SELF_REF2: begin
				if (done) begin
					state_in = SELF_REF3;
				end
			end
			SELF_REF3: begin
				if (opcode == 3'd0) begin
					state_in = SELF_REF_EXIT;
				end
			end
			SELF_REF_EXIT: begin
				if (done) begin
					state_in = READY;
				end
			end
			AUTO_REF: begin
				if (done) begin
					state_in = READY;
				end
			end
			READ_NB1: begin
				if (done) begin
					state_in = READ_NB2;
				end
			end
			READ_NB2: begin
				if (done) begin
					state_in = READ_NB3;
				end
			end
			READ_NB3: begin
				if (done) begin
					state_in = READ_NB4;
				end
			end
			READ_NB4: begin
				if (done) begin
					state_in = READY;
				end
			end
			READ_BRST1: begin
				if (done) begin
					state_in = READ_BRST2;
				end
			end
			READ_BRST2: begin
				if (done) begin
					state_in = READY;
				end
			end
			WRITE_NB1: begin
				if (done) begin
					state_in = WRITE_NB2;
				end
			end
			WRITE_NB2: begin
				if (done) begin
					state_in = WRITE_NB3;
				end
			end
			WRITE_NB3: begin
				if (done) begin
					state_in = WRITE_NB4;
				end
			end
			WRITE_NB4: begin
				if (done) begin
					state_in = READY;
				end
			end
			WRITE_BRST1: begin
				if (done) begin
					state_in = WRITE_BRST2;
				end
			end
			WRITE_BRST2: begin
				if (done) begin
					state_in = READY;
				end
			end
		endcase
	end

	always_ff @(posedge clk, negedge n_rst) begin
		if (n_rst == 1'b0) begin
			state_out <= INIT1;
		end else begin
			state_out <= state_in;
		end
	end

	always_comb
	begin: SELECT_LOGIC
		select = 4'd0;
		case (state_out)
			INIT2: select = 4'd9;
			INIT3: select = 4'd6;
			INIT4: select = 4'd6;
			INIT5: select = 4'd11;
			SELF_REF1: select = 4'd9;
			SELF_REF2: select = 4'd7;
			SELF_REF_EXIT: select = 4'd8;
			AUTO_REF: select = 4'd6;
			READ_NB1: select = 4'd10;
			READ_NB2: select = 4'd1;
			READ_NB3: select = 4'd2;
			READ_NB4: select = 4'd11;
			READ_BRST1: select = 4'd1;
			READ_BRST2: select = 4'd3;
			WRITE_NB1: select = 4'd10;
			WRITE_NB2: select = 4'd1;
			WRITE_NB3: select = 4'd4;
			WRITE_NB4: select = 4'd11;
			WRITE_BRST1: select = 4'd1;
			WRITE_BRST2: select = 4'd5;
		endcase
	end

	assign idle = state_out == READY;
	assign start = state_out == INIT1;

endmodule 