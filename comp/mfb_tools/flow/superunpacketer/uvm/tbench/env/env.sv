// env.sv: Verification environment
// Copyright (C) 2022 CESNET z. s. p. o.
// Author(s): Daniel Kříž <xkrizd01@vutbr.cz>

// SPDX-License-Identifier: BSD-3-Clause

// Environment for the functional verification.
class env #(MFB_REGIONS, MFB_REGION_SIZE, MFB_BLOCK_SIZE, MFB_ITEM_WIDTH, OUT_META_WIDTH, HEADER_SIZE, VERBOSITY, PKT_MTU, MIN_SIZE, OUT_META_MODE) extends uvm_env;
    `uvm_component_param_utils(uvm_superunpacketer::env #(MFB_REGIONS, MFB_REGION_SIZE, MFB_BLOCK_SIZE, MFB_ITEM_WIDTH, OUT_META_WIDTH, HEADER_SIZE, VERBOSITY, PKT_MTU, MIN_SIZE, OUT_META_MODE));

    uvm_logic_vector_array_mfb::env_rx #(MFB_REGIONS, MFB_REGION_SIZE, MFB_BLOCK_SIZE, MFB_ITEM_WIDTH, 0)              m_env_rx;
    uvm_logic_vector_array_mfb::env_tx #(MFB_REGIONS, MFB_REGION_SIZE, MFB_BLOCK_SIZE, MFB_ITEM_WIDTH, OUT_META_WIDTH) m_env_tx;
    uvm_logic_vector_mvb::env_tx       #(MFB_REGIONS, OUT_META_WIDTH)                                                  m_env_tx_mvb;

    driver#(OUT_META_WIDTH, HEADER_SIZE, VERBOSITY, PKT_MTU, MIN_SIZE, MFB_BLOCK_SIZE) m_driver;

    uvm_superunpacketer::virt_sequencer #(MFB_REGIONS, MFB_REGION_SIZE, MFB_BLOCK_SIZE, MFB_ITEM_WIDTH, OUT_META_WIDTH) vscr;

    uvm_reset::agent                               m_reset;
    uvm_superpacket_header::agent                  m_info_agent;
    uvm_superpacket_size::agent                    m_size_agent;
    uvm_logic_vector_array::agent#(MFB_ITEM_WIDTH) m_byte_array_agent;

    scoreboard #(HEADER_SIZE, VERBOSITY, OUT_META_WIDTH) sc;

    // Constructor of the environment.
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // Create base components of the environment.
    function void build_phase(uvm_phase phase);

        uvm_reset::config_item                  m_config_reset;
        uvm_logic_vector_array_mfb::config_item m_config_rx;
        uvm_logic_vector_array_mfb::config_item m_config_tx;
        uvm_logic_vector_mvb::config_item       m_config_mvb_tx;
        uvm_superpacket_header::config_item     m_info_agent_cfg;
        uvm_superpacket_size::config_item       m_size_agent_cfg;
        uvm_logic_vector_array::config_item     m_byte_array_agent_cfg;

        m_info_agent_cfg        = new();
        m_info_agent_cfg.active = UVM_ACTIVE;
        uvm_config_db #(uvm_superpacket_header::config_item)::set(this, "m_info_agent", "m_config", m_info_agent_cfg);
        m_info_agent = uvm_superpacket_header::agent::type_id::create("m_info_agent", this);

        m_size_agent_cfg        = new();
        m_size_agent_cfg.active = UVM_ACTIVE;
        uvm_config_db #(uvm_superpacket_size::config_item)::set(this, "m_size_agent", "m_config", m_size_agent_cfg);
        m_size_agent = uvm_superpacket_size::agent::type_id::create("m_size_agent", this);

        m_byte_array_agent_cfg        = new();
        m_byte_array_agent_cfg.active = UVM_ACTIVE;
        uvm_config_db #(uvm_logic_vector_array::config_item)::set(this, "m_byte_array_agent", "m_config", m_byte_array_agent_cfg);
        m_byte_array_agent   = uvm_logic_vector_array::agent#(MFB_ITEM_WIDTH)::type_id::create("m_byte_array_agent", this);

        m_config_reset                = new;
        m_config_reset.active         = UVM_ACTIVE;
        m_config_reset.interface_name = "vif_reset";

        uvm_config_db #(uvm_reset::config_item)::set(this, "m_reset", "m_config", m_config_reset);
        m_reset = uvm_reset::agent::type_id::create("m_reset", this);

        // Passing the virtual interfaces
        m_config_rx                = new;
        m_config_rx.active         = UVM_ACTIVE;
        m_config_rx.interface_name = "vif_rx";
        m_config_rx.meta_behav     = (OUT_META_MODE == 0) ? uvm_logic_vector_array_mfb::config_item::META_SOF : uvm_logic_vector_array_mfb::config_item::META_EOF;

        uvm_config_db #(uvm_logic_vector_array_mfb::config_item)::set(this, "m_env_rx", "m_config", m_config_rx);
        m_env_rx = uvm_logic_vector_array_mfb::env_rx#(MFB_REGIONS, MFB_REGION_SIZE, MFB_BLOCK_SIZE, MFB_ITEM_WIDTH, 0)::type_id::create("m_env_rx", this);

        m_config_tx                = new;
        m_config_tx.active         = UVM_ACTIVE;
        m_config_tx.interface_name = "vif_tx";
        m_config_tx.meta_behav     = (OUT_META_MODE == 0) ? uvm_logic_vector_array_mfb::config_item::META_SOF : uvm_logic_vector_array_mfb::config_item::META_EOF;


        uvm_config_db #(uvm_logic_vector_array_mfb::config_item)::set(this, "m_env_tx", "m_config", m_config_tx);
        m_env_tx = uvm_logic_vector_array_mfb::env_tx#(MFB_REGIONS, MFB_REGION_SIZE, MFB_BLOCK_SIZE, MFB_ITEM_WIDTH, OUT_META_WIDTH)::type_id::create("m_env_tx", this);

        m_config_mvb_tx                = new;
        m_config_mvb_tx.active         = UVM_ACTIVE;
        m_config_mvb_tx.interface_name = "vif_mvb_tx";

        uvm_config_db #(uvm_logic_vector_mvb::config_item)::set(this, "m_env_tx_mvb", "m_config", m_config_mvb_tx);
        m_env_tx_mvb = uvm_logic_vector_mvb::env_tx#(MFB_REGIONS, OUT_META_WIDTH)::type_id::create("m_env_tx_mvb", this);

        sc       = scoreboard#(HEADER_SIZE, VERBOSITY, OUT_META_WIDTH)::type_id::create("sc", this);
        m_driver = driver #(OUT_META_WIDTH, HEADER_SIZE, VERBOSITY, PKT_MTU, MIN_SIZE, MFB_BLOCK_SIZE)::type_id::create("m_driver", this);
        vscr     = uvm_superunpacketer::virt_sequencer#(MFB_REGIONS, MFB_REGION_SIZE, MFB_BLOCK_SIZE, MFB_ITEM_WIDTH, OUT_META_WIDTH)::type_id::create("vscr",this);

    endfunction

    // Connect agent's ports with ports from the scoreboard.
    function void connect_phase(uvm_phase phase);

        m_env_rx.analysis_port_data.connect(sc.input_data);
        m_env_tx.analysis_port_data.connect(sc.out_data);
        if (OUT_META_MODE == 2) begin
            m_env_tx_mvb.analysis_port.connect(sc.out_meta);
        end else
            m_env_tx.m_logic_vector_agent.analysis_port.connect(sc.out_meta);

        m_reset.sync_connect(m_env_rx.reset_sync);
        m_reset.sync_connect(m_env_tx.reset_sync);

        vscr.m_reset          = m_reset.m_sequencer;
        vscr.m_mfb            = m_env_tx.m_sequencer;
        vscr.m_mvb            = m_env_tx_mvb.m_sequencer;
        vscr.m_byte_array_scr = m_byte_array_agent.m_sequencer;
        vscr.m_info           = m_info_agent.m_sequencer;
        vscr.m_size           = m_size_agent.m_sequencer;

        m_driver.seq_item_port_header.connect(m_info_agent.m_sequencer.seq_item_export);
        m_driver.seq_item_port_sp_size.connect(m_size_agent.m_sequencer.seq_item_export);
        m_driver.seq_item_port_byte_array.connect(m_byte_array_agent.m_sequencer.seq_item_export);

    endfunction

    virtual task run_phase(uvm_phase phase);
        byte_array_sequence byte_array_seq;

        byte_array_seq           = byte_array_sequence::type_id::create("byte_array_seq", this);
        byte_array_seq.tr_export = m_driver.byte_array_export;
        byte_array_seq.randomize();

        fork
            byte_array_seq.start(m_env_rx.m_sequencer.m_data);
        join
    endtask

endclass
