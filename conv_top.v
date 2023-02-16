`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Uttej
// 
// Create Date: 01/30/2021 11:49:14 AM
// Design Name: 
// Module Name: conv_top
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

module conv_top(
    input clk,
    input rst,
    input i_mem_wr,
    input [`data_width-1:0] i_mem_data,
    input [`CONV_FEATURE_ADDRS_WIDTH-1:0] i_memory_addrs,
    input mem_sel,
    input start_conv,
    output reg done,
    output o_mem_wr,
    output [`data_width-1:0] o_mem_data
    );
    
    reg flag_f1, flag_f2;
    reg [2:0] state;
    localparam idle = 3'b000, feature_write = 3'b001, weights_write = 3'b010, s1 = 3'b011, s2 = 3'b100, op_wait = 3'b101, op_write = 3'b110, stop = 3'b111;
    
    reg [(`NUM_PE * `data_width)-1:0] PE_mem_in;
    reg [`NUM_PE-1:0] PE_mem_wr, PE_mem_sel, PE_start, PE_start_internal;
    reg [(`NUM_PE * `PE_BUFF_ADDRS_WIDTH)-1:0] PE_mem_addrs;
    reg [`PE_BUFF_ADDRS_WIDTH-1:0] PE_mem_addrs_c1;
    wire [`NUM_PE-1:0] PE_done;
    wire round_done;
    wire [(`NUM_PE * `data_width)-1:0] PE_out;
    
    reg [`data_width-1:0] feature_mem_in;
    wire [`CONV_FEATURE_ADDRS_WIDTH-1:0] feature_mem_addrs;
    reg [`CONV_FEATURE_ADDRS_WIDTH-1:0] feature_mem_addrs_internal;
    reg feature_mem_wr, feature_mem_rd;
    wire [`data_width-1:0] feature_mem_out;
    
    reg o_mem_wr_internal;
    reg [(`NUM_PE * `data_width)-1:0] o_mem_data_internal;
    
//    integer i_hori_cntr = 0, i_verti_cntr = 0, e_hori_cntr = 0, e_verti_cntr = 0, pe_counter = 0, j=0;
    reg [3:0] i_hori_cntr = 0;
    reg [8-1:0] e_hori_cntr = 0;
    reg [1:0] i_verti_cntr = 0;
    reg [7-1:0] e_verti_cntr = 0;
    reg [4:0] pe_counter = 0, j = 0;
    
    
    bram_memory #(
        .dataWidth(`data_width),
        .addrW(`CONV_FEATURE_ADDRS_WIDTH),
        .memFile("Conv_feature_map.mem")
    )feature_mem(
        .clk(clk),
        .data_in(feature_mem_in),
        .addr(feature_mem_addrs),
        .wr(feature_mem_wr),
        .rd(feature_mem_rd),
        .data_out(feature_mem_out)
    );
    
//    assign feature_mem_addrs = (feature_mem_wr) ? feature_mem_addrs_internal : (((e_verti_cntr + i_verti_cntr)*`featureM) + e_hori_cntr + i_hori_cntr);
    assign feature_mem_addrs = (feature_mem_wr) ? feature_mem_addrs_internal : addrs_compute(e_verti_cntr, i_verti_cntr, e_hori_cntr, i_hori_cntr);    
    assign round_done = PE_done[pe_counter];
    
    assign o_mem_wr = o_mem_wr_internal;
    assign o_mem_data = o_mem_data_internal[`data_width-1:0];
    
    genvar i;
    generate 
        for(i=0; i<=(`NUM_PE)-1; i=i+1) begin
            procEng PE (
                .clk(clk),
                .rst(rst),
                .memory_data(PE_mem_in[((`data_width*(i+1))-1) :(`data_width * i)]),
                .mem_wr(PE_mem_wr[((i+1)-1):(i)]),
                .memory_addrs(PE_mem_addrs[((`PE_BUFF_ADDRS_WIDTH*(i+1))-1) :(`PE_BUFF_ADDRS_WIDTH * i)]),
                .mem_sel(PE_mem_sel[((i+1)-1):(i)]),
                .start(PE_start_internal[((i+1)-1):(i)]),
                .done(PE_done[((i+1)-1):(i)]),
                .data_out(PE_out[((`data_width*(i+1))-1) :(`data_width * i)])
            );
        end
    endgenerate
    
    always @(posedge clk) begin
        if(rst) begin
            PE_start_internal <= 0;
        end
        else begin
            PE_start_internal <= PE_start;
        end
    end
    
    always @(posedge clk) begin
        if(rst) begin
            state <= idle;
            feature_mem_in <= 0;
            feature_mem_wr <= 0;
            feature_mem_rd <= 0;
            feature_mem_addrs_internal <= 0;
            PE_mem_in <= 0;
            PE_mem_wr <= 0;
            PE_mem_addrs <= 0;
            PE_mem_sel <= 0;
            PE_start <= 0;
            i_hori_cntr <= 0;
            i_verti_cntr <= 0;
            e_hori_cntr <= 0;
            e_verti_cntr <= 0;
            PE_mem_addrs_c1 <= 0;
            done <= 1'b0;
            flag_f1 <= 0;
            pe_counter <= 0;
            flag_f2 <= 0;
            o_mem_data_internal <= 0;
            o_mem_wr_internal <= 0;
        end
        else begin
            case(state)
                idle: begin
                    done <= 1'b0;
                    if(i_mem_wr) begin
                        if(mem_sel) begin
                            state <= weights_write;
                            PE_mem_in <= {`NUM_PE{i_mem_data}};
                            PE_mem_wr <= {`NUM_PE{i_mem_wr}};
                            PE_mem_addrs <= {`NUM_PE{i_memory_addrs[`PE_BUFF_ADDRS_WIDTH-1:0]}};
                            PE_mem_sel <= {`NUM_PE{1'b0}};
                            PE_start <= {`NUM_PE{1'b0}};
                        end
                        else begin
                            state <= feature_write;
                        end
                    end
                    else if(start_conv) begin
                        feature_mem_rd <= 1'b1;
                        i_hori_cntr <= 0;
                        i_verti_cntr <= 0;
                        e_hori_cntr <= 0;
                        e_verti_cntr <= 0;
                        PE_mem_wr <= {{(`NUM_PE-1){1'b0}}, {1'b1}};
                        PE_mem_sel <= {{(`NUM_PE-1){1'b0}}, {1'b1}};
                        PE_start <= {{(`NUM_PE-1){1'b0}}, {1'b0}};
                        PE_mem_addrs_c1 <= 0;
                        state <= s1;
                    end
                    else begin
                        state <= idle;
                        feature_mem_in <= 0;
                        feature_mem_wr <= 0;
                        feature_mem_rd <= 0;
                        feature_mem_addrs_internal <= 0;
                        PE_mem_in <= 0;
                        PE_mem_wr <= 0;
                        PE_mem_addrs <= 0;
                        PE_mem_sel <= 0;
                        PE_start <= 0;
                        i_hori_cntr <= 0;
                        i_verti_cntr <= 0;
                        e_hori_cntr <= 0;
                        e_verti_cntr <= 0;
                        PE_mem_addrs_c1 <= 0;
                        done <= 1'b0;
                        flag_f1 <= 0;
                        pe_counter <= 0;
                        flag_f2 <= 0;
                        o_mem_data_internal <= 0;
                        o_mem_wr_internal <= 0;
                    end
                end
                
                feature_write: begin
                    if(!i_mem_wr) begin
                        state <= idle;
                        feature_mem_in <= 0;
                        feature_mem_wr <= i_mem_wr;
                        feature_mem_addrs_internal <= 0;
                    end
                    else begin
                        state <= feature_write;
                        feature_mem_in <= i_mem_data;
                        feature_mem_wr <= i_mem_wr;
                        feature_mem_rd <= 0;
                        feature_mem_addrs_internal <= i_memory_addrs;
                    end
                end
                
                weights_write: begin
                    if(!i_mem_wr) begin
                        state <= idle;
                        PE_mem_wr <= {`NUM_PE{1'b0}};
                        PE_mem_sel <= {`NUM_PE{1'b0}};
                        PE_mem_in <= 0;
                        PE_mem_addrs <= 0;
                    end
                    else begin
                        state <= weights_write;
                        PE_mem_in <= {`NUM_PE{i_mem_data}};
                        PE_mem_wr <= {`NUM_PE{i_mem_wr}};
                        PE_mem_addrs <= {`NUM_PE{i_memory_addrs[`PE_BUFF_ADDRS_WIDTH-1:0]}};
                        PE_mem_sel <= {`NUM_PE{1'b0}};
                        PE_start <= {`NUM_PE{1'b0}};
                    end
                end
                
                s1: begin
                    feature_mem_rd <= feature_mem_rd;
                    PE_mem_in <= {`NUM_PE{feature_mem_out}};
                    PE_mem_addrs <= {`NUM_PE{PE_mem_addrs_c1}};
                    PE_mem_addrs_c1 <= 0;
                    PE_mem_wr <= PE_mem_wr;
                    PE_mem_sel <= PE_mem_sel;
                    if(i_hori_cntr <= `weightM-1) begin
                        i_hori_cntr <= i_hori_cntr + 1'b1;
                        state <= s2;
                    end
                    
                end
                
                s2: begin
                    feature_mem_rd <= feature_mem_rd;
                    PE_mem_in <= {`NUM_PE{feature_mem_out}};
                    PE_mem_addrs <= {`NUM_PE{PE_mem_addrs_c1}};
                    PE_mem_wr <= PE_mem_wr;
                    PE_mem_sel <= PE_mem_sel;
                    if((`NUM_PE != 1) && flag_f1) begin
                        if(pe_counter < `NUM_PE-1) begin
                            feature_mem_rd <= 1'b1;
                            state <= s2;
                            flag_f2 <= 1'b1;
                            flag_f1 <= 1'b0;
                        end
                        else begin
                            state <= s2;
                            flag_f2 <= 1'b1;
                            flag_f1 <= 1'b0;
                        end
                    end
                    else if((`NUM_PE != 1) && flag_f2) begin
                        flag_f2 <= 1'b0;
                        if(pe_counter == 0) begin
                            PE_start <= {{(`NUM_PE-1){1'b0}}, {1'b1}};
                        end
                        else begin
                            PE_start <= {PE_start[`NUM_PE-2:0], 1'b0};
                        end
                        
                        if((`NUM_PE != 1) && (pe_counter < `NUM_PE-1)) begin
                            feature_mem_rd <= 1'b1;
                            pe_counter <= pe_counter + 1'b1;
                            PE_mem_addrs_c1 <= 0;
                            PE_mem_wr <= {PE_mem_wr[`NUM_PE-2:0], 1'b0};
                            PE_mem_sel <= {PE_mem_sel[`NUM_PE-2:0], 1'b0};
                            if((i_hori_cntr + e_hori_cntr) >= `featureM-1) begin
                                `ifndef CONV_1D
                                    if((i_verti_cntr + e_verti_cntr) >= `featureN-1) begin
                                        state <= op_wait;
                                        feature_mem_rd <= 1'b0;
                                        pe_counter <= pe_counter;
                                        PE_mem_addrs_c1 <= 0;
                                        PE_mem_wr <= 0;
                                        PE_mem_sel <= 0;
                                    end
                                    else if(e_verti_cntr < `featureN-1) begin
                                        i_hori_cntr <= 0;
                                        i_verti_cntr <= 0;
                                        e_hori_cntr <= 0;
                                        e_verti_cntr <= e_verti_cntr + 1'b1;
                                        state <= s1;
                                    end
                                    else begin
                                        state <= stop;
                                    end
                                `else
                                    state <= op_wait;
                                    feature_mem_rd <= 1'b0;
                                    pe_counter <= pe_counter;
                                    PE_mem_addrs_c1 <= 0;
                                    PE_mem_wr <= 0;
                                    PE_mem_sel <= 0;
                                `endif
                            end
                            else if(e_hori_cntr < `featureM-1) begin
                                i_hori_cntr <= 0;
                                i_verti_cntr <= 0;
                                e_hori_cntr <= e_hori_cntr + 1'b1;
                                state <= s1;
                            end
                        end
                        else begin
                            feature_mem_rd <= 1'b0;
                            PE_mem_wr <= 0;
                            PE_mem_sel <= 0;
                            PE_mem_addrs_c1 <= 0;
                            state <= op_wait;
                        end
                        flag_f1 <= 1'b0;
                    end
                    else if(i_hori_cntr < `weightM-1) begin
                        i_hori_cntr <= i_hori_cntr + 1'b1;
                        state <= s2;
                    end
                    else if(i_verti_cntr < `weightN-1) begin
                        i_hori_cntr <= 0;
                        i_verti_cntr <= i_verti_cntr + 1'b1;
                        state <= s2;
                    end
                    else if((i_hori_cntr == `weightM-1) && (i_verti_cntr == `weightN-1)) begin
                        state <= s2;
                        feature_mem_rd <= 0;
                        flag_f1 <= 1'b1;
                    end
                    if(PE_mem_addrs_c1 <= (`weightM * `weightN)-2) begin
                        PE_mem_addrs_c1 <= PE_mem_addrs_c1 + 1'b1;
                    end
                end
                
                op_wait: begin
                    PE_start <= 0;
                    if(!round_done) begin
                        state <= op_wait;
                    end
                    else begin
                        state <= op_write;
                    end
                end
                
                op_write: begin
                    if(j < (pe_counter+1)) begin
                        if(j==0) begin
                            o_mem_wr_internal <= 1'b1;
                            o_mem_data_internal <= PE_out;
                            state <= op_write;
                            j <= j+1;
                        end
                        else begin
                            o_mem_wr_internal <= 1'b1;
                            o_mem_data_internal <= {o_mem_data_internal[`data_width-1:0], o_mem_data_internal[(`NUM_PE * `data_width)-1:(`data_width * multiplier(`NUM_PE))]};
                            j <= j+1;
                            state <= op_write;
                        end
                        if(j== pe_counter) begin
                            feature_mem_rd <= 1'b1;
                        end
                    end
                    else begin
                        pe_counter <= 0;
                        if((i_hori_cntr + e_hori_cntr) >= `featureM-1) begin
                            `ifndef CONV_1D
                                if((i_verti_cntr + e_verti_cntr) >= `featureN-1) begin
                                    state <= stop;
                                end
                                else if(e_verti_cntr < `featureN-1) begin
                                    i_hori_cntr <= 0;
                                    i_verti_cntr <= 0;
                                    e_hori_cntr <= 0;
                                    e_verti_cntr <= e_verti_cntr + 1'b1;
                                    feature_mem_rd <= 1'b1;
                                    e_hori_cntr <= 0;
                                    PE_mem_wr <= {{(`NUM_PE-1){1'b0}}, {1'b1}};
                                    PE_mem_sel <= {{(`NUM_PE-1){1'b0}}, {1'b1}};
                                    PE_start <= {{(`NUM_PE-1){1'b0}}, {1'b0}};
                                    PE_mem_addrs_c1 <= 0;
                                    state <= s1;
                                end
                                else begin
                                    state <= stop;
                                end
                            `else
                                state <= stop;
                            `endif
                        end
                        else if(e_hori_cntr < `featureM-1) begin
                            i_hori_cntr <= 0;
                            i_verti_cntr <= 0;
                            e_hori_cntr <= e_hori_cntr + 1'b1;
                            feature_mem_rd <= 1'b1;
                            PE_mem_wr <= {{(`NUM_PE-1){1'b0}}, {1'b1}};
                            PE_mem_sel <= {{(`NUM_PE-1){1'b0}}, {1'b1}};
                            PE_start <= {{(`NUM_PE-1){1'b0}}, {1'b0}};
                            PE_mem_addrs_c1 <= 0;
                            state <= s1;
                        end
                        else if ((e_hori_cntr == `featureM-1) && (e_verti_cntr == `featureN-1)) begin
                            e_hori_cntr <= e_hori_cntr;
                            e_verti_cntr <= e_verti_cntr;
                            state <= stop;
                        end
                        o_mem_wr_internal <= 1'b0;
                        j <= 0;
                    end
                end
                
                stop: begin
                    done <= 1'b1;
                    state <= idle;
                end
                
                default: begin
                    state <= idle;
                end
            endcase
        end
    end
    
    function [0:0] multiplier;
        input integer num_pe;
        begin
            if(num_pe > 1) begin
                multiplier = 1'b1;
            end
            else begin
                multiplier = 1'b0;
            end
        end
    endfunction
    
    function integer addrs_compute;
        input integer e_verti_cntr, i_verti_cntr, e_hori_cntr, i_hori_cntr;
        begin
            addrs_compute = (((e_verti_cntr + i_verti_cntr)*`featureM) + e_hori_cntr + i_hori_cntr);
        end
    endfunction
    
endmodule
