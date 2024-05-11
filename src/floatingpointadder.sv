module FloatAdder(Op1, Op2, InputValid, Result, ResultValid, Clock, Reset);

import floatingpoint::*;

input  float Op1, Op2;
output float Result;

input  logic InputValid;
output logic ResultValid;

input logic Clock, Reset;

endmodule
