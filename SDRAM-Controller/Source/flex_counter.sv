// $Id: $
// File name:   flex_counter.sv
// Created:     1/28/2017
// Author:      Geoffrey Cramer
// Lab Section: 337-01
// Version:     1.0  Initial Design Entry
// Description: Flexible Counter w/ Rollover
module flex_counter
#(
	parameter NUM_CNT_BITS = 4
)
(
	input wire clk, n_rst, clear, count_enable,
	input wire [NUM_CNT_BITS-1:0]rollover_val,
	
	output wire [NUM_CNT_BITS-1:0]count_out,
	output wire rollover_flag
);
	reg [NUM_CNT_BITS-1:0]next_count_out; //register value for count_out to be assigned to count_out directly
	reg [NUM_CNT_BITS-1:0]current_count_out;
	reg next_rollover;
	reg current_rollover;

	always_ff @(posedge clk, negedge n_rst) begin
		if (n_rst == 1'b0) begin
			next_count_out <= 0;
			next_rollover <= 0;
		end else begin
			next_count_out <= current_count_out;
			next_rollover <= current_rollover;
		end
	end

	always_comb
	begin : NEXT_STATE_LOGIC
		if (clear) begin
			current_count_out = 0;
			current_rollover = 0;
		end else if (count_enable) begin
			current_rollover = (next_count_out + 1) == rollover_val;
			if (next_rollover) begin
				current_count_out = 1;
			end else begin
				current_count_out = next_count_out + 1;
			end
		end else begin
			current_rollover = next_rollover;
			current_count_out = next_count_out;
		end
	end

	assign rollover_flag = next_rollover;

	assign count_out = next_count_out;

endmodule