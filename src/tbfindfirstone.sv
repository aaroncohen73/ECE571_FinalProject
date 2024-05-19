module top;

    parameter N = 4;

    logic [N-1:0] In;
    logic V;
    logic [$clog2(N)-1:0] I;
    logic Error = 0;
    
    function findFirst(logic [N-1:0]findMe);
	    for (int i=N; i>0; i--)
		begin
			if(findMe[i])
				return i;
		end
		return 0;
	endfunction


    nBitFFO #(N) dut(In, V, I);

   // initial
   // begin
    //    $monitor($time,,, "%b : %b %b ", In, V, I);
    //end

    initial
    begin
        for (int i = 0; i < 2**N; i++)
        begin
            In = i;
            #10;
	    if (I !==findFirst(In))
	    begin
		    $display("In = %b, Index = %b, Expected = %b, Valid = %b",In,I,findFirst(In));
		    Error = 1;
	    end
        end
        #10;
	if (Error ===0)
		$display("Sim completed with no errors!");
        $finish;
    end
endmodule
