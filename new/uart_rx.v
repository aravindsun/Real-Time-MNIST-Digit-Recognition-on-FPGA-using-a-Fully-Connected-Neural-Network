`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.04.2026 14:40:47
// Design Name: 
// Module Name: uart_rx
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


module uart_rx (
    input clk,          
    input rx,           
    output reg [7:0] data_out,
    output reg data_valid
);
    // 100MHz / 115200 Baud = 868
    parameter CLKS_PER_BIT = 868; 

    localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
    
    reg [1:0] state = IDLE;
    reg [9:0] clock_count = 0;
    reg [2:0] bit_index = 0;
    reg [7:0] rx_data = 0;

    always @(posedge clk) begin
        case (state)
            IDLE: begin
                data_valid <= 0;
                clock_count <= 0;
                bit_index <= 0;
                if (rx == 1'b0)
                    state <= START;
                else
                    state <= IDLE;
            end
            
            START: begin
                if (clock_count == (CLKS_PER_BIT-1)/2) begin
                    if (rx == 1'b0) begin
                        clock_count <= 0; 
                        state <= DATA;
                    end else
                        state <= IDLE;
                end else begin
                    clock_count <= clock_count + 1;
                    state <= START;
                end
            end
            
            DATA: begin
                if (clock_count < CLKS_PER_BIT-1) begin
                    clock_count <= clock_count + 1;
                    state <= DATA;
                end else begin
                    clock_count <= 0;
                    rx_data[bit_index] <= rx;
                    if (bit_index < 7) begin
                        bit_index <= bit_index + 1;
                        state <= DATA;
                    end else begin
                        bit_index <= 0;
                        state <= STOP;
                    end
                end
            end
            
            STOP: begin
                if (clock_count < CLKS_PER_BIT-1) begin
                    clock_count <= clock_count + 1;
                    state <= STOP;
                end else begin
                    data_out <= rx_data;
                    data_valid <= 1; 
                    state <= IDLE;
                end
            end
            
            default: state <= IDLE;
        endcase
    end
endmodule