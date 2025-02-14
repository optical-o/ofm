//-- driver.sv
//-- Copyright (C) 2022 CESNET z. s. p. o.
//-- Author(s): Daniel Kříž <xkrizd01@vutbr.cz>

//-- SPDX-License-Identifier: BSD-3-Clause

class driver#(CHANNELS) extends uvm_component;
    `uvm_component_param_utils(uvm_dma_up::driver #(CHANNELS))

    localparam MFB_META_WIDTH = sv_dma_bus_pack::DMA_REQUEST_LENGTH_W   + sv_dma_bus_pack::DMA_REQUEST_TYPE_W + sv_dma_bus_pack::DMA_REQUEST_FIRSTIB_W + 
                                sv_dma_bus_pack::DMA_REQUEST_LASTIB_W   + sv_dma_bus_pack::DMA_REQUEST_TAG_W + sv_dma_bus_pack::DMA_REQUEST_UNITID_W   + 
                                sv_dma_bus_pack::DMA_REQUEST_GLOBAL_W   + sv_dma_bus_pack::DMA_REQUEST_VFID_W + sv_dma_bus_pack::DMA_REQUEST_PASID_W   + 
                                sv_dma_bus_pack::DMA_REQUEST_PASIDVLD_W + sv_dma_bus_pack::DMA_REQUEST_RELAXED_W;

    uvm_seq_item_pull_port #(uvm_logic_vector_array::sequence_item #(32), uvm_logic_vector_array::sequence_item #(32)) seq_item_port_logic_vector_array;
    uvm_seq_item_pull_port #(uvm_ptc_info::sequence_item, uvm_ptc_info::sequence_item)     seq_item_port_info;

    mailbox #(uvm_logic_vector_array::sequence_item #(32))       logic_vector_array_export;
    mailbox #(uvm_logic_vector::sequence_item #(MFB_META_WIDTH)) logic_vector_export;

    uvm_logic_vector_array::sequence_item #(32) frame;
    uvm_ptc_info::sequence_item                 header_req;

    uvm_logic_vector_array::sequence_item #(32)       frame_new;
    uvm_logic_vector::sequence_item #(MFB_META_WIDTH) header_new;
    logic port;
    int write_cnt = 0;
    int read_cnt = 0;
    uvm_ptc_info::sync_tag tag_sync;

    // ------------------------------------------------------------------------
    // Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);

        seq_item_port_logic_vector_array = new("seq_item_port_logic_vector_array", this);
        seq_item_port_info        = new("seq_item_port_info", this);
        logic_vector_array_export = new(1);
        logic_vector_export       = new(1);
    endfunction

    // ------------------------------------------------------------------------
    // Starts driving signals to interface
    task run_phase(uvm_phase phase);
        logic [sv_dma_bus_pack::DMA_REQUEST_GLOBAL_W-1 : 0]  global_id;
        logic [sv_dma_bus_pack::DMA_REQUEST_LENGTH_W-1 : 0]  packet_size;
        logic [sv_dma_bus_pack::DMA_REQUEST_TYPE_W-1 : 0]    type_ide;
        logic [sv_dma_bus_pack::DMA_REQUEST_TAG_W-1 : 0]     tag;
        logic [sv_dma_bus_pack::DMA_REQUEST_FIRSTIB_W-1 : 0] firstib;
        logic [sv_dma_bus_pack::DMA_REQUEST_LASTIB_W-1 : 0]  lastib;
        logic [sv_dma_bus_pack::DMA_REQUEST_UNITID_W-1 : 0]  unitid;
        logic [sv_dma_bus_pack::DMA_REQUEST_VFID_W-1 : 0]    vfid;
        logic                                                pasid;
        logic                                                pasidvld;
        logic [sv_dma_bus_pack::DMA_REQUEST_RELAXED_W-1 : 0] relaxed;

        forever begin
            string debug_msg = "";
            // Get new sequence item to drive to interface
            seq_item_port_logic_vector_array.get_next_item(frame);
            seq_item_port_info.get_next_item(header_req);

            $cast(frame_new, frame.clone());
            header_new  = uvm_logic_vector::sequence_item #(MFB_META_WIDTH)::type_id::create("header_new");

            type_ide    = header_req.type_ide;
            firstib     = header_req.firstib;
            lastib      = header_req.lastib;

            if (type_ide == 1'b0) begin
                if (tag_sync.list_of_tags.size() != 128) begin
                    header_req.tag[7] = port; // top bit of tag is port
                    if (tag_sync.list_of_tags.size() != 0) begin 
                        while ((tag_sync.list_of_tags.exists(header_req.tag))) begin
                            void'(std::randomize(header_req.tag));
                            header_req.tag[7] = port;
                        end
                    end
                    tag         = header_req.tag;
                    tag_sync.add_element(tag);
                end else begin
                    tag         = header_req.tag;
                    type_ide = 1'b1;
                end
            end else
                tag         = header_req.tag;

            // TODO random unitid (for each unitid is set of tags)
            // unitid      = header_req.unitid;
            unitid      = 8'b10000000;
            global_id   = header_req.global_id;
            vfid        = {header_req.vfid[8-1 : 1], port};
            pasid       = header_req.pasid;
            pasidvld    = header_req.pasidvld;
            relaxed     = header_req.relaxed;
            if (type_ide == 1'b1) begin
                packet_size = frame_new.data.size(); // Size in DWORDS
                write_cnt++;
            end else begin
                packet_size = header_req.length;
                read_cnt++;
            end

            header_new.data = {relaxed, pasidvld, pasid, vfid, global_id, unitid, tag, lastib, firstib, type_ide, packet_size};

            if (type_ide == 1'b0) begin
                $swrite(debug_msg, "%s\n\t Generated RQ MVB read request number %d: %s\n", debug_msg, read_cnt, header_new.convert2string());
            end
            if (type_ide == 1'b1) begin
                $swrite(debug_msg, "%s\n\t Generated RQ MVB write request number %d: %s\n", debug_msg, write_cnt, header_new.convert2string());
                $swrite(debug_msg, "%s\n\t Generated RQ write MFB: %s\n", debug_msg, frame_new.convert2string());
            end

            $swrite(debug_msg, "%s\n\t Deparsed RQ MVB TR port %d:\n", debug_msg, port);

            $swrite(debug_msg, "%s\n\t PACKET SIZE:      %d", debug_msg, packet_size);
            $swrite(debug_msg, "%s\n\t TYPE ID:          %h", debug_msg, type_ide);
            $swrite(debug_msg, "%s\n\t RELAXED:          %h", debug_msg, relaxed);
            $swrite(debug_msg, "%s\n\t PASIDVLD:         %h", debug_msg, pasidvld);
            $swrite(debug_msg, "%s\n\t PASID:            %h", debug_msg, pasid);
            $swrite(debug_msg, "%s\n\t VFID:             %h", debug_msg, vfid);
            $swrite(debug_msg, "%s\n\t GLOBAL ID:        %h", debug_msg, global_id);
            $swrite(debug_msg, "%s\n\t UNITID:           %h", debug_msg, unitid);
            $swrite(debug_msg, "%s\n\t LASTIB:           %h\n", debug_msg, lastib);

            `uvm_info(this.get_full_name(), debug_msg ,UVM_MEDIUM);

            if (type_ide == 1'b1) begin
                logic_vector_array_export.put(frame_new);
            end
            logic_vector_export.put(header_new);

            seq_item_port_logic_vector_array.item_done();
            seq_item_port_info.item_done();
        end
    endtask

endclass

