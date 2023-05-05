import cocotb
from cocotb.handle import SimHandleBase
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles, Join
from cocotb.types import concat, LogicArray, Range

g_PKT_LEN_BIT_WIDTH = 11
FIN_TIME_BIT_WIDTH  = 20
FLOW_ID_BIT_WIDTH   = 10
g_PKT_ID_BIT_WIDTH  = 16
DESC_BIT_WIDTH = g_PKT_LEN_BIT_WIDTH + FIN_TIME_BIT_WIDTH + FLOW_ID_BIT_WIDTH + \
                    g_PKT_ID_BIT_WIDTH

class SifterTb():
    enq_cnt  = 0
    deq_cnt  = 0
    ovfl_cnt = 0
    def __init__(self, dut: SimHandleBase, enq_in_file, deq_ctl_file, deq_out_file): 
        self.dut = dut
        self.clk_rst_init = self.ClkRstInit(self.dut)
        self.enq = self.Enqueue(self.dut, enq_in_file)
        self.deq = self.Dequeue(self.dut, deq_ctl_file, deq_out_file)
        self.ovfl = self.Overflow(self.dut)

    async def run(self):
        await self.clk_rst_init.start()
        enq_proc = cocotb.start_soon(self.enq.enq())
        deq_proc = cocotb.start_soon(self.deq.deq())
        ovfl_mon = cocotb.start_soon(self.ovfl.mon())

        enq_rslt = await Join(enq_proc)
        print('enq cnt = ', SifterTb.enq_cnt)
        deq_rslt = await Join(deq_proc)
        print('deq cnt = ', SifterTb.deq_cnt)
        print('ovfl cnt = ', SifterTb.ovfl_cnt)

        assert SifterTb.enq_cnt == SifterTb.deq_cnt + SifterTb.ovfl_cnt, f"# enq: {SifterTb.enq_cnt} != # deq: {SifterTb.deq_cnt} + # ovfl: {SifterTb.ovfl_cnt}"

    class ClkRstInit():
        def __init__(self, dut):
            self.dut = dut
            self.dut.rst.value = 0
            self.dut.enq_cmd.value = 0
            self.dut.deq_cmd.value = 0

        async def start(self):
            # Clock
            clk = Clock(self.dut.clk, 2.857, 'ns')
            await cocotb.start(clk.start())
            # Reset pulse
            await RisingEdge(self.dut.clk)
            self.dut.rst.value = 1
            await RisingEdge(self.dut.clk)
            self.dut.rst.value = 0


    class Enqueue():
        def __init__(self, dut, enq_in_file):
            self.dut = dut
            self.enq_in_file = enq_in_file

        async def enq(self):
            with open(self.enq_in_file) as f_enq_in:
                for line in f_enq_in:
                    # skip lines with comments
                    if len(line.strip().split()) == 6 and line[0] != '#':
                        cmd, delay, pkt_len, fin_time, flow_id, pkt_id = line.split()
                        print(cmd, delay, pkt_len, fin_time, flow_id, pkt_id)
                        # Wait for delay
                        await ClockCycles(self.dut.clk, int(delay))
                        # Wait for enq rdy
                        while(self.dut.enq_rdy.value == 0):
                            await RisingEdge(self.dut.clk)
                        # Drive enq desc 
                        desc_hi = concat(LogicArray(int(pkt_len), Range(g_PKT_LEN_BIT_WIDTH - 1, "downto", 0)), \
                                LogicArray(int(fin_time), Range(FIN_TIME_BIT_WIDTH - 1, "downto", 0)))
                        desc_lo = concat(LogicArray(int(flow_id), Range(FLOW_ID_BIT_WIDTH - 1, "downto", 0)) ,\
                                LogicArray(int(pkt_id), Range(g_PKT_ID_BIT_WIDTH - 1, "downto", 0)))
        
                        self.dut.enq_desc.value = concat(desc_hi, desc_lo)
                        self.dut.enq_cmd.value = 1
                        await RisingEdge(self.dut.clk) 
                        self.dut.enq_cmd.value = 0
                        SifterTb.enq_cnt += 1
                return True

    class Dequeue(): 
        def __init__(self, dut, deq_ctl_file, deq_out_file):
            self.dut = dut
            self.deq_ctl_file = deq_ctl_file
            self.deq_out_file = deq_out_file

        async def deq(self):
            f_deq_ctl = open(self.deq_ctl_file)
            with open(self.deq_out_file, 'w') as f_deq_out:
                for line in f_deq_ctl:
                    # skip lines with comments
                    if not line.strip() or line[0] != '#':
                        cmd, count = line.split()
                        # Wait for delay
                        if cmd == 'D':
                            await ClockCycles(self.dut.clk, int(count))
                        elif cmd == 'O':
                            for _ in range(int(count)):
                                # Wait for deq rdy
                                while(self.dut.deq_rdy.value == 0):
                                    await RisingEdge(self.dut.clk)
                                # Wait for valid
                                timeout = 0
                                while self.dut.deq_desc_valid == 0 and timeout < 5:
                                    await RisingEdge(self.dut.clk)
                                    timeout += 1
                                assert(timeout < 5)

                                # Pulse deq_cmd
                                self.dut.deq_cmd.value = 1
                                await RisingEdge(self.dut.clk) 
                                self.dut.deq_cmd.value = 0
                                await RisingEdge(self.dut.clk) 

                                deq_dat = LogicArray(self.dut.deq_desc.value, Range(DESC_BIT_WIDTH - 1, "downto", 0))
                                pkt_len = deq_dat[DESC_BIT_WIDTH - 1 : DESC_BIT_WIDTH - g_PKT_LEN_BIT_WIDTH].integer
                                fin_time = deq_dat[DESC_BIT_WIDTH - g_PKT_LEN_BIT_WIDTH - 1 : \
                                                   DESC_BIT_WIDTH - g_PKT_LEN_BIT_WIDTH - FIN_TIME_BIT_WIDTH].integer
                                flow_id = deq_dat[DESC_BIT_WIDTH - g_PKT_LEN_BIT_WIDTH - FIN_TIME_BIT_WIDTH - 1 : \
                                                  DESC_BIT_WIDTH - g_PKT_LEN_BIT_WIDTH - FIN_TIME_BIT_WIDTH - FLOW_ID_BIT_WIDTH].integer
                                pkt_id = deq_dat[DESC_BIT_WIDTH - g_PKT_LEN_BIT_WIDTH - FIN_TIME_BIT_WIDTH - FLOW_ID_BIT_WIDTH - 1 : \
                                                 DESC_BIT_WIDTH - g_PKT_LEN_BIT_WIDTH - FIN_TIME_BIT_WIDTH - FLOW_ID_BIT_WIDTH - g_PKT_ID_BIT_WIDTH].integer
                                print(pkt_len, fin_time, flow_id, pkt_id)
                                f_deq_out.write('{} {} {} {}\n'.format(pkt_len, fin_time, flow_id, pkt_id)) 
                                f_deq_out.flush()
                                SifterTb.deq_cnt += 1
                    if SifterTb.enq_cnt > 0 and SifterTb.deq_cnt + SifterTb.ovfl_cnt == SifterTb.enq_cnt:
                        break
                f_deq_ctl.close()
                return True

    class Overflow(): 
        def __init__(self, dut):
            self.dut = dut

        async def mon(self):
            while True:
                SifterTb.ovfl_cnt += (self.dut.ovfl_out.value.integer + self.dut.ovfl_out_lvl.value.integer)
                await RisingEdge(self.dut.clk)

