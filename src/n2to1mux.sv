module n2to1Mux(Select, A, B, muxOut);

parameter nBITS = 32;

input [nBITS-1:0] A, B;
input Select;
output [nBITS-1:0] muxOut;

assign muxOut = Select ? A : B;

endmodule
