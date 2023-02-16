`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Uttej
// 
// Create Date: 02/02/2021 12:17:12 PM
// Design Name: 
// Module Name: convolution_wrapper
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "parameters.vh"

module convolution_wrapper(
    input clk,
    input rst,
    input mem_sel,
    input wr_en,
    input [`data_width-1:0] mem_in,
    input start_conv,
    output o_mem_wr,
    output [`data_width-1:0] o_mem_in,
    output reg done
    );
    
    reg [2:0] state;
    localparam idle = 3'b000, fmw = 3'b001, wmw = 3'b010, conv_running = 3'b011, conv_wmw = 3'b100, stop = 3'b101;
    reg flag;
    
    integer num_weights;
    
    reg [`data_width-1:0] weight_mem_in;
    reg [`WIGHT_ADDRS_WIDTH-1:0] weight_addrs, weight_addrs_delayed;
    reg weight_mem_wr, weight_mem_rd;
    wire [`data_width-1:0] weight_mem_out;
    
    reg conv_mem_wr, start_conv_internal, conv_mem_sel;
    reg [`data_width-1:0] conv_mem_in;
    reg [`CONV_FEATURE_ADDRS_WIDTH-1:0] conv_memory_addrs, conv_memory_addrs_delayed;
    wire conv_done;
    
    bram_memory#(
            .dataWidth(`data_width),
            .addrW(`WIGHT_ADDRS_WIDTH),
            .memFile("Conv_Weights_map.mem")
            )weight_mem(
            .clk(clk),
            .data_in(weight_mem_in),
            .addr(weight_addrs),
            .wr(weight_mem_wr),
            .rd(weight_mem_rd),
            .data_out(weight_mem_out)
    );
    
    conv_top conv_layer(
    .clk(clk),
    .rst(rst),
    .i_mem_wr(conv_mem_wr),
    .i_mem_data(conv_mem_in),
    .i_memory_addrs(conv_memory_addrs),
    .mem_sel(conv_mem_sel),
    .start_conv(start_conv_internal),
    .done(conv_done),
    .o_mem_wr(o_mem_wr),
    .o_mem_data(o_mem_in)
    );
    
    always @(posedge clk) begin
        if(rst) begin
            state <= idle;
            weight_mem_in <= 0;
            weight_addrs <= 0;
            weight_mem_wr <= 0;
            weight_mem_rd <= 0;
            conv_mem_wr <= 0;
            start_conv_internal <= 0;
            conv_mem_in <= 0;
            conv_memory_addrs <= 0;
            conv_memory_addrs_delayed <= 0;
            conv_mem_sel <= 0;
            flag <= 0;
            num_weights <= 0;
            done <= 0;
            weight_addrs_delayed <= 0;
        end
        else begin
            case(state)
                idle: begin
                    if(wr_en) begin
                        if(mem_sel) begin
                            state <= wmw;
                            weight_addrs <= 0;
                            weight_mem_in <= mem_in;
                            weight_mem_wr <= wr_en;
                            weight_mem_rd <= 0;
                        end
                        else begin
                            state <= fmw;
                            conv_mem_wr <= 1'b1;
                            conv_mem_sel <= 1'b0;
                            flag <= 1'b0;
                        end
                    end
                    else if(start_conv) begin
                        flag <= 0;
                        start_conv_internal <= 1'b1;
                        num_weights <= num_weights + 1'b1;
                        state <= conv_running;
                    end
                    else begin
                        state <= idle;
                        weight_mem_in <= 0;
                        weight_addrs <= 0;
                        weight_mem_wr <= 0;
                        weight_mem_rd <= 0;
                        conv_mem_wr <= 0;
                        start_conv_internal <= 0;
                        conv_mem_in <= 0;
                        conv_memory_addrs <= 0;
                        conv_mem_sel <= 0;
                        flag <= 0;
                        num_weights <= 0;
                        done <= 0;
                    end
                end
                
                wmw: begin
                    if(!wr_en) begin
                        state <= idle;
                        weight_mem_wr <= 0;
                        weight_addrs <= 0;
                    end
                    else begin
                        weight_mem_in <= mem_in;
                        weight_addrs <= weight_addrs + 1'b1;
                        weight_mem_wr <= wr_en;
                        weight_mem_rd <= 0;
                     end
                end
                
                fmw: begin
                    if(!wr_en) begin
                        state <= idle;
                        conv_mem_wr <= 0;
                        conv_memory_addrs <= 0;
                    end
                    else begin
                        if(!flag) begin
                            conv_memory_addrs <= 0;
                            flag <= 1'b1;
                        end
                        else begin
                            conv_memory_addrs <= conv_memory_addrs + 1'b1;
                        end
                        conv_mem_wr <= 1'b1;
                        start_conv_internal <= 1'b0;
                        conv_mem_in <= mem_in;
                        conv_mem_sel <= 1'b0;
                        state <= fmw;
                    end
                end
                
                conv_running: begin
                    start_conv_internal <= 1'b0;
                    if(!conv_done) begin
                        state <= conv_running;
                    end
                    else begin
                        if(num_weights <= `NUM_WEIGHT_LAYERS) begin
                            weight_mem_rd <= 1'b1;
                            weight_addrs <= weight_addrs;
                            weight_addrs_delayed <= weight_addrs;
                            conv_mem_wr <= 1'b1;
                            conv_mem_sel <= 1'b1;
                            conv_memory_addrs <= 0;
                            conv_memory_addrs_delayed <= 0;
                            num_weights <= num_weights + 1'b1;
                            state <= conv_wmw;
                        end
                        else begin
                            done <= 1'b1;
                            state <= stop;
                        end
                    end
                end
                
                conv_wmw: begin
                    if(conv_memory_addrs < (`weightM * `weightN)-1) begin
                        if(!flag) begin
                            conv_memory_addrs <= 0;
                            conv_memory_addrs_delayed <= 0;
                            flag <= 1'b1;
                        end
                        else begin
                            conv_memory_addrs_delayed <= conv_memory_addrs_delayed + 1'b1;
                            conv_memory_addrs <= conv_memory_addrs_delayed;
                        end
                        conv_mem_wr <= conv_mem_wr;
                        conv_mem_sel <= conv_mem_sel;
                        if((weight_addrs - weight_addrs_delayed) < `weightM * `weightN) begin
                            weight_mem_rd <= weight_mem_rd;
                            weight_addrs <= weight_addrs + 1'b1;
                        end
                        else begin
                            weight_mem_rd <= 0;
                            weight_addrs <= weight_addrs;
                        end
                        conv_mem_in <= weight_mem_out;
                        state <= conv_wmw;
                    end
                    else begin
                        if(flag) begin
                            flag <= 1'b0;
                            state <= conv_wmw;
                            conv_mem_wr <= 1'b0;
                        end
                        else begin
                            weight_mem_rd <= 1'b0;
                            conv_memory_addrs <= 0;
                            conv_memory_addrs_delayed <= 0; 
                            start_conv_internal <= 1'b1;
                            weight_addrs <= weight_addrs;
                            conv_mem_wr <= 1'b0;
                            conv_mem_sel <= 1'b0;
                            state <= conv_running;
                        end
                    end
                    
                end
                
                stop: begin
                    done <= 1'b0;
                    state <= idle;
                end
                
                default: begin
                    state <= idle;
                end
            endcase
        end
    end
    
endmodule
