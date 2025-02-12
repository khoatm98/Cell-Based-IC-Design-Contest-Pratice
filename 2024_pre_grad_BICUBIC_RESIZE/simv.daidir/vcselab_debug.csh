#!/bin/csh -f

cd /home/MingKe/Cell-Based-IC-Design-Contest-Pratice/ICC_2024_pre_grad_BICUBIC_RESIZE

#This ENV is used to avoid overriding current script in next vcselab run 
setenv SNPS_VCSELAB_SCRIPT_NO_OVERRIDE  1

/usr/cad/synopsys/vcs/cur/linux/bin/vcselab $* \
    -o \
    simv \
    -nobanner \

cd -

