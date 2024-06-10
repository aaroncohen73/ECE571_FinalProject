`define DEBUG_ADDER
module FloatAdder(Op1, Op2, InputValid, Result, ResultValid, Clock, Reset);

import floatingpoint::*;

input  float Op1, Op2;
output float Result;

input  logic InputValid;
output logic ResultValid;

input logic Clock, Reset;

logic [22:0] mant1, mant2, smallMant, mantA, mantB;

logic [23:0] firstMant, normMant, signMant, leftMant, rightMant, roundMant;

logic [24:0] preMant;

logic [7:0] exp1, exp2, preExp, currExp, normExp, roundExp;

logic expSel, mantASel, mantBSel, signSel,roundingMant, roundingExp, incExp, normDir, expNoDif;

logic [7:0] expDif;

logic [4:0] Index;

logic signA, signB, signOut, subCtrl, mantWrong, zeroResult, normRound, shiftRound, round, sticky, valid, doneRounding;

xnor signControl(subCtrl, signA, signB);//

always_ff @(posedge Clock)
begin
if(Reset)
  begin
    mant1 <=0;
    mant2 <=0;
    exp1 <=0;
    exp2 <=0;
    signA <=0;
    signB <=0;
   end
   else if(InputValid)
   begin 
    mant1 <= Op1.mantissa;
    mant2 <= Op2.mantissa;
    exp1 <= Op1.exponent;
    exp2 <= Op2.exponent;
    signA <= Op1.sign;
    signB <= Op2.sign;
    ResultValid <= 0;
   end
   else
    begin
    mant1 <= mant1;
    mant2 <= mant2;
    exp1 <= exp1;
    exp2 <= exp2;
    signA <= signA;
    signB <= signB; 
    ResultValid <= doneRounding;
    end
end

`ifdef DEBUG_ADDER
always @(posedge InputValid)
begin
    $display("-----------------------------------------------------------------");
    $display("START ADDITION");
    @(posedge Clock);
    $strobe("\tINPUTS:\n",
            "\t\tInput 1: Sign=%1b, Exponent=%0d, Mantissa=%23b\n", signA, exp1, mant1,
            "\t\tInput 2: Sign=%1b, Exponent=%0d, Mantissa=%23b", signB, exp2, mant2);
    $strobe("\tSTEP 1: Op1.exponent=%0d, Op2.exponent=%0d\n", Op1.exponent, Op2.exponent,
            "\t\tLarger exponent (mantASel)=%0d, Difference (expDif)=%0d", mantASel ? Op1.exponent : Op2.exponent, expDif);
    $strobe("\tSTEP 2: Operand 1 sign (signA)=%1b, prepended mantissa ({expNoDif,mantA})=%24b\n", signA, {expNoDif, mantA},
            "\t\tOperand 2 sign (signB)=%1b, prepended+shifted mantissa ({1'b1,mantB})=%24b\n", signB, {1'b1, mantB},
            "\t\tResult sign (signOut)=%1b, mantissa (signMant)=%24b", signOut, signMant);

    do
        begin
        $strobe("\tRounding block output (roundingMant)=%1b",roundingMant);
        $strobe("\tSTEP 3: Non-normalized mantissa (preMant)=%25b, exponent (preExp)=%0d\n", preMant, preExp,
                "\t\tNormalized mantissa (normMant)=%24b, exponent (normExp)=%0d\n", normMant, normExp,
                "\t\tFFO Result (Index)=%0d",Index);
        $strobe("\tSTEP 4: Rounding block input: mantissa (normMant)=%24b, exponent (currExp)=%0d\n", normMant, currExp,
                "\t\tRounding block output: mantissa (roundMant)=%24b, exponent (roundExp)=%0d", roundMant, roundExp);
        @(posedge Clock);
        end
    while (~ResultValid);
    $strobe("\tOUTPUT: Sign=%1b, Exponent=%0d, Mantissa=%23b", Result.sign, Result.exponent, Result.mantissa);
end
`endif

//Selects mantissa placement based on exponent ALU output. Doesn't account for exponents being the same
n2to1Mux #(23) mantAmux(mantASel, mant1, mant2, smallMant);//

n2to1Mux #(23) mantBmux(mantBSel, mant1, mant2, mantB);//

//Selects the exponent to send to the normalizing circuitry based on difference in exponents. If same, won't matter 
n2to1Mux #(8) preExpMux(mantBSel, exp1, exp2, preExp);//

//Selects which mux goes through normalizing circuitry based on if rounding is ready or not
n2to1Mux #(8) roundExpMux(roundingExp, roundExp, preExp, currExp);//

//Selects the sign to passthrough based on exponent ALU results THEN mantissa ALU results. 
n2to1Mux #(1) signMux(mantBSel | (mantWrong && expNoDif), signA, signB, signOut);//

//Selects which mantissa to send to the rounding circuit based on if we are currently rounding or not
n2to1Mux #(25) roundMantMux(roundingMant, {1'b0,roundMant}, {normDir,signMant}, preMant);//

//Determines which exponent (therefore operand) is larger. Also determines how far to shift the smaller mantissa to align binary placement.
AddSub8Bit #(8) expALU(expDif, exp1, exp2, mantASel,expNoDif , , ,1'b1);//

//Never select the same mantissa twice
assign mantBSel = ~mantASel;//

//Determines the sum of the two mantissas. If exponent is the same, ordering may be incorrect. To account for this, use logic to decide if output needs 2's complement to restore proper sign
AddSub8Bit #(24) mantALU(firstMant,{1'b1, mantB}, {expNoDif, mantA},mantWrong , , , normDir, ~subCtrl);//

//Ensure correct "sign" of mantissa result
always_comb begin //
if (signA!=signB && expNoDif && mantWrong)
	signMant = ~firstMant+1'b1;
else
	signMant = firstMant;
end
	
//increment exponent during normalizing. If amount normalized by is 0, don't decrement
AddSub8Bit #(8) expInc(normExp, currExp, {7'b0,zeroResult}, , , , ,normDir);//

//DONE Make normalizer circuitry

//output location of first one
nBitFFO #(32) findFirst ({7'b0,preMant}, zeroResult, Index);//

//barrelshifter instantiation, shift left 24-index
BarrelShifter #(32) normalizer({7'b0,preMant}, (Index-5'd24), 1'b0, {leftMant}, 1'b1);//

//pre mantissa right shift
rightShift preMantShift(smallMant,signOut,expDif,mantA,shiftRound,sticky);

//rounding logic
FloatRounding  roundingLogic(normMant,currExp,shiftRound,sticky,Clock,roundMant,roundExp,valid,Reset);

assign roundingMant = valid;
assign roundingExp = valid;
assign doneRounding = valid;

assign Result.sign = signOut;
assign Result.exponent = roundExp;
assign Result.mantissa = roundMant;

//right shift by one
assign rightMant = {preMant,normRound} >> 1;//

//either take the right shift or the left shifted mantissa
n2to1Mux #(24) normDirMux(normDir, rightMant, leftMant, normMant);//

//Pick the right Round bit
n2to1Mux #(1) roundPicker(normDir, normRound, shiftRound, round);//

endmodule
