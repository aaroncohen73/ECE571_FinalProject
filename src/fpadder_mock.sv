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

            @(posedge Clock);

            // STEP 3 - Normalize output
            for (int i = 24; i >= 0; i--)
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

            @(posedge Clock);

            // STEP 4 (TODO) - Rounding
            MantissaRoundingResult <= SumNormalizationResult;

            @(posedge Clock);

            Result.exponent <= SumNormalizationExponent[7:0];
            Result.mantissa <= MantissaRoundingResult[22:0];
            Result.sign <= (SumNormalizationExponent == 0 && MantissaRoundingResult == 0) ? 0 : MantissaAdditionSign[0];
            ResultValid <= 1'b1;
            Busy <= 1'b0;

            @(posedge Clock);
            ResultValid <= 1'b0;
            end
        end

endmodule
