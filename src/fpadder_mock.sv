module fpadder(Op1, Op2, InputValid, Clock, Reset, Result, Busy, ResultValid);

    input logic [31:0] Op1, Op2;
    input logic InputValid;
    input logic Clock, Reset;

    output logic [31:0] Result;
    output logic Busy, ResultValid;

    logic [31:0] ComputedResult;

    always @(posedge Clock)
        begin
        if (Reset)
            begin
            Result = '0;
            Busy = '0;
            ResultValid = '0;
            end
        else if (~Busy && InputValid)
            begin
            ComputedResult <= $shortrealtobits($bitstoshortreal(Op1) + $bitstoshortreal(Op2));
            Busy <= '1;
            ResultValid <= '0;
            repeat (5) @(posedge Clock);
            Result <= ComputedResult;
            ResultValid <= '1;
            Busy <= '0;
            end
        end

endmodule
