module FloatAdder(Op1, Op2, InputValid, Result, ResultValid, Clock, Reset);

    import floatingpoint::*;

    input float Op1, Op2;
    input logic InputValid;
    input logic Clock, Reset;

    output float Result;
    output logic ResultValid;

    logic Busy;

    int SmallerExponentMantissa, LargerExponentMantissa;
    int LargerExponentValue;
    int SmallerExponentSign, LargerExponentSign;

    int MantissaAdditionResult;
    int MantissaAdditionSign;

    int SumNormalizationResult;
    int SumNormalizationExponent;
    int SumNormalizationOverflowUnderflow;

    int MantissaRoundingResult;
    int i;

    always @(posedge Clock)
        begin
        if (Reset)
            begin
            Result <= '0;
            ResultValid <= '0;

            Busy <= '0;

            SmallerExponentMantissa <= '0;
            LargerExponentMantissa <= '0;
            LargerExponentValue <= '0;
            SmallerExponentSign <= '0;
            LargerExponentSign <= '0;

            MantissaAdditionResult <= '0;
            MantissaAdditionSign <= '0;

            SumNormalizationResult <= '0;
            SumNormalizationExponent <= '0;
            SumNormalizationOverflowUnderflow <= '0;

            MantissaRoundingResult <= '0;
            end
        else if (InputValid)
            begin
            Busy <= '1;
            ResultValid <= '0;

            // STEP 1 - Take difference of exponents
            if (Op1.exponent < Op2.exponent)
                begin
                SmallerExponentMantissa <= (Op1.mantissa + 2**23) >> (Op2.exponent - Op1.exponent);
                LargerExponentMantissa <= Op2.mantissa + 2**23;
                LargerExponentValue <= Op2.exponent;
                SmallerExponentSign <= Op1.sign;
                LargerExponentSign <= Op2.sign;
                end
            else
                begin
                SmallerExponentMantissa <= (Op2.mantissa + 2**23) >> (Op1.exponent - Op2.exponent);
                LargerExponentMantissa <= Op1.mantissa + 2**23;
                LargerExponentValue <= Op1.exponent;
                SmallerExponentSign <= Op2.sign;
                LargerExponentSign <= Op1.sign;
                end

            $strobe("-----------------------------------------------------------------");
            $strobe("START ADDITION");
            $strobe("\tINPUTS:\n",
                    "\t\tInput 1: Sign=%1b, Exponent=%0d, Mantissa=%23b\n", Op1.sign, Op1.exponent, Op1.mantissa,
                    "\t\tInput 2: Sign=%1b, Exponent=%0d, Mantissa=%23b", Op2.sign, Op2.exponent, Op2.mantissa);
            $strobe("\tSTEP 1: Op1.exponent=%0d, Op2.exponent=%0d\n", Op1.exponent, Op2.exponent,
                    "\t\tLarger exponent=%0d, Difference=%0d", LargerExponentValue,
                    (Op1.exponent > Op2.exponent) ? (Op1.exponent - Op2.exponent) : (Op2.exponent - Op1.exponent));
            @(posedge Clock);

            // STEP 2 - Add/subtract mantissas after shifting
            if (SmallerExponentSign !== LargerExponentSign)
                if (LargerExponentMantissa > SmallerExponentMantissa)
                    begin
                    MantissaAdditionSign <= LargerExponentSign;
                    MantissaAdditionResult <= LargerExponentMantissa - SmallerExponentMantissa;
                    end
                else
                    begin
                    MantissaAdditionSign <= SmallerExponentSign;
                    MantissaAdditionResult <= SmallerExponentMantissa - LargerExponentMantissa;
                    end
            else
                begin
                MantissaAdditionSign <= LargerExponentSign;
                MantissaAdditionResult <= LargerExponentMantissa + SmallerExponentMantissa;
                end

            SumNormalizationResult <= '0;
            SumNormalizationExponent <= '0;

            $strobe("\tSTEP 2: Operand 1 sign=%1b, prepended mantissa=%24b\n", LargerExponentSign, LargerExponentMantissa,
                    "\t\tOperand 2 sign=%1b, prepended+shifted mantissa=%24b\n", SmallerExponentSign, SmallerExponentMantissa,
                    "\t\tResult sign=%1b, mantissa=%24b", MantissaAdditionSign, MantissaAdditionResult);
            @(posedge Clock);

            // STEP 3 - Normalize output
            for (i = 24; i >= 0; i--)
                if (MantissaAdditionResult[i] == 1)
                    begin
                    if (i == 24)
                        begin
                        SumNormalizationResult <= MantissaAdditionResult >> 1;
                        SumNormalizationExponent <= LargerExponentValue + 1;
                        end
                    else
                        begin
                        SumNormalizationResult <= MantissaAdditionResult << (23 - i);
                        SumNormalizationExponent <= LargerExponentValue - (23 - i);
                        end
                    break;
                    end

            $strobe("\tSTEP 3: Non-normalized mantissa=%25b, exponent=%0d\n", MantissaAdditionResult[24:0], LargerExponentValue,
                    "\t\tNormalized mantissa=%24b, exponent=%0d", SumNormalizationResult[23:0], SumNormalizationExponent);
            @(posedge Clock);

            // STEP 4 (TODO) - Rounding
            MantissaRoundingResult <= SumNormalizationResult;

            @(posedge Clock);

            Result.exponent <= SumNormalizationExponent[7:0];
            Result.mantissa <= MantissaRoundingResult[22:0];
            Result.sign <= (SumNormalizationExponent == 0 && MantissaRoundingResult == 0) ? 0 : MantissaAdditionSign[0];
            ResultValid <= 1'b1;
            Busy <= 1'b0;

            $strobe("\tOUTPUT: Sign=%1b, Exponent=%0d, Mantissa=%23b", Result.sign, Result.exponent, Result.mantissa);
            @(posedge Clock);
            ResultValid <= 1'b0;
            end
        end

endmodule
