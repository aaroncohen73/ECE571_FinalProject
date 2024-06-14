
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

//some specific test cases; could replace "magic" numbers with const ints

//add smallest norm float to largest float
TestAdditionGeneric('h00800000, 'h7F7FFFFF);

//add smallest norm float to smallest norm float
TestAdditionGeneric('h00800000, 'h00800000);

//add largest float to largest float
TestAdditionGeneric('h7F7FFFFF, 'h7F7FFFFF);

//add a NaN to float (3.14)
TestAdditionGeneric('hFFC00001, 'h4048F5C3);

//test addition of all exponents (rest randomized)
task TestAdditionAllExp(int TestCycles);
        Float In1, In2;
        In1 = new;
        In2 = new;

        In1.constraint_mode(0);
        In1.nodenorm_c.constraint_mode(1);
        In1.nonan_c.constraint_mode(1);
        In1.noinf_c.constraint_mode(1);

        In2.constraint_mode(0);
        In2.nodenorm_c.constraint_mode(1);
        In2.nonan_c.constraint_mode(1);
        In2.noinf_c.constraint_mode(1);

        for (int j = 1; j < 255; j++)
            In1.exponent = j;
            for (int i = 0; i < TestCycles; i++)
                begin
                        assert(In1.randomize(sign));
                        assert(In1.randomize(mantissa));
                        assert(In2.randomize());
                
                CheckAdditionResult(In1, In2);
                CheckAdditionResult(In2, In1);
            end
endtask

//add some integers (in float format) to floats
task TestAdditionIntToFloat(int TestCycles);
        Float In1, In2;
        In1 = new;
        In2 = new;

        In2.constraint_mode(0);
        In2.nodenorm_c.constraint_mode(1);
        In2.nonan_c.constraint_mode(1);
        In2.noinf_c.constraint_mode(1);

        for (int i = 0; i < TestCycles; i++)
            begin
            In1 = FromShortreal(i * 1.0); //could also cast
            assert(In2.randomize());
            
            CheckAdditionResult(In1, In2);
            CheckAdditionResult(In2, In1);
        end
endtask

//add some integers (in float format) to thmeselves
task TestAdditionIntToInt(int TestCycles);
        Float In1, In2;
        In1 = new;
        In2 = new;

        //Note that integers 0 to 16777216 can be represented exactly
        for (int i = 0; i < TestCycles; i++)
            begin
            In1 = FromShortreal(i * 1.0); //could also cast
            In2 = FromShortreal(i * 1.0);
            
            CheckAdditionResult(In1, In2);
            CheckAdditionResult(In2, In1);
        end
endtask
