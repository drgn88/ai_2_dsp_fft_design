`timescale 1ns/1ps

module cnt_2b (
	input clk,
	input rstn,
	input valid,
	
	output logic [1:0] cnt_ctrl
);
	
	always_ff @( posedge clk or negedge rstn ) begin : make_ctrl_signal
		if(!rstn) begin
			cnt_ctrl <= 0;
		end
		else if(valid) begin
			cnt_ctrl <= cnt_ctrl + 1;
		end
	end

endmodule