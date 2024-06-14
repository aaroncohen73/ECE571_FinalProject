module CheckSpecial(Input, Special);

    import floatingpoint::*;

    input float Input;
    output logic Special;

    always @(Input)
      begin
        Special = '0;
        if (IsInf(Input) || IsNaN(Input) || IsDenorm(Input))
            Special = '1;
        else 
            Special = '0;
      end


endmodule
