module nBitFFO4Bit(In, V, I);

    input logic [3:0] In;
    output logic V;
    output logic [1:0] I;

    assign V = |In;
    assign I[0] = In[3] | In[1] & ~In[2] & In[3];
    assign I[1] = In[2] | In[3];

endmodule

module nBitFFORecursive(In, V, I);

    parameter N = 8;
    localparam halfN = N/2;

    input logic [N-1:0] In;
    output logic V;
    output logic [$clog2(N)-1:0] I;

    wire upperV, lowerV;
    wire [$clog2(halfN)-1:0] upperI, lowerI;

    assign V = upperV | lowerV;
    assign I = {upperV, upperV ? upperI : lowerI};

    nBitFFO #(halfN) nBitFFOUpper(In[halfN +: halfN], upperV, upperI);
    nBitFFO #(halfN) nBitFFOLower(In[    0 +: halfN], lowerV, lowerI);

endmodule


module nBitFFO(In, V, I);

    parameter N = 8;

    input logic [N-1:0] In;
    output logic V;
    output logic [$clog2(N)-1:0] I;

    generate
        if ($clog2(N)**2 != N)
            $fatal("Error in %m: Parameter N = %d must be a power of 2", N);
        else if (N < 4)
            $fatal("Error in %m: Paramter N = %d must be greater than or equal to 4", N);
        else if (N == 4)
            nBitFFO4Bit FFO4Bit(In, V, I);
        else
            nBitFFORecursive #(N) FFORecursive(In, V, I);
    endgenerate

endmodule
