import cocotb
import sifter_tb


@cocotb.test(timeout_time = 2, timeout_unit = 'us')
async def sifter_test1(dut):
    tb = sifter_tb.SifterTb(dut, 'enq_in.dat', 'deq_ctl.dat', 'deq_out.dat')
    await tb.run()
