module fulladder(A, B, Cin, Cout, S);
input A, B, Cin;
output reg Cout, S;

wire [2:0] C;

xor
	xor1(C[0], A, B),
	xor2(S, Cin, C[0]);
and
	and1(C[1], A, B),
	and2(C[2], C[0], Cin);
or
	or1(Cout, C[1], C[2]);

endmodule
