/*
 * file       : monitor.sv
 * Copyright (C) 2021 CESNET z. s. p. o.
 * description: converting Intel mac seq into byte array
 * date       : 2021
 * author     : Radek Iša <isa@cesnet.cz>
 *
 * SPDX-License-Identifier: BSD-3-Clause
*/


class monitor_byte_array#(SEGMENTS) extends uvm_byte_array::monitor;
    `uvm_component_param_utils(uvm_byte_array_intel_mac_seg::monitor_byte_array#(SEGMENTS))

    uvm_analysis_imp #(uvm_intel_mac_seg::sequence_item #(SEGMENTS), monitor_byte_array#(SEGMENTS)) analysis_export;
    uvm_byte_array::sequence_item hl_tr;
    uvm_reset::sync_terminate reset_sync;

    typedef enum {FRAME, NO_FRAME} state_t;
    state_t state;
    byte unsigned data[$];

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
        analysis_export = new("analysis_export", this);
        reset_sync = new();
    endfunction

    virtual function void write(uvm_intel_mac_seg::sequence_item #(SEGMENTS) tr);
        //check if in past has been set reset
        if (reset_sync.has_been_reset()) begin
            state = NO_FRAME;
            data.delete();
        end

        if (tr.valid !== 1) begin
            return;
        end

        for (int unsigned it = 0; it < SEGMENTS; it++) begin
            //detection start of packet
            if (state == NO_FRAME && tr.inframe[it] == 1) begin
                state = FRAME;
                data.delete();
            end

            if (tr.inframe[it] == 1) begin
                for (int unsigned jt = 0; jt < 8; jt++) begin
                    data.push_back(tr.data[it][(jt+1)*8-1 -: 8]);
                end
            end

            //detection eof
            if (state == FRAME && tr.inframe[it] == 0) begin
                //get last bytes
                for (int unsigned jt = 0; jt < (8 - tr.eop_empty[it]); jt++) begin
                    data.push_back(tr.data[it][(jt+1)*8-1 -: 8]);
                end

                state = NO_FRAME;
                hl_tr = uvm_byte_array::sequence_item::type_id::create("hl_tr", this);
                hl_tr.data = data;
                analysis_port.write(hl_tr);
            end
        end
    endfunction

endclass

