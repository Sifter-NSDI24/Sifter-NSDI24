import cocotb
import sifter_tb


@cocotb.test(timeout_time = 10, timeout_unit = 'us')
async def sentinel_corner_case(dut):
    tb = sifter_tb.SifterTb(dut)
    await tb.run()
