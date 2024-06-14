module CheckSpecial(Input, Special);

    import floatingpoint::*;

    input float Input;
    output logic Special

    always @(Input)
        Special = '0;
        if (IsInf(Input) || IsNaN(Input) || IsDeNorm(Input))
            Special = '1;
        else 
            Special = '0;


endmodule
