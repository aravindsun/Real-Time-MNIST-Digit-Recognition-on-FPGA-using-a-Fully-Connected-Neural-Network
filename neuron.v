`timescale 1ns / 1ps

`include "include.v"
 
module neuron #(

    parameter layerNo=0,

    neuronNo=0,

    numWeight=784,

    dataWidth=8,

    sigmoidSize=10,

    weightIntWidth=1,

    actType="relu", 

    biasFile="b_1_0.mif",

    weightFile="w_1_0.mif"

)

(

    input   clk,

    input   rst,

    input [dataWidth-1:0]   myinput,

    input   myinputValid,

    input   weightValid,

    input   biasValid,

    input [31:0]    weightValue,

    input [31:0]    biasValue,

    input [31:0]    config_layer_num,

    input [31:0]    config_neuron_num,

    output reg [dataWidth-1:0]  out,

    output reg  outvalid    

);

    parameter addressWidth = $clog2(numWeight);

    wire    ren;

    reg [addressWidth:0]    r_addr;

    wire [dataWidth-1:0]    w_out;

    // 1. EXPAND ACCUMULATOR TO 32 BITS

    reg signed [2*dataWidth-1:0]    mul;    // 16 bits is fine for single mult

    reg signed [31:0]               sum;    // 32 bits prevents overflow during accumulation

    reg signed [31:0]               bias;   // 32 bits for bias

    reg [31:0]  biasReg[0:0];

    reg weight_valid;

    reg mult_valid;

    wire    mux_valid;

    reg sigValid; 

    // Wire for intermediate calc

    wire signed [31:0]   biasSum; 

    wire signed [31:0]   weightedSum;

    reg [dataWidth-1:0] myinputd;

    reg muxValid_d;

    reg muxValid_f;

    reg addr=0;

    assign mux_valid = mult_valid;

    assign weightedSum = sum + mul; 

    assign biasSum = sum + bias; 

    assign ren = myinputValid;

    //Initialize Weight Memory

    weightMemory #(.numWeight(numWeight),.neuronNo(neuronNo),.layerNo(layerNo),.addressWidth(addressWidth),.dataWidth(dataWidth),.weightFile(weightFile)) 

    Weight_Memory(

        .clk(clk),

        .ren(ren),

        .radd(r_addr),

        .wout(w_out)

    );

    // Read Address Control

    always @(posedge clk)

    begin

        if(rst|outvalid)

            r_addr <= 0;

        else if(myinputValid)

            r_addr <= r_addr + 1;

    end

    // Initialize Bias

    `ifdef pretrained

        initial

        begin

            $readmemb(biasFile,biasReg);

        end

        always @(posedge clk)

        begin

            // Load bias and sign extend to 32 bits

            bias <= $signed(biasReg[addr][dataWidth-1:0]);

        end

    `endif

 
    // Multiply: Q1.7 * Q1.7 = Q2.14

    // Shift right by 7 to align decimal point -> Q2.7

    always @(posedge clk)

    begin

        mul <= ($signed(myinputd) * $signed(w_out)) >>> 7;

    end

    // Accumulate (Using 32-bit math now)

    always @(posedge clk)

    begin

        if(rst|outvalid)

            sum <= 0;

        else if((r_addr == numWeight) & muxValid_f) 

        begin   

            sum <= biasSum; // Add bias at the end

        end

        else if(mux_valid)

        begin   

            sum <= weightedSum; // Accumulate

        end

    end

    // Valid Signal Generation

    always @(posedge clk)

    begin

        myinputd <= myinput;

        weight_valid <= myinputValid;

        mult_valid <= weight_valid;

        sigValid <= ((r_addr == numWeight) & muxValid_f) ? 1'b1 : 1'b0;

        outvalid <= sigValid;

        muxValid_d <= mux_valid;

        muxValid_f <= !mux_valid & muxValid_d;

    end

    // Activation: ReLU with 32-bit Saturation Logic

    generate

        if(actType == "relu")

        begin: reluinst

             always @(*) begin

                // 1. Check Negative (Sign bit of 32-bit sum)

                if (sum[31] == 1'b1) 

                    out = 8'd0;

                // 2. Check Overflow (If any bits above 7 are 1)

                // We want 8 bits output (1 sign, 7 frac). Max is 127.

                // If bits [30:7] have any value, it means result > 127.

                else if (|sum[30:7]) 

                    out = 8'd127; // Clamp to max positive

                // 3. Pass through

                else

                    out = sum[7:0];

             end

        end

    endgenerate
 
endmodule
 