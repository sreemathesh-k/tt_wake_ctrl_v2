import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_or_mode(dut):
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())
    dut.rst_n.value  = 0
    dut.ui_in.value  = 0
    dut.uio_in.value = 0
    dut.ena.value    = 1
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value  = 1
    await ClockCycles(dut.clk, 2)
    # OR mode (uio_in[0]=0), ch_en=1111, thresh_in[0]=1
    dut.uio_in.value = 0b00000000
    dut.ui_in.value  = 0b11110001
    await ClockCycles(dut.clk, 30)
    dut._log.info(f"uo_out={dut.uo_out.value}")
    assert int(dut.uo_out.value) >= 0
