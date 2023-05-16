/**
 *  @example enyx-hw-mmio-test/CMakeLists.txt
 *  @example enyx-hw-mmio-test/main.c
 */

#include <iostream>
#include <fstream>
#include <sstream>
#include <mutex>
#include <chrono>
#include <thread>
#include <cmath>

#include <enyx/hw/accelerator.hpp>
#include <enyx/hw/core.hpp>
#include <enyx/hw/core_tree.hpp>
#include <enyx/hw/core_descriptions.hpp>
#include <enyx/hw/register_io.hpp>
#include <enyx/hw/xml_file_locations.hpp>
#include <enyx/hw/mmio.hpp>


namespace h = enyx::hw;

const std::string TEST_NAME = "rand370";
const std::string DATA_DIR  = "../data/";
const std::string CORE_NAME = "nxuser_sandbox_smartnic";
const std::string BUS       = "0";
const int REG_OFFSET        = 4;
const int MM_ENQ_BUFFER     = 0x08000;
const int MM_ENQ_GAP_BUFFER = 0x10000;
const int MM_DEQ_BUFFER     = 0x18000;
const int MM_DEQ_TS_BUFFER  = 0x20000;
const int MM_OVFL_BUFFER    = 0x28000;

const int FIN_TIME_BIT_WIDTH = 20;
const int FLOW_ID_BIT_WIDTH  = 10;
const int PKT_ID_BIT_WIDTH   = 16;

static h::filter
make_acc_filter(std::string const & arg)
{
    try {
        size_t end;
        uint32_t bus_id = std::stol(arg, &end, 0);
        if (end != arg.length())
            throw std::exception{};
        return h::filter{h::index{bus_id}};
    } catch (std::exception &) {
        return h::filter{h::name{arg}};
    }
}

