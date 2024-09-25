#!/bin/csh -f

cd /home/raid7_2/user12/r2k41036/IC-Contest/ICC_2023_pre_grad_LASER

#This ENV is used to avoid overriding current script in next vcselab run 
setenv SNPS_VCSELAB_SCRIPT_NO_OVERRIDE  1

/usr/cad/synopsys/vcs/2022.06/linux64/bin/vcselab $* \
    -o \
    simv \
    -nobanner \

cd -

