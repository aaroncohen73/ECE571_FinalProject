import floatingpoint::*;

module top;
int i;
logic [31:0] num[4];
initial
begin
shortreal testNum,testShort;
float floatNum; 
num[0] = '0;
num[1] = 32'h7F800000;
num[2] = 32'h006A4B76;
num[3] = 32'hFFFFFFFF;
testNum = 3.14;
floatNum = ShortrealToFloat(testNum);
testShort = FloatToShortreal(floatNum);
foreach(num[i])
begin
  if(IsZero(num[i]) == 1)
    $display("Number is zero");
  if(IsInf(num[i]) == 1)
    $display("Number is infinity");
  if(IsDenorm(num[i]) == 1)
    $display("Number is denormalized");
  if(IsNaN(num[i]) == 1)
    $display("Not a number");
  DisplayFloatComponents(num[i]);
end
$display("Shortreal value: %g",testShort);
$display("Shortreal to float Components");
DisplayFloatComponents(floatNum);
#1
$finish;
end
endmodule
