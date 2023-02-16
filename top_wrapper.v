`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Uttej
// 
// Create Date: 01/25/2021 11:58:08 AM
// Design Name: 
// Module Name: top_wrapper
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

module top_wrapper(
    input clk,
    input reset,
    input [1:0] mem_sel,
    input go,
    input [`data_width-1:0] data_in,
    input [`COEF_ADDRS_WIDTH-1:0] addrs_in,
    input mem_wr,
    input mem_rd,
    output reg [`data_width-1:0] data_out,
//    `ifdef `GET_LATENCY
//        output[31:0] cntr_out,
//    `endif
    output done
    );
    
    reg [`data_width-1:0] coef_mem_data_in;
    reg [`COEF_ADDRS_WIDTH-1:0] coef_mem_addrs_in;
    reg coef_mem_wr;
    reg [`data_width-1:0] h_t_mem_in;
    reg [`HT_addrs_width-1:0] h_t_mem_addrs_in;
    reg h_t_mem_wr;
    
    wire [`data_width-1:0] x_t_mem_in;
    reg [`XT_addrs_width-1:0] x_t_mem_addrs_in;
    wire x_t_mem_wr;
    
    reg read_op;
    reg h_t_read;
    reg SM_WM_read;
//    wire done,
    wire [`data_width-1:0] out;
    wire [`data_width-1:0] h_t_out;
    wire [`data_width-1:0] SM_out;
    
    reg conv_mem_wr, conv_mem_sel;
    reg [`data_width-1:0] conv_mem_in;
    wire [`data_width-1:0] conv_op;
    wire conv_done, conv_op_wr;
    
    wire max_op_wr, max_done;
    wire [`data_width-1:0] max_out;
    
    localparam CFM = 2'b00, HTMem = 2'b01, SMWMem = 2'b10, CWM = 2'b11;
    
//    `ifdef `GET_LATENCY
//        integer latency_cntr = 0;
//        reg [1:0] state;
//        localparam idle = 2'b00, cnt = 2'b01, stop = 2'b10; 
//    `endif
    
    convolution_wrapper convolution_layer(
        .clk(clk),
        .rst(reset),
        .wr_en(conv_mem_wr),
        .mem_in(conv_mem_in),
        .mem_sel(conv_mem_sel),
        .start_conv(go),
        .done(conv_done),
        .o_mem_wr(conv_op_wr),
        .o_mem_in(conv_op)
    );
    
    max_pool maxpool_layer(
    .clk(clk),
    .rst(reset),
    .wr_en(conv_op_wr),
    .mem_in(conv_op),
    .start(conv_done),
    .done(max_done),
    .o_mem_wr(max_op_wr),
    .o_mem_data(max_out)
    );
    
    lstm_top_tmp top(
        .clk(clk),
        .rst(reset),
        .go(max_done),
        .coef_mem_data_in(coef_mem_data_in),
        .coef_mem_addrs_in(coef_mem_addrs_in),
        .coef_mem_wr(coef_mem_wr),
        .h_t_mem_in(h_t_mem_in),
        .h_t_mem_addrs_in(h_t_mem_addrs_in),
        .h_t_mem_wr(h_t_mem_wr),
        .x_t_mem_in(x_t_mem_in),
        .x_t_mem_addrs_in(x_t_mem_addrs_in),
        .x_t_mem_wr(x_t_mem_wr),
        .read_op(read_op),
        .h_t_read(h_t_read),
        .SM_WM_read(SM_WM_read),
        .done(done),
        .out(out),
        .h_t_out(h_t_out),
        .SM_out(SM_out)
    );
    
    assign x_t_mem_in = max_out;
    assign x_t_mem_wr = max_op_wr;
    
//    `ifdef `GET_LATENCY
//        always @(posedge clk) begin
//            if(reset) begin
//                state <= idle;
//                latency_cntr <= 0;
//            end
//            else begin
//                case(state)
//                    idle: begin
//                        latency_cntr <= 0;
//                        if(go) begin
//                            state <= cnt;
//                        end
//                        else begin
//                            state <= idle;
//                        end
//                    end
                    
