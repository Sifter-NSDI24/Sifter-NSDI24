import cocotb
import sifter_tb


@cocotb.test(timeout_time = 300, timeout_unit = 'us')
async def smallFlows(dut):
    tb = sifter_tb.SifterTb(dut)
    await tb.run()
