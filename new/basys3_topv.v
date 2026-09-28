`timescale 1ns / 1ps

module basys3_top (
    input clk,          
    input btnC,         
    input RsRx,         
    output [3:0] an,    
    output [6:0] seg    
);
    wire [7:0] rx_data;
    wire rx_valid;

    uart_rx receiver (
        .clk(clk),
        .rx(RsRx),
        .data_out(rx_data),
        .data_valid(rx_valid)
    );

    wire intr; 
    wire [3:0] nn_prediction;
    
    perceptron my_nn (
        .clk(clk),
        .rst(btnC),  // <--- FIXED: Removed the '~' so it only resets when pressed
        .axis_in_data(rx_data),
        .axis_in_data_valid(rx_valid),
        .axis_in_data_ready(),
        .intr(intr),
        .final_prediction(nn_prediction)
    );

    reg [3:0] display_digit = 4'hF; 
    
    always @(posedge clk) begin
        if (btnC)
            display_digit <= 4'hF;
        else if (intr)
            display_digit <= nn_prediction;
    end

    seven_segment_ctrl display_unit (
        .clk(clk),
        .digit_val(display_digit),
        .an(an),
        .seg(seg)
    );
endmodule