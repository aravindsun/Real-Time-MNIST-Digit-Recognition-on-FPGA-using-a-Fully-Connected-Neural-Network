`timescale 1ns / 1ps
`include "include.v"
`define MaxTestSamples 200

module perceptron_tb();
    integer cycle_count;
    reg reset;
    reg clock;
    reg [`dataWidth-1:0] in;
    reg in_valid;
    
    // Ascending order [0:784] ensures image loads Top->Bottom correctly
    reg [`dataWidth-1:0] in_mem [0:784]; 
    
    reg [7:0] fileName[23:0];
    wire intr;
    reg [`dataWidth-1:0] expected;
    wire [3:0] tb_final_prediction; 

    integer right = 0;
    integer wrong = 0;

    // DUT instantiation (AXI ports removed, updated to standard clk/rst)
    perceptron dut(
        .clk(clock),
        .rst(reset),
        .intr(intr),
        .axis_in_data(in),
        .axis_in_data_valid(in_valid),
        .axis_in_data_ready(),
        .final_prediction(tb_final_prediction)
    );

    initial begin
        clock = 1'b0;
        in_valid = 1'b0;
    end

    always #5 clock = ~clock;

    function [7:0] to_ascii;
        input integer a;
        begin
            to_ascii = a + 48;
        end
    endfunction

    task sendData();
    integer t;
    begin
        $readmemb({fileName[17], fileName[16], fileName[15], fileName[14], fileName[13], fileName[12], fileName[11],
               fileName[10], fileName[9], fileName[8], fileName[7], fileName[6], fileName[5], fileName[4], fileName[3],
               fileName[2], fileName[1], fileName[0]}, in_mem);
               
        @(posedge clock);
        @(posedge clock);
        @(posedge clock);
        
        // Send pixels 0 to 783
        for (t = 0; t < 784; t = t + 1) begin
            @(posedge clock);
            in <= in_mem[t];
            in_valid <= 1;
        end
        
        @(posedge clock);
        in_valid <= 0;
        // The label is at index 784
        expected = in_mem[t]; 
    end
    endtask

    // Configuring Test Data 
    integer i, j, layerNo = 1, k;
    integer start;
    integer testDataCount;
    integer testDataCount_int;
    
    initial begin
        reset = 1;
        in_valid = 0;
        #100;
        reset = 0;
        #100;
        
        start = $time;
        
        for (testDataCount = 0; testDataCount < `MaxTestSamples; testDataCount = testDataCount + 1) begin
            testDataCount_int = testDataCount;
            fileName[0] = "t"; fileName[1] = "x"; fileName[2] = "t"; fileName[3] = ".";
            fileName[4] = "0"; fileName[5] = "0"; fileName[6] = "0"; fileName[7] = "0";
            
            i = 0;
            while (testDataCount_int != 0) begin
                fileName[i + 4] = to_ascii(testDataCount_int % 10);
                testDataCount_int = testDataCount_int / 10;
                i = i + 1;
            end
            
            fileName[8] = "_"; fileName[9] = "a"; fileName[10] = "t"; fileName[11] = "a";
            fileName[12] = "d"; fileName[13] = "_"; fileName[14] = "t"; fileName[15] = "s";
            fileName[16] = "e"; fileName[17] = "t";
            
            sendData();
            
            // Wait for the neural network to finish processing the image
            @(posedge intr);
            
            // Check the prediction output directly against expected label
            if (tb_final_prediction == expected[3:0]) begin
                right = right + 1;
                $display("%0d. Accuracy: %f, Detected: %0x, Expected: %x (MATCH)", testDataCount + 1, right * 100.0 / (testDataCount + 1), tb_final_prediction, expected);
            end else begin
                $display("%0d. Accuracy: %f, Detected: %0x, Expected: %x (MISMATCH)", testDataCount + 1, right * 100.0 / (testDataCount + 1), tb_final_prediction, expected);
            end
        end
        $display("Final Accuracy: %f", right * 100.0 / `MaxTestSamples);
        $display("Number of clock cycles: %d", cycle_count);
        $stop;
    end
    
    always @(posedge clock) begin 
        if (reset)
            cycle_count <= 0;
        else
            cycle_count <= cycle_count + 1; 
    end

    initial begin
        $dumpfile("perceptron_output.vcd"); 
        $dumpvars(0, perceptron_tb);       
    end
endmodule