package FloatingPoint;

    class Float;
        const int BIAS = 127;

        rand logic        sign;
        rand logic [7:0]  exponent;
        rand logic [22:0] mantissa;

        int minexp, maxexp;

        constraint nodenorm_c {exponent != 0 || mantissa == 0;}

        constraint alldenorm_c {exponent == 0 && mantissa != 0;}

        constraint nonan_c {exponent != 255 || mantissa == 0;}

        constraint noinf_c {exponent != 255 || mantissa != 0;}

        constraint exprange_c {exponent inside {[minexp+BIAS:maxexp+BIAS]};}

        static function Float FromComponents(logic sign, logic [7:0] exponent, logic [22:0] mantissa);
            Float f;
            f = new({>> {sign, exponent, mantissa}});

            return f;
        endfunction

        static function Float FromShortreal(shortreal sr);
            Float f;
            f = new($shortrealtobits(sr));

            return f;
        endfunction

        static function int CompareIncludeNaN(Float Op1, Op2);
            if (Op1.IsNaN() && Op2.IsNaN())
                return 1;
            else
                return Op1.ToBits() === Op2.ToBits();
        endfunction

        function new (logic [31:0] bits = '0);
            {>> {sign, exponent, mantissa}} = bits;
            minexp = '0;
            maxexp = '0;
        endfunction

        function string FloatComponents();
            return $sformatf("(Sign: %1b, Exponent: %8b, Mantissa: %23b)", sign, exponent, mantissa);
        endfunction

        function shortreal ToShortreal();
            return $bitstoshortreal(ToBits());
        endfunction

        function logic [31:0] ToBits();
            return {>> {sign, exponent, mantissa}};
        endfunction

        function int IsZero();
            if (exponent === 0 && mantissa === 0)
                return 1;
            else
                return 0;
        endfunction

        function int IsInf();
            if (exponent === 255 && mantissa === 0)
                return 1;
            else
                return 0;
        endfunction

        function int IsDenorm();
            if (exponent === 0 && mantissa !== 0)
                return 1;
            else
                return 0;
        endfunction

        function int IsNaN();
            if (exponent === 255 && mantissa !== 0)
                return 1;
            else
                return 0;
        endfunction
    endclass

endpackage
