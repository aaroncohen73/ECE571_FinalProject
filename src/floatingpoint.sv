package floatingpoint;
    typedef struct packed
    {
        logic        sign;
        logic [7:0]  exponent;
        logic [22:0] mantissa;
    } float;

    function automatic float ShortrealToFloat(input shortreal sr);
        return $shortrealtobits(sr);
    endfunction

    function automatic shortreal FloatToShortreal(input float f);
        return $bitstoshortreal(f);
    endfunction

    function automatic logic IsZero(input float num);
        if (num.exponent === 0 && num.mantissa === 0)
            return 1;
        else
            return 0;
    endfunction

    function automatic logic IsInf(input float num);
        if (num.exponent === 255 && num.mantissa === 0)
            return 1;
        else
            return 0;
    endfunction

    function automatic logic IsDenorm(input float num);
        if (num.exponent === 0 && num.mantissa !== 0)
            return 1;
        else
            return 0;
    endfunction

    function automatic logic IsNaN(input float num);
        if (num.exponent === 255 && num.mantissa !== 0)
            return 1;
        else
            return 0;
    endfunction

    function automatic void DisplayFloatComponents(input float num);
        $display("Sign: %b, Exponent: %b, Mantissa: %b", num.sign, num.exponent, num.mantissa);
    endfunction
endpackage
