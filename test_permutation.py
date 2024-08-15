import cocotb
from cocotb.clock import Clock, Timer
from cocotb.triggers import RisingEdge
from cocotb.utils import Decimal

@cocotb.test()
async def test_permutation(dut):
    clock = Clock(dut.i_clk, 10, units="us")
    cocotb.start_soon(clock.start(start_high=False))

    await Timer(Decimal(100), units='ns')

    dut.i_sponge.value = "8624da62e0ab31b597131a649f8b72478f73d4af34daf80506949c43fbb6f515"
    dut.i_trigger.value = 1

    for _ in range(10):
        dut.i_trigger.value = 0
        await RisingEdge(dut.i_clk)
        if dut.o_ready.value == 1:
            print("output: ", dut.o_sponge.value)
