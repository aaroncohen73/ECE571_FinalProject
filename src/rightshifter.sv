module rightShift(mantValue,sign,index,shiftedMant,R,S,expNoDif,noLeadingZero,subCtrl);
parameter n = 23;
parameter exp = 8;
input logic [n-1:0] mantValue;
input logic [exp-1:0] index;
input logic sign,expNoDif,noLeadingZero,subCtrl;
output logic [n-1:0] shiftedMant;
output logic S;
output logic R;
logic [exp-1:0] shiftAmount;
int i;

    assign shiftAmount = (index^{8{sign}}) + sign;

always_comb
  begin
  //    shiftAmount = (index^{8{sign}}) + sign;
  for(i = 0; i <shiftAmount; i++)
  begin
    if(mantValue[i] == 1)
      begin
        S = 1;
        break;
      end
    else
      S = 0;
  end
  if(expNoDif)
  shiftedMant = mantValue;
  else
  {shiftedMant,R} = {noLeadingZero,mantValue} >> shiftAmount - 1'b1;
  if(subCtrl)
  begin
  if(shiftedMant[0] && R)
    shiftedMant = shiftedMant +1'b1;
  else if(R&&S)
    shiftedMant  = shiftedMant + 1'b1;
  else
    shiftedMant = shiftedMant;
  R = 0;
  S = 0;
  end
  end
endmodule
