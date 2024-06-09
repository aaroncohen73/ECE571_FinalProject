module BarrelShifter(In, ShiftAmount, ShiftIn, Out, Mode);
parameter nBITS = 32;
input logic Mode;
input [nBITS-1:0] In;
input [$clog2(nBITS)-1:0] ShiftAmount;
input ShiftIn;
output logic [nBITS-1:0] Out;

wire [nBITS-1:0] C[$clog2(nBITS):0];

assign C[0] = In;
assign Out = C[$clog2(nBITS)];

genvar i;

generate
for (i = 0; i<$clog2(nBITS); i=i+1)
	begin:mux
		n2to1Mux #(.nBITS(nBITS)) m (.Select(ShiftAmount[$clog2(nBITS)-1-i]), .A(C[i]<<(2**($clog2(nBITS)-i-1))|{2**($clog2(nBITS)-i-1){ShiftIn}}), .B(C[i]), .muxOut(C[i+1]));
 // else
//		n2to1Mux #(.nBITS(nBITS)) m (.Select(ShiftAmount[$clog2(nBITS)-1-i]), .A(C[i]>>(2**($clog2(nBITS)-i-1))|{2**($clog2(nBITS)-i-1){ShiftIn}}), .B(C[i]), .muxOut(C[i+1]));
	end
	endgenerate

endmodule