//                    cnt: begin
//                        if(!done) begin
//                            latency_cntr <= latency_cntr + 1'b1;
//                            state <= cnt;
//                        end
//                        else begin
//                            state <= stop;
//                        end
//                    end
                    
//                    stop: begin
//                        state <= idle;
//                    end
                    
//                    default: begin
//                        state <= idle;
//                    end
//                endcase
//            end
//        end
        
//        assign cntr_out = latency_cntr;
//    `endif
    
    always @(posedge clk) begin
        if(reset) begin
            x_t_mem_addrs_in <= 0;
        end
        else begin
            if(max_op_wr || read_op) begin
                x_t_mem_addrs_in <= x_t_mem_addrs_in + 1'b1;
            end
        end
    end
    
    always @(*) begin
        case(mem_sel)
//            XTMem: begin
//                coef_mem_data_in = 0;
//                coef_mem_addrs_in = 0;
//                coef_mem_wr = 0;
//                SM_WM_read = 0;
                
//                h_t_mem_in = 0;
//                h_t_mem_addrs_in = 0;
//                h_t_mem_wr = 0;
//                h_t_read = 0;
                
//                x_t_mem_in = data_in;
//                x_t_mem_addrs_in = addrs_in;
//                x_t_mem_wr = mem_wr;
//                read_op = mem_rd;
                
//                data_out = out;
//            end
            
            CFM: begin
                coef_mem_data_in = 0;
                coef_mem_addrs_in = 0;
                coef_mem_wr = 0;
                SM_WM_read = 0;
                
                h_t_mem_in = 0;
                h_t_mem_addrs_in = 0;
                h_t_mem_wr = 0;
                h_t_read = 0;
                
                conv_mem_wr = mem_wr;
                conv_mem_in = data_in;
                conv_mem_sel = 1'b0;
                
                read_op = mem_rd;
                data_out = out;
            end
            
            CWM: begin
                coef_mem_data_in = 0;
                coef_mem_addrs_in = 0;
                coef_mem_wr = 0;
                SM_WM_read = 0;
                
                h_t_mem_in = 0;
                h_t_mem_addrs_in = 0;
                h_t_mem_wr = 0;
                h_t_read = 0;
                
                conv_mem_wr = mem_wr;
                conv_mem_in = data_in;
                conv_mem_sel = 1'b1;
                
                read_op = mem_rd;
                data_out = out;
            end
            
            HTMem: begin
                coef_mem_data_in = 0;
                coef_mem_addrs_in = 0;
                coef_mem_wr = 0;
                SM_WM_read = 0;
                
                h_t_mem_in = data_in;
                h_t_mem_addrs_in = addrs_in;
                h_t_mem_wr = mem_wr;
                h_t_read = mem_rd;
                
                conv_mem_wr = 0;
                conv_mem_in = 0;
                conv_mem_sel = 1'b0;
                
                read_op = 0;
                data_out = h_t_out;
            end
            
            SMWMem: begin
                coef_mem_data_in = data_in;
                coef_mem_addrs_in = addrs_in;
                coef_mem_wr = mem_wr;
                SM_WM_read = mem_rd;
                
                h_t_mem_in = 0;
                h_t_mem_addrs_in = 0;
                h_t_mem_wr = 0;
                h_t_read = 0;
                
                conv_mem_wr = 0;
                conv_mem_in = 0;
                conv_mem_sel = 1'b0;
                
                read_op = 0;
                data_out = SM_out;
            end
            
//            default: begin
//                coef_mem_data_in = 0;
//                coef_mem_addrs_in = 0;
//                coef_mem_wr = 0;
//                SM_WM_read = 0;
                
//                h_t_mem_in = 0;
//                h_t_mem_addrs_in = 0;
//                h_t_mem_wr = 0;
//                h_t_read = 0;
                
//                conv_mem_wr = mem_wr;
//                conv_mem_in = data_in;
//                conv_mem_sel = 1'b0;
                
//                read_op = mem_rd;
//                data_out = out;
//            end
        endcase
    end
    
endmodule
