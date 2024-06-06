TB = src/tbfpadder.sv
FPADDER_MOCK = src/fpadder_mock.sv

.PHONY: ffo mock

mock:
	vlog src/fpclass.sv $(TB) $(FPADDER_MOCK)
	vsim -c top -do "run -all"

ffo:
	vlog src/findfirstone.sv src/tbfindfirstone.sv
	vsim -G/top/N=8 -c top -do "run -all"
