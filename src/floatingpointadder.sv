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

logic [7:0] holder;

logic signA, signB, signOut, subCtrl, mantWrong, zeroResult, normRound, shiftRound, round, sticky, valid, validInput,rounded,roundSign;

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
//    sticky <= 0; 
 //   shiftRound <= 0;
    validInput <= 1;
   end
   else
    begin
    mant1 <= mant1;
    mant2 <= mant2;
    exp1 <= exp1;
    exp2 <= exp2;
    signA <= signA;
    signB <= signB; 
    end
end


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
AddSub8Bit #(8) expALU(expDif, exp1, exp2, mantASel,expNoDif , , abc,1'b1);//

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
BarrelShifter #(32) normalizer({7'b0,preMant}, (5'd23-Index), 1'b0, {holder,leftMant}, 1'b1);//
//assign leftMant = preMant << (Index-5'd24);
//pre mantissa right shift
rightShift preMantShift(smallMant,mantASel,expDif,mantA,shiftRound,sticky);

//rounding logic
FloatRounding roundingLogic(normMant,currExp,shiftRound,sticky,Clock,roundMant,roundExp,valid,Reset,validInput,rounded,ResultValid,signOut,roundSign);

assign roundingMant = rounded;
assign roundingExp =rounded;
assign ResultValid = valid;
assign Result.sign = roundSign;
assign Result.exponent = roundExp;
assign Result.mantissa = roundMant;

//right shift by one
assign rightMant = {preMant,normRound} >> 1'b1;//

//either take the right shift or the left shifted mantissa
n2to1Mux #(24) normDirMux(normDir, rightMant, leftMant, normMant);//

//Pick the right Round bit
n2to1Mux #(1) roundPicker(normDir, normRound, shiftRound, round);//

endmodule
