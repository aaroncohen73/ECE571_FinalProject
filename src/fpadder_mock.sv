module FloatAdder(Op1, Op2, InputValid, Result, ResultValid, Clock, Reset);

    import floatingpoint::*;

    parameter ExtraPrecisionBits = 2; // Round and sticky bit

    input float Op1, Op2;
    input logic InputValid;
    input logic Clock, Reset;

    output float Result;
    output logic ResultValid;

    logic Busy;

    int SmallerExponentMantissa, LargerExponentMantissa;
    int LargerExponentValue;
    int SmallerExponentSign, LargerExponentSign;

    int Round, Sticky;

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

            Round <= '0;
            Sticky <= '0;

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
                LargerExponentMantissa <= (Op2.mantissa + 2**23);
                LargerExponentValue <= Op2.exponent;
                SmallerExponentSign <= Op1.sign;
                LargerExponentSign <= Op2.sign;

                if (Op2.exponent - Op1.exponent == 0)
                    Round <= 0;
                else
                    Round <= Op1.mantissa[Op2.exponent - Op1.exponent - 1];

                if (Op2.exponent - Op1.exponent <= 1)
                    Sticky <= 0;
                else
                    Sticky <= (Op1.mantissa != (Op1.mantissa >> (Op2.exponent - Op1.exponent - 1) << (Op2.exponent - Op1.exponent - 1)));
                end
            else
                begin
                SmallerExponentMantissa <= (Op2.mantissa + 2**23) >> (Op1.exponent - Op2.exponent);
                LargerExponentMantissa <= (Op1.mantissa + 2**23);
                LargerExponentValue <= Op1.exponent;
                SmallerExponentSign <= Op2.sign;
                LargerExponentSign <= Op1.sign;

                if (Op1.exponent - Op2.exponent == 0)
                    Round <= 0;
                else
                    Round <= Op2.mantissa[Op1.exponent - Op2.exponent - 1];

                $strobe("%32b",(Op2.mantissa << (31 - (Op1.exponent - Op2.exponent - 2))));

                if (Op2.exponent - Op1.exponent <= 1)
                    Sticky <= 0;
                else
                    Sticky <= (Op2.mantissa != (Op2.mantissa >> (Op1.exponent - Op2.exponent - 1) << (Op1.exponent - Op2.exponent - 1)));
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

            $strobe("\tSTEP 3: Non-normalized mantissa=%25b, exponent=%0d\n", MantissaAdditionResult, LargerExponentValue,
                    "\t\tNormalized mantissa=%24b, exponent=%0d", SumNormalizationResult, SumNormalizationExponent);
            @(posedge Clock);

            // STEP 4 (TODO) - Rounding

            // Rounding conditions
            if (Round && Sticky)
                begin
                if (MantissaAdditionSign[0])
                    MantissaRoundingResult <= SumNormalizationResult - 1;
                else
                    MantissaRoundingResult <= SumNormalizationResult + 1;
                $strobe("\t\tRounding to nearest performed");
                end
            else if (SumNormalizationResult[0] && Round && ~Sticky)
                begin
                if (MantissaAdditionSign[0])
                    MantissaRoundingResult <= SumNormalizationResult - 1;
                else
                    MantissaRoundingResult <= SumNormalizationResult + 1;
                $strobe("\t\tRounding to even performed");
                end
            else
                begin
                MantissaRoundingResult <= SumNormalizationResult;
                $strobe("\t\tRounding not performed");
                end
            $strobe("\tSTEP 4: Rounding mantissa = %23b, G = %1b, R = %1b, S = %1b", MantissaRoundingResult, SumNormalizationResult[0], Round, Sticky);

            @(posedge Clock);

            // Re-normalize
            if (MantissaRoundingResult[24])
                begin
                MantissaRoundingResult <= MantissaRoundingResult >> 1;
                SumNormalizationExponent <= SumNormalizationExponent + 1;
                $strobe("\t\tRe-normalized result");
                end

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
