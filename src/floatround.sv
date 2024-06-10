module FloatRounding(normMant,normExp,R,S,Clock,roundMant,roundExp,valid,Reset);
parameter n = 24;
parameter exp = 8;
input logic [n-1:0] normMant;
input logic [exp-1:0] normExp; 
input logic R;
input logic Reset;
input logic S;
input logic Clock;
output logic [n-1:0] roundMant;
output logic [exp-1:0]  roundExp;
output bit valid;

  always_ff @(posedge Clock)
    begin
      if(Reset)
        begin
          valid <=0;
          roundMant <=0;
          roundExp <=0;
        end
      else
      begin
      if (normMant[0] && R)
        begin
        valid <= 1;
        roundMant <= normMant+1'b1; // Round up 
        end
      else if(R&&S)
        begin
          valid <= 1;
          roundMant <= normMant+1'b1; // Round up 
        end
      else
        begin
        valid <= 0;
        roundMant <= normMant; // Round down
        end
      roundExp <= normExp;
      end
    end
endmodule
