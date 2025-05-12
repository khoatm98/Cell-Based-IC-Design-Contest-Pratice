#RTL simulation, pattern1
vcs  -full64 -R -debug_access+all +v2k +notimingcheck -sverilog tb.sv CONVEX.v +define+P1 +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+CONVEX.fsdb 

#Gate-Level simuation
vcs -full64 -R  -sverilog tb.sv CONVEX_syn.v +define+SDF +access+r +vcs+fsdbon +fsdb+mda +fsdbfile+CONVEX.fsdb -v /home/raid7_2/course/cvsd/CBDK_IC_Contest_v2.5/Verilog/tsmc13_neg.v +maxdelays +neg_tchk
vcs -f rtl_03.f -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk +define+P1 /home/raid7_2/course/cvsd/CBDK_IC_Contest_v2.5/Verilog/tsmc13_neg.v
