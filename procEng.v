`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Uttej
// 
// Create Date: 01/30/2021 08:16:44 AM
// Design Name: 
// Module Name: procEng
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

module procEng(
    input clk,
    input rst,
    input [`data_width-1:0] memory_data,
    input mem_wr,
    input [`PE_BUFF_ADDRS_WIDTH-1:0] memory_addrs,
    input mem_sel,
    input start,
    output reg done,
    output [`data_width-1:0] data_out
    );
    
    reg flag;
    reg [`data_width-1:0] weight_buff_in, data_buff_in;
    reg [`PE_BUFF_ADDRS_WIDTH-1:0] weight_buff_addrs, data_buff_addrs;
    reg weight_buff_wr, data_buff_wr, weight_buff_rd, data_buff_rd;
    wire [`data_width-1:0] weight_buff_out, data_buff_out;
    reg [`data_width-1:0] weight_buff_out_internal, data_buff_out_internal;
    
    reg [1:0] state;
    localparam idle = 2'b00, mem_write = 2'b01, begin_ops = 2'b10, end_ops = 2'b11;
    
//    wire [2*`data_width-1:0] prod_val;
    reg [2*`data_width-1:0] prod_val;
    reg [2*`data_width:0] mac_val;
    
    reg [`data_width-1:0] data_out_internal;
    reg done_internal;
    
    bram_memory #(
        .dataWidth(`data_width),
        .addrW(`PE_BUFF_ADDRS_WIDTH),
        .memFile("")
    )PE_weight_buff(
        .clk(clk),
        .data_in(weight_buff_in),
        .addr(weight_buff_addrs),
        .wr(weight_buff_wr),
        .rd(weight_buff_rd),
        .data_out(weight_buff_out)
    );
    
    bram_memory #(
        .dataWidth(`data_width),
        .addrW(`PE_BUFF_ADDRS_WIDTH),
        .memFile("")
    )PE_data_buff(
        .clk(clk),
        .data_in(data_buff_in),
        .addr(data_buff_addrs),
        .wr(data_buff_wr),
        .rd(data_buff_rd),
        .data_out(data_buff_out)
    );
    
    assign data_out = data_out_internal;
    
//    assign prod_val = weight_buff_out * data_buff_out;
    
    always @(posedge clk) begin
        if(rst) begin
            data_out_internal <= 0;
            done <= 0;
        end
        else begin
            if(done_internal) begin
                data_out_internal <= mac_val[`data_width-1:0];
                done <= done_internal;
            end
            else begin
                done <= 0;
            end
        end
    end
    
    always @(posedge clk) begin
        if(rst) begin
            state <= idle;
            weight_buff_in <= 0;
            data_buff_in <= 0;
            weight_buff_addrs <= 0;
            data_buff_addrs <= 0;
            weight_buff_wr <= 0;
            data_buff_wr <= 0;
            weight_buff_rd <= 0;
            data_buff_rd <= 0;
            mac_val <= 0;
            flag <= 0;
            prod_val <= 0;
        end
        else begin
            case(state)
                idle: begin
                    weight_buff_wr <= 0;
                    data_buff_wr <= 0;
                    done_internal <= 1'b0;
                    mac_val <= 0;
                    if(mem_wr) begin
                        if(!mem_sel) begin
                            weight_buff_in <= memory_data;
                            weight_buff_addrs <= memory_addrs;
                            weight_buff_wr <= mem_wr;
                            state <= mem_write;
                        end
                        else begin
                            data_buff_in <= memory_data;
                            data_buff_addrs <= memory_addrs;
                            data_buff_wr <= mem_wr;
                            state <= mem_write;
                        end
                    end
                    else if(start) begin
                        data_buff_rd <= 1'b1;
                        weight_buff_rd <= 1'b1;
                        weight_buff_addrs <= 0;
                        data_buff_addrs <= 0;
                        state <= begin_ops;
                    end
                    else begin
                        state <= idle;
                        weight_buff_in <= 0;
                        data_buff_in <= 0;
                        weight_buff_addrs <= 0;
                        data_buff_addrs <= 0;
                        weight_buff_wr <= 0;
                        data_buff_wr <= 0;
                    end
                end
                
                mem_write: begin
                    if(!mem_wr) begin
                        state <= idle;
                        weight_buff_addrs <= weight_buff_addrs;
                        data_buff_addrs <= data_buff_addrs;
                        weight_buff_wr <= 0;
                        data_buff_wr <= 0;
                    end
                    else begin
                        state <= mem_write;
                        if(!mem_sel) begin
                            weight_buff_in <= memory_data;
                            weight_buff_addrs <= memory_addrs;
                            weight_buff_wr <= mem_wr;
                            state <= mem_write;
                        end
                        else begin
                            data_buff_in <= memory_data;
                            data_buff_addrs <= memory_addrs;
                            data_buff_wr <= mem_wr;
                            state <= mem_write;
                        end
                    end
                end
                
                begin_ops: begin
                    prod_val <= weight_buff_out * data_buff_out;
                    if(weight_buff_addrs < (`weightM * `weightN)-1) begin
                        weight_buff_addrs <= weight_buff_addrs + 1'b1;
                        data_buff_addrs <= data_buff_addrs + 1'b1;
                        if (!flag) begin
                            flag <= 1'b1;
                        end
                        else begin
                            mac_val <= mac_val + {1'b0, prod_val};
                        end
                        state <= begin_ops;
                    end
                    else begin
                        flag <= 1'b0;
                        mac_val <= mac_val + {1'b0, prod_val};
                        data_buff_rd <= 1'b0;
                        weight_buff_rd <= 1'b0;
                        weight_buff_addrs <= 0;
                        data_buff_addrs <= 0;
                        state <= end_ops;
                    end
                end
                
                end_ops: begin
                    prod_val <= 0;
                    mac_val <= mac_val + {1'b0, prod_val};
                    done_internal <= 1'b1;
                    state <= idle;
                end
                
                default: begin
                    state <= idle;
                end
            endcase
        end
    end
    
endmodule
