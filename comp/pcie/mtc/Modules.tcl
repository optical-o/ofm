# Modules.tcl: Components include script
# Copyright (C) 2019 CESNET z. s. p. o.
# Author(s): Jakub Cabal <cabal@cesnet.cz>
#
# SPDX-License-Identifier: BSD-3-Clause

# Set paths

# Paths to components
set CONVERTORS_BASE           "$OFM_PATH/comp/pcie/convertors"
set SDP_BRAM_BASE             "$OFM_PATH/comp/base/mem/sdp_bram"
set MI_PIPE_BASE              "$OFM_PATH/comp/mi_tools/pipe"
set PIPE_BASE                 "$OFM_PATH/comp/base/misc/pipe"
set MFB_PIPE_BASE             "$OFM_PATH/comp/mfb_tools/flow/pipe"
set MFB_TRANSFORMER_BASE      "$OFM_PATH/comp/mfb_tools/flow/transformer"
set PCIE_HDR_GEN_BASE         "$OFM_PATH/comp/pcie/others/hdr_gen"

# Packages
lappend PACKAGES "$OFM_PATH/comp/base/pkg/math_pack.vhd"
lappend PACKAGES "$OFM_PATH/comp/base/pkg/type_pack.vhd"

# list of subcomponents
lappend COMPONENTS [ list "SDP_BRAM"                 $SDP_BRAM_BASE             "FULL" ]
lappend COMPONENTS [ list "PIPE"                     $PIPE_BASE                 "FULL" ]
lappend COMPONENTS [ list "MI_PIPE"                  $MI_PIPE_BASE              "FULL" ]
lappend COMPONENTS [ list "MFB_PIPE"                 $MFB_PIPE_BASE             "FULL" ]
lappend COMPONENTS [ list "MFB_TRANSFORMER"          $MFB_TRANSFORMER_BASE      "FULL" ]
lappend COMPONENTS [ list "PCIE_HDR_GEN"             $PCIE_HDR_GEN_BASE         "FULL" ]
lappend COMPONENTS [ list "CONVERTORS"               $CONVERTORS_BASE           "FULL" ]

# entity and architecture
lappend MOD "$ENTITY_BASE/mtc.vhd"
lappend MOD "$ENTITY_BASE/mtc_wrapper.vhd"
