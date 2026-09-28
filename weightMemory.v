`timescale 1ns / 1ps
`include "include.v"
 
module weightMemory #(parameter numWeight = 784, neuronNo=0,layerNo=1,addressWidth=10,dataWidth=8,weightFile="w_1_0.mif") 
( 
	input clk,
	input ren,
	input [addressWidth-1:0] radd,
	output reg [dataWidth-1:0] wout    
);
	reg [dataWidth-1:0] mem [numWeight-1:0];
	// Loading Pre-Trained Weights File
	`ifdef pretrained
	    	initial
	    	begin
	    		$readmemb(weightFile, mem);
	    	end
	`endif
	// Read Operation
	always @(posedge clk)
	begin
		if (ren)
        	begin
        		wout <= mem[radd];
        	end
        end
endmodule