int main()
{
    auto acc_descr = h::enumerate_accelerators(make_acc_filter(BUS));
    if (acc_descr.size() != 1)
    {
        ::perror("enumerate_accelerators");
        return EXIT_FAILURE;
    }

    auto core_descriptions_result = enyx::hw::core_descriptions_from_xml(
            enyx::hw::DESCRIPTIONS_DEFAULT_LOCATION
    );
    if (! core_descriptions_result)
    {
        ::perror("cores_descriptions_from_xml");
        return EXIT_FAILURE;
    }
    auto descriptions = core_descriptions_result.v();

    auto hw_id_result = descriptions.get_hardware_id(CORE_NAME);
    if (! hw_id_result)
    {
        ::perror("No core descriptins with this core name");
        return EXIT_FAILURE;
    }

    auto acc = h::accelerator{acc_descr[0]};
    auto mmio = h::mmio{acc.enumerate_mmios()[0]};
    auto tree = h::enumerate_cores(mmio);
    auto root = tree.get_root();
    auto target_core = root.enumerate(hw_id_result.v()).at(0);
    std::int64_t target_core_base_addr = target_core.get_base_addr();

    // Reset core
    if (! target_core.reset())
    {
        ::perror("Could not reset node");
        return EXIT_FAILURE;
    }

    auto description = descriptions.find(target_core).v();

    // Open config file
    std::ifstream cstrm(DATA_DIR + TEST_NAME + ".conf");
    std::string   line;

    while(std::getline(cstrm, line))
    {
        std::cout << line << std::endl;
        std::stringstream   linestream(line);
	std::string         cmd;
	std::string         reg_name;
	int                 reg_value;

        linestream >> cmd >> reg_name >> reg_value;
        auto reg_r = description.find_register(reg_name);
        if (! reg_r)
        {
            ::perror("Could not find register in core descriptions");
            return EXIT_FAILURE;
        }
	
        // When variables accesses are dependent (e.g. a variable
        // is a page selection that change values of other variables)
        // the accesses need to be protected against concurrent accesses from
        // other processes or threads.
        //std::lock_guard<enyx::hw::core> lock{target_core};

	if (cmd == "W")
            enyx::hw::write(target_core, reg_r.v(), reg_value);
	else if (cmd == "R")
	{
            auto read_result = enyx::hw::read(target_core, reg_r.v());
            if (!read_result)
            {
                ::perror("Failed to read register ");
                return EXIT_FAILURE;
            }
            if (read_result.v() != reg_value)
                std::cout <<  "Register read error: Expecting: " << std::hex << reg_value 
		          <<  " Got: " << read_result.v()
                          << std::endl;
	}
	else
	    std::cout << "Unknown command: " << cmd
		      << std::endl;
    }
    cstrm.close();	    

    // Open Enqueue data file
    std::ifstream estrm(DATA_DIR + TEST_NAME + ".enq");

    // Create an unordered_map to store the input descriptors for later comparison against the dequeued descriptors
    //std::unordered_map<std::string, std::string> u = {
    //    {"RED","#FF0000"},
    //    {"GREEN","#00FF00"},
    //    {"BLUE","#0000FF"}
    //};

    int enq_cnt = 0;
    while(std::getline(estrm, line))
    {
        std::stringstream   linestream(line);
	std::string         cmd;
	int                 enq_gap;
	int                 pkt_len;
	int                 fin_time;
	int                 flow_id;
	int                 pkt_id;

        linestream >> cmd >> enq_gap >> pkt_len >> fin_time >> flow_id >> pkt_id;

	std::int64_t gap_addr = target_core_base_addr + (MM_ENQ_GAP_BUFFER + enq_cnt * 2 + REG_OFFSET) * 4;
        mmio.write_32(gap_addr, enq_gap);

        // Form enq desc 
	std::int64_t enq_addr_hi = target_core_base_addr + (MM_ENQ_BUFFER + enq_cnt * 2 + REG_OFFSET) * 4;
	std::int64_t enq_addr_lo = target_core_base_addr + (MM_ENQ_BUFFER + enq_cnt * 2 + REG_OFFSET + 1) * 4;
	std::int64_t desc = (std::int64_t(pkt_len) << (FIN_TIME_BIT_WIDTH + FLOW_ID_BIT_WIDTH + PKT_ID_BIT_WIDTH)) +
                            (std::int64_t(fin_time) << (FLOW_ID_BIT_WIDTH + PKT_ID_BIT_WIDTH)) +
                            (std::int64_t(flow_id)  << PKT_ID_BIT_WIDTH) +
                             std::int64_t(pkt_id);
        int desc_hi = desc >> 32;
        int desc_lo = (int)desc;
        mmio.write_32(enq_addr_hi, desc_hi);
        mmio.write_32(enq_addr_lo, desc_lo);
        enq_cnt += 1;
        //if int(flow_id) not in SifterTb.flow_enq:
        //    SifterTb.flow_enq[int(flow_id)] = [int(pkt_id)]
        //else:
        //    SifterTb.flow_enq[int(flow_id)].append(int(pkt_id))
    }

    estrm.close();	    
    std::cout << "Wrote " << enq_cnt << " descriptors to Enqueue buffer" << std::endl; 
    
    // Write number of enq descriptors
    auto reg_r = description.find_register("ENQ_MAX");
    if (! reg_r)
    {
        ::perror("Could not find register in core descriptions");
        return EXIT_FAILURE;
    }
    enyx::hw::write(target_core, reg_r.v(), enq_cnt);
    auto read_result = enyx::hw::read(target_core, reg_r.v());
    if (!read_result)
    {
        ::perror("Failed to read register ");
        return EXIT_FAILURE;
    }
    if (read_result.v() != enq_cnt)
        std::cout <<  "ENQ_MAX_CNT Register read error: Expecting: " << std::hex << enq_cnt
                  <<  " Got: " << read_result.v()
                  << std::endl;

    // Start Sifter
    reg_r = description.find_register("START");
    if (! reg_r)
    {
        ::perror("Could not find register in core descriptions");
        return EXIT_FAILURE;
    }
    enyx::hw::write(target_core, reg_r.v(), 1);
    read_result = enyx::hw::read(target_core, reg_r.v());
    if (!read_result)
    {
        ::perror("Failed to read register ");
        return EXIT_FAILURE;
    }
    if (read_result.v() != 0)
        std::cout <<  "START Register read error: Expecting: " << std::hex << 0 
                  <<  " Got: " << read_result.v()
                  << std::endl;
 
    // Wait 3 msec
    std::this_thread::sleep_for(std::chrono::milliseconds(3));

    // Read counts
    reg_r = description.find_register("ENQ_COUNT");
    if (! reg_r)
    {
        ::perror("Could not find register in core descriptions");
        return EXIT_FAILURE;
    }
    read_result = enyx::hw::read(target_core, reg_r.v());
    if (!read_result)
    {
        ::perror("Failed to read register ");
        return EXIT_FAILURE;
    }
    std::cout <<  "Enq count: " << std::dec << read_result.v() << std::endl;
                  
    reg_r = description.find_register("DEQ_COUNT");
    if (! reg_r)
    {
        ::perror("Could not find register in core descriptions");
        return EXIT_FAILURE;
    }
    read_result = enyx::hw::read(target_core, reg_r.v());
    if (!read_result)
    {
        ::perror("Failed to read register ");
        return EXIT_FAILURE;
    }
    int deq_cnt_max = read_result.v();
    std::cout <<  "Deq count: " << std::dec << read_result.v() << std::endl;

    reg_r = description.find_register("OVFL_COUNT");
    if (! reg_r)
    {
        ::perror("Could not find register in core descriptions");
        return EXIT_FAILURE;
    }
    read_result = enyx::hw::read(target_core, reg_r.v());
    if (!read_result)
    {
        ::perror("Failed to read register ");
        return EXIT_FAILURE;
    }
    int ovfl_cnt_max = read_result.v();
    std::cout <<  "Ovfl count: " << std::dec << read_result.v() << std::endl;

    // Open Dequeue output data file
    std::ofstream dstrm(DATA_DIR + TEST_NAME + ".deq");

    int deq_cnt = 0;
    // Read dequeued descriptors and write to output stream
    while(deq_cnt < deq_cnt_max)
    {
	std::int64_t ts_addr     = target_core_base_addr + (MM_DEQ_TS_BUFFER + deq_cnt * 2 + REG_OFFSET) * 4;
        auto deq_ts = mmio.read_32(ts_addr);
	std::int64_t deq_addr_hi = target_core_base_addr + (MM_DEQ_BUFFER + deq_cnt * 2 + REG_OFFSET) * 4;
        auto deq_desc_hi = mmio.read_32(deq_addr_hi);
	std::int64_t deq_addr_lo = target_core_base_addr + (MM_DEQ_BUFFER + deq_cnt * 2 + REG_OFFSET + 1) * 4;
        auto deq_desc_lo         = mmio.read_32(deq_addr_lo);

        // Form deq desc 
	std::int64_t deq_desc = ((std::int64_t)deq_desc_hi.v()) << 32 | (std::int64_t)deq_desc_lo.v();
	std::int32_t pkt_len  = deq_desc >> (FIN_TIME_BIT_WIDTH + FLOW_ID_BIT_WIDTH + PKT_ID_BIT_WIDTH);
	std::uint32_t mask = 0xFFFFFFFF >> (32 - FIN_TIME_BIT_WIDTH);
	std::int32_t fin_time = (deq_desc >> (FLOW_ID_BIT_WIDTH + PKT_ID_BIT_WIDTH)) & mask;
	mask = 0xFFFFFFFF >> (32 - FLOW_ID_BIT_WIDTH);
	std::int32_t flow_id  = (deq_desc >> PKT_ID_BIT_WIDTH) & mask;
	mask = 0xFFFFFFFF >> (32 - PKT_ID_BIT_WIDTH);
	std::int32_t pkt_id   = deq_desc & mask;
	dstrm << std::dec << deq_ts.v() << " " << pkt_len << " " << fin_time << " " << flow_id << " " << pkt_id << std::endl; 
        deq_cnt += 1;
    }

    dstrm.close();

    // Open Overflow output data file
    std::ofstream ostrm(DATA_DIR + TEST_NAME + ".ovfl");

    int ovfl_cnt = 0;
    // Read overflow descriptors and write to output stream
    while(ovfl_cnt < ovfl_cnt_max)
    {
	std::int64_t ovfl_addr_hi = target_core_base_addr + (MM_OVFL_BUFFER + ovfl_cnt * 2 + REG_OFFSET) * 4;
        auto ovfl_desc_hi = mmio.read_32(ovfl_addr_hi);
	std::int64_t ovfl_addr_lo = target_core_base_addr + (MM_OVFL_BUFFER + ovfl_cnt * 2 + REG_OFFSET + 1) * 4;
        auto ovfl_desc_lo         = mmio.read_32(ovfl_addr_lo);

        // Form ovfl desc 
	std::int64_t ovfl_desc = ((std::int64_t)ovfl_desc_hi.v()) << 32 | (std::int64_t)ovfl_desc_lo.v();
	std::int32_t pkt_len  = ovfl_desc >> (FIN_TIME_BIT_WIDTH + FLOW_ID_BIT_WIDTH + PKT_ID_BIT_WIDTH);
	std::uint32_t mask = 0xFFFFFFFF >> (32 - FIN_TIME_BIT_WIDTH);
	std::int32_t fin_time = (ovfl_desc >> (FLOW_ID_BIT_WIDTH + PKT_ID_BIT_WIDTH)) & mask;
	mask = 0xFFFFFFFF >> (32 - FLOW_ID_BIT_WIDTH);
	std::int32_t flow_id  = (ovfl_desc >> PKT_ID_BIT_WIDTH) & mask;
	mask = 0xFFFFFFFF >> (32 - PKT_ID_BIT_WIDTH);
	std::int32_t pkt_id   = ovfl_desc & mask;
	ostrm << std::dec << " " << pkt_len << " " << fin_time << " " << flow_id << " " << pkt_id << std::endl; 
        ovfl_cnt += 1;
    }

    ostrm.close();

    return EXIT_SUCCESS;
}
