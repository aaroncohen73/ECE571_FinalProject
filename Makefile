.PHONY: ffo

ffo:
	vlog src/findfirstone.sv src/tbfindfirstone.sv
	vsim -G/top/N=8 -c top -do "run -all"
