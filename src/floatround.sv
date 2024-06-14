module
FloatRounding(normMant,normExp,R,S,Clock,roundMant,roundExp,valid,Reset,validInput,rounded,ResultValid,signOut,roundSign,expNoDif,mantNoDif,subCtrl,isInf,isNaN,isZero);
parameter n = 24;
parameter exp = 8;
input logic [n-1:0] normMant;
input logic [exp-1:0] normExp; 
input logic
R,S,Reset,Clock,validInput,ResultValid,signOut,expNoDif,mantNoDif,subCtrl;
output logic [n-1:0] roundMant;
output logic [exp-1:0]  roundExp;
output logic valid,roundSign,isInf,isZero,isNaN;

output logic rounded;

  always_ff @(posedge Clock)
    begin
      isInf <= 0;
      isNaN <= 0;
      isZero <= 0;
      if(normExp == '1 && normMant == '0)
        isInf <= 1;
      else if(normExp == '1 && normMant != '0)
        isNaN <= 1;
      else if(normExp == '0 && normMant == '0)
        isZero <= 1;
      if(Reset || ResultValid)
        begin
          valid <=0;
          roundMant <=0;
          roundExp <=0;
          rounded <=0;
          roundSign <= 0;
        end
      else if(validInput)
      begin
      if(rounded == '1)
        begin
        valid <= 1;
        roundMant <= normMant; 
        roundExp <= normExp;
        roundSign <= signOut;
        rounded <= 0;
        end
     else if(expNoDif && mantNoDif)
        begin
        roundMant <= 0;
        roundExp <= 0;
        roundSign <= 0;
        rounded <= 0;
        valid <= 1;
        end
     else if (normMant[0] && R)
        begin
        valid <= 0;
        roundMant <= normMant+1'b1; // Round up 
        roundExp <= normExp;
        roundSign <= signOut;
        rounded <= '1;
        end
      else if(R&&S)
        begin
          valid <= 0;
          roundMant <= normMant+1'b1; // Round up 
          roundExp <= normExp;
          roundSign <= signOut;
          rounded <= '1;
        end
      else
        begin
        valid <= 1;
        roundMant <= normMant; // Round down
        roundExp <= normExp;
        roundSign <= signOut;
        rounded <= 0;
        end
      end
    else if(!validInput)
      begin
        roundMant <= '0;
        roundExp <= '0;
        roundSign <= 0;
        valid <= 0;
        rounded <= 0;
      end
    end
endmodule
