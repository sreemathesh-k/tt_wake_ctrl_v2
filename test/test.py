import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

@cocotb.test()
async def test_or_mode(dut):
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.ena.value = 1
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # OR mode, channel 0 enabled, thresh_in[0] high
    # ui_in[7:4]=1111 ch_en, ui_in[3:0]=0001 thresh
    dut.ui_in.value = 0b11110001
    await ClockCycles(dut.clk, 30)

    dut._log.info(f"uo_out = {dut.uo_out.value}")
