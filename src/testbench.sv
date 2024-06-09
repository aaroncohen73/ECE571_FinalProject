module top;
import floatingpoint::*;

float Op1,Op2,Result;
logic InputValid,ResultValid,Reset;
bit Clock;

FloatAdder U1 (Op1,Op2,InputValid,Result,ResultValid,Clock,Reset);

initial
begin
  $display("staring clock");
  forever
    #5 Clock = ~Clock;
end
initial
begin
  $monitor("Clock %b Op1: %g Op2: %g Result: %g ResultValid %b",Clock,Op1,Op2,Result,ResultValid); 
  #10
  $display("Starting");
  repeat(1)@(negedge Clock);
  Reset = 1;
  $display("Resetting");
  repeat(1)@(negedge Clock);
  Reset = 0;
  repeat(1)@(negedge Clock);
    Op1 = ShortrealToFloat(4.5);  
    Op2 = ShortrealToFloat(2.5); 
    InputValid = 1;
  repeat(2)@(posedge Clock);
#10
$finish;
end
endmodule


