# c4puter northbridge - support code
# Copyright (C) 2017 Chris Pavlina
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

COCOTB ?= $(PWD)/../../cocotb
SRCDIR := $(PWD)/../../modules

VERILOG_SOURCES := \
		$(SRCDIR)/flipflop/flipflop.v \
		$(SRCDIR)/limb_interface/limb_interface.v \
		$(SRCDIR)/wb_ram/wb_ram.v \
		./limb_test_top.v

TOPLEVEL = limb_test_top
MODULE  = test_limb_interface
EXTRA_ARGS = -I ${SRCDIR}

include $(COCOTB)/makefiles/Makefile.inc
include $(COCOTB)/makefiles/Makefile.sim
