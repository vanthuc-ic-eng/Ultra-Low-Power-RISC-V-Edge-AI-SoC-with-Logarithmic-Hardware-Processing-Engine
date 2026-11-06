// ============================================================================
// File: pulp_hwpe_pkg.sv
// Project: PULP-inspired Edge AI SoC for Handwritten Digit Recognition
// Package: pulp_hwpe_pkg
// Author: Nguyen Van Thuc (24161421)
// Description:
//   Global architectural constants, typed enums, and data types for the
//   PULP-inspired Logarithmic Approximate HWPE (LA-HWPE) Edge AI Accelerator.
// ============================================================================

package pulp_hwpe_pkg;

    // Network Topology Parameters
    localparam int unsigned L1_INPUT_DIM   = 784;
    localparam int unsigned L1_NEURONS     = 64;
    localparam int unsigned L2_NEURONS     = 10;
    localparam int unsigned L2_NEURONS_PAD = 12;
    localparam int unsigned PE_COUNT       = 4;
    localparam int unsigned SHIFT_BITS     = 11;
    localparam int unsigned PRE_ENC_W_WIDTH = 12;
    localparam int unsigned WEIGHT_BUS_WIDTH = 48; // 4 x 12-bit pre-encoded log weights

    // Memory Depths
    localparam int unsigned WEIGHT_MEM_DEPTH = 16384;
    localparam int unsigned IN_MEM_DEPTH     = 1024;
    localparam int unsigned HIDDEN_MEM_DEPTH = 64;

    // Stream Controller FSM State Enum
    typedef enum logic [3:0] {
        ST_IDLE          = 4'd0,
        ST_L1_LOAD_BIAS  = 4'd1,
        ST_L1_STREAM     = 4'd2,
        ST_L1_DRAIN      = 4'd3,
        ST_L1_WRITEBACK  = 4'd4,
        ST_L2_LOAD_BIAS  = 4'd5,
        ST_L2_STREAM     = 4'd6,
        ST_L2_DRAIN      = 4'd7,
        ST_DONE          = 4'd8
    } fsm_state_e;

endpackage : pulp_hwpe_pkg
