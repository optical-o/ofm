// sequencer.sv: Virtual sequencer
// Copyright (C) 2022 CESNET z. s. p. o.
// Author(s): Daniel Kříž <xkrizd01@vutbr.cz>

// SPDX-License-Identifier: BSD-3-Clause


class virt_sequencer #(REGIONS, REGION_SIZE, BLOCK_SIZE, ITEM_WIDTH, META_WIDTH, MVB_DATA_WIDTH) extends uvm_sequencer;
    `uvm_component_param_utils(virt_sequencer #(REGIONS, REGION_SIZE, BLOCK_SIZE, ITEM_WIDTH, META_WIDTH, MVB_DATA_WIDTH))

    uvm_logic_vector_array::sequencer #(ITEM_WIDTH) m_byte_array_scr;
    uvm_header_type::sequencer                      m_info;

    function new(string name = "virt_sequencer", uvm_component parent);
        super.new(name, parent);
    endfunction

endclass
