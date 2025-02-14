//-- env.sv: Verification environment
//-- Copyright (C) 2021 CESNET z. s. p. o.
//-- Author(s): Tomáš Beneš <xbenes55@stud.fit.vutbr.cz>

//-- SPDX-License-Identifier: BSD-3-Clause 

// Environment for functional verification of encode.
// This environment containts two mii agents.
class env #(ITEM_WIDTH) extends uvm_env;

    `uvm_component_param_utils(uvm_asfifox::env #(ITEM_WIDTH));

    uvm_logic_vector_mvb::env_rx #(1, ITEM_WIDTH) rx_env;
    uvm_logic_vector_mvb::config_item cfg_rx;
    uvm_logic_vector_mvb::env_tx #(1, ITEM_WIDTH) tx_env;
    uvm_logic_vector_mvb::config_item cfg_tx;

    scoreboard #(ITEM_WIDTH) m_scoreboard;

    uvm_mvb::coverage #(1, ITEM_WIDTH) m_cover_rx;
    uvm_mvb::coverage #(1, ITEM_WIDTH) m_cover_tx;

    // Constructor of environment.
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // Create base components of environment.
    function void build_phase(uvm_phase phase);

        m_cover_rx = new("m_cover_rx");
        m_cover_tx = new("m_cover_tx");
        cfg_tx = new;
        cfg_rx = new;

        cfg_tx.active = UVM_ACTIVE;
        cfg_rx.active = UVM_ACTIVE;

        cfg_tx.interface_name = "vif_tx";
        cfg_rx.interface_name = "vif_rx";

        uvm_config_db #(uvm_logic_vector_mvb::config_item)::set(this, "tx_env", "m_config", cfg_tx);
        uvm_config_db #(uvm_logic_vector_mvb::config_item)::set(this, "rx_env", "m_config", cfg_rx);

        tx_env    = uvm_logic_vector_mvb::env_tx #(1, ITEM_WIDTH)::type_id::create("tx_env", this);
        rx_env    = uvm_logic_vector_mvb::env_rx #(1, ITEM_WIDTH)::type_id::create("rx_env", this);

        m_scoreboard  = scoreboard #(ITEM_WIDTH)::type_id::create("m_scoreboard", this);
    endfunction

    // Connect agent's ports with ports from scoreboard.
    function void connect_phase(uvm_phase phase);

        rx_env.analysis_port.connect(m_scoreboard.analysis_imp_mvb_rx);
        tx_env.analysis_port.connect(m_scoreboard.analysis_imp_mvb_tx);

        rx_env.m_mvb_agent.analysis_port.connect(m_cover_rx.analysis_export);
        rx_env.m_mvb_agent.analysis_port.connect(m_cover_tx.analysis_export);
    endfunction
endclass
