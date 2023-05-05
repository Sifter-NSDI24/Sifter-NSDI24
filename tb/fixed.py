import cocotb
import sifter_tb

@cocotb.test(timeout_time = 500, timeout_unit = 'us')
async def fixed64(dut):
    tb = sifter_tb.SifterTb(dut)
    await tb.run()

@cocotb.test(timeout_time = 500, timeout_unit = 'us')
async def fixed320(dut):
    tb = sifter_tb.SifterTb(dut)
    await tb.run()

@cocotb.test(timeout_time = 300, timeout_unit = 'us')
async def fixed352(dut):
    tb = sifter_tb.SifterTb(dut)
    await tb.run()

@cocotb.test(timeout_time = 3, timeout_unit = 'ms')
async def fixed370(dut):
    tb = sifter_tb.SifterTb(dut)
    await tb.run()

@cocotb.test(timeout_time = 3, timeout_unit = 'ms')
async def fixed460(dut):
    tb = sifter_tb.SifterTb(dut)
    await tb.run()
