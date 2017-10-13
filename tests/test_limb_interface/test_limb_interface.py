# c4puter northbridge - simulations
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

from __future__ import print_function
import cocotb
from cocotb.triggers import Timer
from cocotb.result import TestFailure
import sys

CLK_HALF = 50
WB_CLK_HALF = 10

@cocotb.coroutine
def limb_clk_tick(dut, count=1):
    for i in range(count):
        dut.limb_clk = 0
        yield Timer(CLK_HALF)
        dut.limb_clk = 1
        yield Timer(CLK_HALF)

@cocotb.coroutine
def wb_clk_tick(dut, count=1):
    for i in range(count):
        dut.clk = 0
        yield Timer(WB_CLK_HALF)
        dut.clk = 1
        yield Timer(WB_CLK_HALF)

@cocotb.coroutine
def limb_send_addr(dut, addr):
    dut.limb_nrd = 1
    dut.limb_start = 1
    dut.limb_d_in = (addr & 0xff)
    yield limb_clk_tick(dut)
    dut.limb_start = 0
    dut.limb_d_in = (addr & 0xff00) >> 8
    yield limb_clk_tick(dut)
    dut.limb_d_in = (addr & 0xff0000) >> 16
    yield limb_clk_tick(dut)
    dut.limb_d_in = (addr & 0xff000000) >> 24
    yield limb_clk_tick(dut)
    dut.limb_d_in = (addr & 0xff00000000) >> 32
    yield limb_clk_tick(dut)

@cocotb.coroutine
def limb_send_data(dut, data):
    dut.limb_nrd = 1
    dut.limb_d_in = (data & 0xff)
    yield limb_clk_tick(dut)
    dut.limb_d_in = (data & 0xff00) >> 8
    yield limb_clk_tick(dut)
    dut.limb_d_in = (data & 0xff0000) >> 16
    yield limb_clk_tick(dut)
    dut.limb_d_in = (data & 0xff000000) >> 24
    yield limb_clk_tick(dut)

@cocotb.coroutine
def limb_get_data(dut, data, rx):
    dut.wb_dat_i = data
    yield wb_clk_tick(dut)
    dut.limb_nrd = 0
    yield limb_clk_tick(dut)
    while not int(dut.limb_nwait):
        dut.wb_ack_i = int(dut.wb_stb_o)
        yield wb_clk_tick(dut)
    dut.wb_ack_i = 0
    yield wb_clk_tick(dut)

    data_rx = int(dut.limb_d_out)

    yield limb_clk_tick(dut)
    data_rx |= (int(dut.limb_d_out) << 8)

    yield limb_clk_tick(dut)
    data_rx |= (int(dut.limb_d_out) << 16)

    yield limb_clk_tick(dut)
    data_rx |= (int(dut.limb_d_out) << 24)
    dut.limb_nrd = 1

    while not int(dut.limb_nwait):
        dut.wb_ack_i = int(dut.wb_stb_o)
        yield wb_clk_tick(dut)

    rx.append(data_rx)

@cocotb.test()
def test_limb_interface(dut):
    dut.limb_d_in = 0
    dut.limb_clk = 0
    dut.limb_nrd = 1
    dut.limb_start = 0
    dut.wb_dat_i = 0
    dut.wb_ack_i = 0
    dut.clk = 0
    dut.reset = 0

    yield Timer(CLK_HALF)
    yield limb_send_addr(dut, 0xBA9876543210)
    yield limb_send_data(dut, 0xDEADBEEF)
    yield wb_clk_tick(dut, 3)
    dut.wb_ack_i = 1
    yield wb_clk_tick(dut, 3)
    dut.wb_ack_i = 0
    yield limb_send_data(dut, 0xFEEDFACE)
    yield wb_clk_tick(dut, 3)
    dut.wb_ack_i = 1
    yield wb_clk_tick(dut, 3)
    dut.wb_ack_i = 0

    yield limb_send_addr(dut, 0xc0ffeec0ffee)
    yield limb_send_data(dut, 0x00c0ffee)
    yield wb_clk_tick(dut, 3)
    dut.wb_ack_i = 1
    yield wb_clk_tick(dut, 3)
    dut.wb_ack_i = 0

    data = []
    yield limb_send_addr(dut, 0xBA9876543210)
    yield limb_get_data(dut, 0x12345678, data)
    yield wb_clk_tick(dut, 25)
    print("%08X" % data[0])
