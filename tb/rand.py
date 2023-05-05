import cocotb
import sifter_tb

@cocotb.test(timeout_time = 2, timeout_unit = 'ms')
async def rand64(dut):
    tb = sifter_tb.SifterTb(dut)
    await tb.run()

@cocotb.test(timeout_time = 1, timeout_unit = 'ms')
async def rand320(dut):
    tb = sifter_tb.SifterTb(dut)
    await tb.run()

@cocotb.test(timeout_time = 3, timeout_unit = 'ms')
async def rand370(dut):
    tb = sifter_tb.SifterTb(dut)
    await tb.run()

@cocotb.test(timeout_time = 3, timeout_unit = 'ms')
async def rand460(dut):
    tb = sifter_tb.SifterTb(dut)
    await tb.run()
