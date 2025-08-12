`timescale 1ns / 1ps

module top_bit_shift_cbfp1 #(
    parameter INPUT_WIDTH = 25,
    parameter OUTPUT_WIDTH = 12,
    parameter BLOCK_SIZE = 8,
    parameter SHIFT_WIDTH = 5,
    parameter SHIFT_TARGET =13
)(
    input logic clk,
    input logic rstn,

    input logic en,
    input logic [SHIFT_WIDTH-1:0] shift_value_add,
    input logic [SHIFT_WIDTH-1:0] shift_value_sub,

    input  logic signed [INPUT_WIDTH-1:0] input_data_R_add [BLOCK_SIZE-1:0],
    input  logic signed [INPUT_WIDTH-1:0] input_data_Q_add [BLOCK_SIZE-1:0],
    input  logic signed [INPUT_WIDTH-1:0] input_data_R_sub [BLOCK_SIZE-1:0],
    input  logic signed [INPUT_WIDTH-1:0] input_data_Q_sub [BLOCK_SIZE-1:0],

    output logic signed [OUTPUT_WIDTH-1:0] output_data_R_add [BLOCK_SIZE-1:0],
    output logic signed [OUTPUT_WIDTH-1:0] output_data_Q_add [BLOCK_SIZE-1:0],
    output logic signed [OUTPUT_WIDTH-1:0] output_data_R_sub [BLOCK_SIZE-1:0],
    output logic signed [OUTPUT_WIDTH-1:0] output_data_Q_sub [BLOCK_SIZE-1:0]
);

    genvar i;
    genvar j;

    generate
        for (i = 0; i < BLOCK_SIZE; i = i + 1) begin
            bit_shift_cbfp1 #(.INPUT_WIDTH(25),
                        .OUTPUT_WIDTH(12),
                        .SHIFT_WIDTH(5),
                        .SHIFT_TARGET(13)) U_BIT_SHIFT_R_add(
                .data_in(input_data_R_add[i]),
                .shift_value(shift_value_add),
                .data_out(output_data_R_add[i])
            );
        end

        for (i = 0; i < BLOCK_SIZE; i = i + 1) begin
            bit_shift_cbfp1 #(.INPUT_WIDTH(25),
                        .OUTPUT_WIDTH(12),
                        .SHIFT_WIDTH(5),
                        .SHIFT_TARGET(13)) U_BIT_SHIFT_Q_add(
                .data_in(input_data_Q_add[i]),
                .shift_value(shift_value_add),
                .data_out(output_data_Q_add[i])
            );
        end

        for (i = 0; i < BLOCK_SIZE; i = i + 1) begin
            bit_shift_cbfp1 #(.INPUT_WIDTH(25),
                        .OUTPUT_WIDTH(12),
                        .SHIFT_WIDTH(5),
                        .SHIFT_TARGET(13)) U_BIT_SHIFT_R_sub(
                .data_in(input_data_R_sub[i]),
                .shift_value(shift_value_sub),
                .data_out(output_data_R_sub[i])
            );
        end

        for (i = 0; i < BLOCK_SIZE; i = i + 1) begin
            bit_shift_cbfp1 #(.INPUT_WIDTH(25),
                        .OUTPUT_WIDTH(12),
                        .SHIFT_WIDTH(5),
                        .SHIFT_TARGET(13)) U_BIT_SHIFT_Q_sub(
                .data_in(input_data_Q_sub[i]),
                .shift_value(shift_value_sub),
                .data_out(output_data_Q_sub[i])
            );
        end
    endgenerate

endmodule
