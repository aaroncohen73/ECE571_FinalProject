module nBitFFO(In, V, I);

    parameter N = 8;
    localparam halfN = N/2;

    input logic [N-1:0] In;
    output logic V;
    output logic [$clog2(N)-1:0] I;

    generate
        if ($countones(N) != 1)
            $fatal("Invalid parameter in module %m: Parameter N = %0d must be a power of 2 which is greater than 1", N);
        else if (N == 2)
            begin
            assign V = |In;
            assign I = In[1];
            end
        else
            begin
            wire upperV, lowerV;
            wire [$clog2(halfN)-1:0] upperI, lowerI;

            assign V = upperV | lowerV;
            assign I = {upperV, upperV ? upperI : lowerI};

            nBitFFO #(.N(N/2)) nBitFFOUpper(In[halfN +: halfN], upperV, upperI);
            nBitFFO #(.N(N/2)) nBitFFOLower(In[    0 +: halfN], lowerV, lowerI);
            end
    endgenerate

endmodule
