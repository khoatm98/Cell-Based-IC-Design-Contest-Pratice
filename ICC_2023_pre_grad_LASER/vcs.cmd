#RTL simulation, single pattern
#vcs -R -sverilog tb.v LASER.v +define+P1+USECOLOR +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+LASER.fsdb
#vcs -full64 -R -sverilog tb.sv LASER.v +v2k  -debug_access+all +define+USECOLOR | tee sim.log
#RTL simulation, all pattern
#vcs -R -sverilog tb.sv LASER.v +define+USECOLOR +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+LASER.fsdb 

#Gate-Level simuation
vcs -full64 -R -sverilog tb.sv LASER_syn.v +define+USECOLOR+SDF +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+LASER.fsdb -v /home/raid7_2/course/cvsd/CBDK_IC_Contest_v2.5/Verilog/tsmc13_neg.v +maxdelays
