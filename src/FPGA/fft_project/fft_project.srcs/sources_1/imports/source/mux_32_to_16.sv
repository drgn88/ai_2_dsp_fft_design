`timescale 1ns/1ps

module mux_32_to_16 #(
	parameter DATA_WIDTH = 10
) (
	input mux_sel,

	input signed [DATA_WIDTH-1:0] din_R_add00 [0:15],
	input signed [DATA_WIDTH-1:0] din_Q_add00 [0:15],
	input signed [DATA_WIDTH-1:0] din_R_sub00 [0:15],
	input signed [DATA_WIDTH-1:0] din_Q_sub00 [0:15],
	
	output logic signed [DATA_WIDTH-1:0] din_R_01 [0:15],
	output logic signed [DATA_WIDTH-1:0] din_Q_01 [0:15]
);
	
	always_comb begin : sel_reg_in
		case (mux_sel)
			1'b0 : begin
				din_R_01 = din_R_add00;
				din_Q_01 = din_Q_add00;
			end
			1'b1: begin
				din_R_01 = din_R_sub00;
				din_Q_01 = din_Q_sub00;
			end
		endcase
	end

endmodule