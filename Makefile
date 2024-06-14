TB = src/tbfpadder.sv
FPADDER_MOCK = src/fpadder_mock.sv

.PHONY: ffo mock all

all:
	vlog src/addsub.sv src/barrelshifter.sv src/findfirstone.sv src/floatingpoint.sv src/floatround.sv src/fpclass.sv src/fulladder.sv src/n2to1mux.sv src/rightshifter.sv src/floatingpointadder.sv src/tbfpadder.sv src/checkspecial.sv
	vsim -c top -do "coverage save -onexit covrpt" -do "run -all"

mock:
	vlog src/fpclass.sv $(TB) $(FPADDER_MOCK)
	vsim -c top -do "run -all"

ffo:
	vlog src/findfirstone.sv src/tbfindfirstone.sv
	vsim -G/top/N=8 -c top -do "run -all"
