module AddSub8Bit (result, x, y, ccn, ccz, ccv, ccc, sub);
parameter nBITS = 8;
input [nBITS-1:0] x, y;
output [nBITS-1:0] result;
output ccn, ccz, ccv, ccc;
input sub;

logic [nBITS-1:0] s;
logic [nBITS:0] C;

assign C[0] = sub;

genvar i;

generate
	for(i=0; i<nBITS; i++)
	begin
	xor complement (s[i], y[i], sub);
	fulladder add (.A(x[i]), .B(s[i]), .Cin(C[i]), .Cout(C[i+1]), .S(result[i]));
	end
endgenerate

assign ccn = result[nBITS-1];

assign ccc = C[nBITS];

assign ccz = (result == 0);

xor oflow (ccv, C[nBITS-1], C[nBITS]);

endmodule
