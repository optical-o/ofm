//-- sequence.sv:  virtual sequence
//-- Copyright (C) 2022 CESNET z. s. p. o.
//-- Author(s): Radek Iša <isa@cesnet.cz>

//-- SPDX-License-Identifier: BSD-3-Clause 

class virt_seq#(PCIE_UP_REGIONS, PCIE_UP_REGION_SIZE, PCIE_UP_BLOCK_SIZE, PCIE_UP_ITEM_WIDTH, CHANNELS) extends uvm_sequence;
    `uvm_object_param_utils(test::virt_seq#(PCIE_UP_REGIONS, PCIE_UP_REGION_SIZE, PCIE_UP_BLOCK_SIZE, PCIE_UP_ITEM_WIDTH, CHANNELS))
    `uvm_declare_p_sequencer(uvm_dma_ll::sequencer#(PCIE_UP_REGIONS, PCIE_UP_REGION_SIZE, PCIE_UP_BLOCK_SIZE, PCIE_UP_ITEM_WIDTH, CHANNELS))

    function new (string name = "virt_seq");
        super.new(name);
    endfunction

    uvm_reset::sequence_start              m_reset;

    uvm_byte_array::sequence_lib m_packet;
    uvm_dma_ll_info::sequence_lib#(CHANNELS)  m_info;

    uvm_dma_ll::reg_sequence#(CHANNELS)     m_reg;
    uvm_sequence#(uvm_mfb::sequence_item #(PCIE_UP_REGIONS, PCIE_UP_REGION_SIZE, PCIE_UP_BLOCK_SIZE*PCIE_UP_ITEM_WIDTH/8, 8, 0)) m_pcie;

    virtual function void init(uvm_dma_ll::regmodel#(CHANNELS) m_regmodel);
        uvm_mfb::sequence_lib_tx#(PCIE_UP_REGIONS, PCIE_UP_REGION_SIZE, PCIE_UP_BLOCK_SIZE*PCIE_UP_ITEM_WIDTH/8, 8, 0) m_pcie_lib;

        m_reset = uvm_reset::sequence_start::type_id::create("rst_seq");

        m_packet = uvm_byte_array::sequence_lib::type_id::create("m_packet");
        m_packet.init_sequence();
        //m_packet.min_random_count = 1;
        //m_packet.max_random_count = 2;
        m_packet.min_random_count = 150;
        m_packet.max_random_count = 200;

        m_info   = uvm_dma_ll_info::sequence_lib#(CHANNELS)::type_id::create("m_info");
        m_info.init_sequence();
        m_info.min_random_count = 150;
        m_info.max_random_count = 200;

        m_reg    =  uvm_dma_ll::reg_sequence#(CHANNELS)::type_id::create("m_reg");
        m_reg.m_regmodel = m_regmodel;

        m_pcie_lib  = uvm_mfb::sequence_lib_tx#(PCIE_UP_REGIONS, PCIE_UP_REGION_SIZE, PCIE_UP_BLOCK_SIZE*PCIE_UP_ITEM_WIDTH/8, 8, 0)::type_id::create();
        m_pcie_lib.init_sequence();
        m_pcie = m_pcie_lib;
    endfunction

    virtual task run_mfb();
        forever begin
            assert(m_pcie.randomize());
            m_pcie.start(p_sequencer.m_pcie);
        end
    endtask

    virtual task run_reset();
        m_reset.randomize();
        m_reset.start(p_sequencer.m_reset);
    endtask

    function void pre_randomize();
         m_packet.randomize();
         m_reg.randomize();
    endfunction

    task body();
        fork
            run_reset();
            begin
                #(200ns)
                m_reg.start(null);
            end
        join_none

        fork
            m_packet.start(p_sequencer.m_packet.m_data);
            forever begin
                m_info.randomize();
                m_info.start(p_sequencer.m_packet.m_info);
            end
            run_mfb();
        join_any
    endtask
endclass
