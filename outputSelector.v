module outputSelector #(parameter numInput=10,parameter inputWidth=16)
(
    input	i_clk,
    input [(numInput*inputWidth)-1:0]	i_data,
    // FIX: Changed input to vector to match the layer's output width
    input [numInput-1:0] i_valid,
    output reg [31:0] o_data,
    output reg	o_data_valid
);

    // 1. Mark 'maxValue' as signed so comparisons respect +/- signs
    reg signed [inputWidth-1:0] maxValue;
    reg [(numInput*inputWidth)-1:0] inDataBuffer;
    integer counter;

    // Detect if ANY valid signal is active to start processing
    wire start_valid;
    assign start_valid = i_valid[0]; // Trigger on the first neuron's valid signal

    always @(posedge i_clk)
    begin
        o_data_valid <= 1'b0;
        
        // Check if we should start capturing data
        if(start_valid)
        begin
            // Capture the first value
            maxValue <= i_data[inputWidth-1:0];
            counter <= 1;
            inDataBuffer <= i_data;
            o_data <= 0;
        end
        else if(counter == numInput)
        begin
            counter <= 0;
            o_data_valid <= 1'b1;
        end
        else if(counter != 0)
        begin
            counter <= counter + 1;
            
            // 2. Use $signed() to force a signed comparison for the new slice
            if($signed(inDataBuffer[counter*inputWidth+:inputWidth]) > maxValue)
            begin
                maxValue <= inDataBuffer[counter*inputWidth+:inputWidth];
                o_data <= counter;
            end
        end
    end
endmodule