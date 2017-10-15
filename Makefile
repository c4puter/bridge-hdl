ISESETTINGS ?= /opt/Xilinx/14.7/ISE_DS/settings64.sh
SHELL := /bin/bash

.PHONY: test syn hdlmake clean mrproper

test:
	cd tb/test_limb_interface && make && gtkwave wf.gtkw

syn:
	source ${ISESETTINGS} && make -C syn/c4-0_ise

hdlmake:
	source ${ISESETTINGS} && cd syn/c4-0_ise && hdlmake

clean:
	-make -C tb/test_limb_interface clean
	-make -C syn/c4-0_ise clean

mrproper:
	-make -C syn/c4-0_ise mrproper
