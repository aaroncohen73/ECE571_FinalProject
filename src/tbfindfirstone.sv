module top;

    parameter N = 4;

    logic [N-1:0] In;
    logic V;
    logic [$clog2(N)-1:0] I;

    nBitFFO #(N) dut(In, V, I);

    initial
    begin
        $monitor($time,,, "%b : %b %b ", In, V, I);
    end

    initial
    begin
        for (int i = 0; i < 2**N; i++)
        begin
            In = i;
            #10;
        end
        #10;
        $finish;
    end
endmodule
