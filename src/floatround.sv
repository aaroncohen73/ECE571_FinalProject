module FloatRounding(normMant,normExp,R,S,Clock,roundMant,roundExp,valid,Reset,validInput,rounded,ResultValid,signOut,roundSign);
parameter n = 24;
parameter exp = 8;
input logic [n-1:0] normMant;
input logic [exp-1:0] normExp; 
input logic R,S,Reset,Clock,validInput,ResultValid,signOut;
output logic [n-1:0] roundMant;
output logic [exp-1:0]  roundExp;
output logic valid,roundSign;

output logic rounded;

  always_ff @(posedge Clock)
    begin
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
        rounded <= 0;
        end
     else  if (normMant[0] && R)
        begin
        valid <= 0;
        roundMant <= normMant+1'b1; // Round up 
        rounded <= '1;
        end
      else if(R&&S)
        begin
          valid <= 0;
          roundMant <= normMant+1'b1; // Round up 
          rounded <= '1;
        end
      else
        begin
        valid <= 1;
        roundMant <= normMant; // Round down
        rounded <= 0;
        end
      roundExp <= normExp;
      roundSign <= signOut;
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
