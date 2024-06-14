`define DEBUG
module top;

    parameter TEST_CYCLES = 100;

    import FloatingPoint::Float;
    import floatingpoint::*;

    var logic [31:0] Op1, Op2;
    var logic InputValid, Clock, Reset;

    wire logic [31:0] Result;
    wire logic ResultValid;
    wire logic outputInvalid, inputInvalid;

    int roundErrCount, otherErrCount;


    FloatAdder DUT(Op1, Op2, InputValid, Result, ResultValid, Clock, Reset, outputInvalid, inputInvalid);

    covergroup AdderCoverage;
        results: coverpoint Result iff (ResultValid)
            {
                bins zero   = { 'd0, 'd2147483648 };
                bins inf    = { 'd2139095040, 'd4286578688 };
                bins nan    = { ['d2139095041:'d2147483647], ['d4286578689:'d4294967295] };
                bins norm   = { ['d8388608:'d2139095039], ['d2155872256:'d4286578687] };
                bins denorm = { ['d1:'d8388607], ['d2147483649:'d2155872255] };
            }
        addend1: coverpoint Op1 iff (InputValid)
            {
                bins zero   = { 'd0, 'd2147483648 };
                bins inf    = { 'd2139095040, 'd4286578688 };
                bins nan    = { ['d2139095041:'d2147483647], ['d4286578689:'d4294967295] };
                bins norm   = { ['d8388608:'d2139095039], ['d2155872256:'d4286578687] };
                bins denorm = { ['d1:'d8388607], ['d2147483649:'d2155872255] };
            }
        addend2: coverpoint Op2 iff (InputValid)
            {
                bins zero   = { 'd0, 'd2147483648 };
                bins inf    = { 'd2139095040, 'd4286578688 };
                bins nan    = { ['d2139095041:'d2147483647], ['d4286578689:'d4294967295] };
                bins norm   = { ['d8388608:'d2139095039], ['d2155872256:'d4286578687] };
                bins denorm = { ['d1:'d8388607], ['d2147483649:'d2155872255] };
            }
    endgroup

    property AdderTransaction_p;
        @(posedge Clock)
        disable iff (Reset)
            InputValid |=> (~ResultValid) ##1 (ResultValid) [->1];
    endproperty
    AdderTransaction_a: assert property(AdderTransaction_p)
                        else $error("Adder interface requirements not met");

    property ValidInputCheck_p;
        @(posedge Clock)
        disable iff (Reset)
            ~inputInvalid |->
                ~(IsNaN(Op1) || IsInf(Op1) || IsDenorm(Op1) ||
                IsNaN(Op2) || IsInf(Op2) || IsDenorm(Op2));
    endproperty
    ValidInputCheck_a: assert property(ValidInputCheck_p)
                       else $error("inputInvalid is asserted for valid inputs\n\tOp1 = %32b\n\tOp2 = %32b",
                                   $sampled(Op1), $sampled(Op2));

    property InvalidInputCheck_p;
        @(posedge Clock)
        disable iff (Reset)
            inputInvalid |->
                IsNaN(Op1) || IsInf(Op1) || IsDenorm(Op1) ||
                IsNaN(Op2) || IsInf(Op2) || IsDenorm(Op2);
    endproperty
    InvalidInputCheck_a: assert property(InvalidInputCheck_p)
                         else $error("inputInvalid is not asserted for invalid inputs\n\tOp1 = %32b\n\tOp2 = %32b",
                                     $sampled(Op1), $sampled(Op2));

    property ValidOutputCheck_p;
        @(posedge ResultValid)
        disable iff (Reset)
            ~outputInvalid |-> ~(IsNaN(Result) || IsInf(Result));
    endproperty
    ValidOutputCheck_a: assert property(ValidOutputCheck_p)
                          else $error("outputInvalid is asserted for valid output %32b", $sampled(Result));

    property InvalidOutputCheck_p;
        @(posedge ResultValid)
        disable iff (Reset)
            outputInvalid |-> IsNaN(Result) || IsInf(Result);
    endproperty
    InvalidOutputCheck_a: assert property(InvalidOutputCheck_p)
                          else $error("outputInvalid is not asserted for invalid output %32b", $sampled(Result));

    task InitDUT();
        Op1 = '0;
        Op2 = '0;
        InputValid = '0;
        ResetDUT(3);
    endtask

    task ResetDUT(int ResetCycles);
        @(negedge Clock) Reset = '1;
        repeat (ResetCycles) @(posedge Clock);
        Reset = '0;
    endtask

    initial
        begin
        Clock = '0;
        forever #5 Clock = ~Clock;
        end

    final
        begin
        $display("Rounding errors: %d, other errors: %d", roundErrCount, otherErrCount);
        end

    int Error;
    AdderCoverage cov;

    initial
        begin
        Error = 0;
        cov = new;
        InitDUT();

        TestAdditionInRange(TEST_CYCLES, -10, 13);
        TestAdditionNormals(TEST_CYCLES);
        TestAdditionToInverse(TEST_CYCLES);
        TestAdditionToPlusMinusZero(TEST_CYCLES);

        //add smallest norm float to largest float
        TestAdditionGeneric('h00800000, 'h7F7FFFFF);

        //add smallest norm float to smallest norm float
        TestAdditionGeneric('h00800000, 'h00800000);

        //add largest float to largest float
        TestAdditionGeneric('h7F7FFFFF, 'h7F7FFFFF);

        //add a NaN to float (3.14)
        TestAdditionGeneric('hFFC00001, 'h4048F5C3);

        if (!Error)
            $display("All tests passed without errors");
        $finish;
        end

    task automatic CheckAdditionResult(Float In1, In2);
        shortreal sr1, sr2;
        Float DUT_Res, KGD_Res, tmp;

        sr1 = In1.ToShortreal();
        sr2 = In2.ToShortreal();

        @(negedge Clock);
        Op1 = In1.ToBits();
        Op2 = In2.ToBits();
        InputValid = 1;
        cov.sample();
        @(negedge Clock);
        InputValid = 0;

        while (~ResultValid) @(posedge Clock);

        DUT_Res = new(Result);
        KGD_Res = Float::FromShortreal(sr1 + sr2);

        `ifdef DEBUG
            $display("\tExpected output: %f %s\n\tActual output: %f %s",
                        KGD_Res.ToShortreal(), KGD_Res.FloatComponents(),
                        DUT_Res.ToShortreal(), DUT_Res.FloatComponents());
            $display("\tInput 1: %f %s\n\tInput 2: %f %s",
                        sr1, In1.FloatComponents(),
                        sr2, In2.FloatComponents());
        `endif

        assert(ResultValid && Float::CompareIncludeNaN(KGD_Res, DUT_Res))
        else
            begin
            Error = 1;
            $error("Floating point addition result doesn't match known-good model.\n",
                   "\tExpected output: %0.3e %s\n\tActual output: %0.3e %s\n",
                        KGD_Res.ToShortreal(), KGD_Res.FloatComponents(),
                        DUT_Res.ToShortreal(), DUT_Res.FloatComponents(),
                   "\tInput 1: %0.3e %s\n\tInput 2: %0.3e %s",
                        sr1, In1.FloatComponents(),
                        sr2, In2.FloatComponents());

            if ((In1.sign || In2.sign) && KGD_Res.exponent == DUT_Res.exponent && ((In1.mantissa-In2.mantissa <= -2) || (In1.mantissa-In2.mantissa >= 2)))
	    	        roundErrCount++;
	        else if (!(In1.sign || In2.sign) && KGD_Res.exponent == DUT_Res.exponent && ((In1.mantissa-In2.mantissa <= 2) || (In1.mantissa-In2.mantissa >= 2)))
		            otherErrCount++;
            end

        cov.sample();
    endtask

    task TestAdditionNormals(int TestCycles);
        Float In1, In2;
        In1 = new;
        In2 = new;

        $display("Testing addition of normals to normals");

        In1.constraint_mode(0);
        In1.nodenorm_c.constraint_mode(1);
        In1.nonan_c.constraint_mode(1);
        In1.noinf_c.constraint_mode(1);

        In2.constraint_mode(0);
        In2.nodenorm_c.constraint_mode(1);
        In2.nonan_c.constraint_mode(1);
        In2.noinf_c.constraint_mode(1);

        for (int i = 0; i < TestCycles; i++)
            begin
            assert(In1.randomize());
            assert(In2.randomize());
            CheckAdditionResult(In1, In2);
            CheckAdditionResult(In2, In1);
            end
    endtask

    task TestAdditionInRange(int TestCycles, int minExp, int maxExp);
        Float In1, In2;
        In1 = new;
        In2 = new;

        In1.minexp = minExp;
        In1.maxexp = maxExp;
        In2.minexp = minExp;
        In2.maxexp = maxExp;

        $display("Testing addition of normals to normals");

        In1.constraint_mode(0);
        In1.nodenorm_c.constraint_mode(1);
        In1.nonan_c.constraint_mode(1);
        In1.noinf_c.constraint_mode(1);
        In1.exprange_c.constraint_mode(1);

        In2.constraint_mode(0);
        In2.nodenorm_c.constraint_mode(1);
        In2.nonan_c.constraint_mode(1);
        In2.noinf_c.constraint_mode(1);
        In2.exprange_c.constraint_mode(1);

        for (int i = 0; i < TestCycles; i++)
            begin
            assert(In1.randomize());
            assert(In2.randomize());
            CheckAdditionResult(In1, In2);
            CheckAdditionResult(In2, In1);
            end
    endtask

    task TestAdditionToInverse(int TestCycles);
        Float In1, In2;
        In1 = new;
        In2 = new;

        $display("Testing addition of normals to their inverse");

        In1.constraint_mode(0);
        In1.nodenorm_c.constraint_mode(1);
        In1.nonan_c.constraint_mode(1);
        In1.noinf_c.constraint_mode(1);

        for (int i = 0; i < TestCycles; i++)
            begin
            assert(In1.randomize());
            In2.sign = ~In1.sign;
            In2.exponent = In1.exponent;
            In2.mantissa = In1.mantissa;

            CheckAdditionResult(In1, In2);
            CheckAdditionResult(In2, In1);
            end
    endtask

    task TestAdditionToPlusMinusZero(int TestCycles);
        Float In1, In2;
        In1 = new;
        In2 = new;

        $display("Testing addition of normals to +/-0");

        In1.constraint_mode(0);
        In1.nodenorm_c.constraint_mode(1);
        In1.nonan_c.constraint_mode(1);
        In1.noinf_c.constraint_mode(1);

        In2.exponent = 0;
        In2.mantissa = 0;

        for (int i = 0; i < TestCycles; i++)
            begin
            assert(In1.randomize());
            In2.sign = 0;

            CheckAdditionResult(In1, In2);
            CheckAdditionResult(In2, In1);

            In2.sign = 1;

            CheckAdditionResult(In1, In2);
            CheckAdditionResult(In2, In1);
            end
    endtask


    //Task to test addition of two particular operands
    task TestAdditionGeneric(int fpBits1, fpBits2);
            Float In1, In2;
            In1 = new;
            In2 = new;

            In1.sign = fpBits1[31];
            In1.exponent = fpBits1[30:23];
            In1.mantissa = fpBits1[22:0];

            In2.sign = fpBits2[31];
            In2.exponent = fpBits2[30:23];
            In2.mantissa = fpBits2[22:0];

            CheckAdditionResult(In1, In2);
            CheckAdditionResult(In2, In1);

    endtask

endmodule
