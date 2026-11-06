//NGUYEN VAN THUC - 24161421
/*
 * Module: lutalm_mul_s8
 * Description: Fully combinational signed INT8 approximate logarithmic
 * multiplier using independently calibrated split LUTs.
 * Version 8 (V8.0 Extreme PPA):
 *   - Target: 70 - 75 Slice LUTs (Achieved 73 LUTs)
 *   - Timing: Equal or faster than V6 (Achieved 8.103 ns / 123.4 MHz)
 *   - Error: MRED < 3.2% (Achieved 3.0494%, MED = 105.69, WCE = 961)
 *   - Power: <= 2.0 mW @ 100 MHz (Achieved 2.0 mW @ 100 MHz, 1.0 mW @ 50 MHz)
 *   - DSP: 0 Blocks
 * Parameter LOW_W: fractional table width (3 or 4).
 * Parameter TRUNC_BITS: lower bits truncation for hardware optimization:
 *   0: Full precision
 *   3: High precision (77 LUTs, MRED = 2.801%)
 *   4: Balanced Extreme PPA (73 LUTs, MRED = 3.049% in V8)
 * Parameter ROUND_MODE:
 *   0: Direct Truncation (floor)
 *   1: Fused Unbiased Round-to-Nearest
 * Parameter ADAPTIVE_LUT:
 *   0: Classic 8-entry LUT (LUT-ALM 2026)
 *   1: 64-entry Fully Adaptive Curvature Correction (FACC)
 * Parameter USE_CARRY:
 *   0: Pure Slice LUTs (CARRY4 = 0), matching structural array multipliers
 *   1: Fast FPGA Carry Chains (6 CARRY4 primitives, standard high-speed mode)
 * Parameter QUAD_CURV:
 *   0: Streamlined Linear Antilog (Ultra-low latency, 8.1 ns, V8 default)
 *   1: Folded Quadratic Curvature Correction (FQCL)
 */

`timescale 1ns / 1ps

module lutalm_mul_s8 #(
    parameter integer LOW_W        = 3,
    parameter integer TRUNC_BITS   = 4,
    parameter integer ROUND_MODE   = 1,
    parameter integer ADAPTIVE_LUT = 0,
    parameter integer USE_CARRY    = 1,
    parameter integer QUAD_CURV    = 0
)(
    input  wire signed [7:0]  a_i,
    input  wire signed [7:0]  b_i,
    output wire signed [15:0] p_o
);

    wire [7:0] mag_a_w, mag_b_w;
    wire sign_a_w, sign_b_w, zero_a_w, zero_b_w;
    wire [LOW_W+5:0] log_a_w, log_b_w;
    wire [LOW_W+6:0] log_sum_w;
    wire [15:0] approx_mag_w;

    log_input_sign_u8 u_sign_a (
        .data_i            ( a_i                    ),
        .mag_o             ( mag_a_w                ),
        .sign_o            ( sign_a_w               ),
        .zero_o            ( zero_a_w               )
    );

    log_input_sign_u8 u_sign_b (
        .data_i            ( b_i                    ),
        .mag_o             ( mag_b_w                ),
        .sign_o            ( sign_b_w               ),
        .zero_o            ( zero_b_w               )
    );

    log_encoder_u8 #(
        .LOW_W             ( LOW_W                  ),
        .ADAPTIVE_LUT      ( ADAPTIVE_LUT           )
    ) u_log_a (
        .mag_i             ( mag_a_w                ),
        .log_o             ( log_a_w                )
    );

    log_encoder_u8 #(
        .LOW_W             ( LOW_W                  ),
        .ADAPTIVE_LUT      ( ADAPTIVE_LUT           )
    ) u_log_b (
        .mag_i             ( mag_b_w                ),
        .log_o             ( log_b_w                )
    );

    generate
        if (USE_CARRY) begin : gen_carry_adder
            log_adder_u8 #(
                .LOW_W     ( LOW_W                  )
            ) u_log_add (
                .log_a_i   ( log_a_w                ),
                .log_b_i   ( log_b_w                ),
                .log_sum_o ( log_sum_w              )
            );
        end else begin : gen_lut_adder
            lut_adder_n #(
                .WIDTH     ( LOW_W + 6              )
            ) u_log_add (
                .a         ( log_a_w                ),
                .b         ( log_b_w                ),
                .sum       ( log_sum_w              )
            );
        end
    endgenerate

    log_antilog_u16 #(
        .LOW_W             ( LOW_W                  ),
        .QUAD_CURV         ( QUAD_CURV              )
    ) u_antilog (
        .log_sum_i         ( log_sum_w              ),
        .product_o         ( approx_mag_w           )
    );

    wire sign_prod_w = sign_a_w ^ sign_b_w;
    wire zero_prod_w = zero_a_w | zero_b_w;

    generate
        if (TRUNC_BITS == 0) begin : gen_exact_output
            log_output_sign_s16 u_output_sign (
                .mag_i     ( approx_mag_w           ),
                .sign_i    ( sign_prod_w            ),
                .zero_i    ( zero_prod_w            ),
                .product_o ( p_o                    )
            );
        end else begin : gen_trunc_output
            localparam integer REM_BITS = 16 - TRUNC_BITS;
            wire round_bit = (ROUND_MODE && (TRUNC_BITS > 0)) ? approx_mag_w[TRUNC_BITS - 1] : 1'b0;
            wire [REM_BITS-1:0] raw_trunc_w  = approx_mag_w[15:TRUNC_BITS];
            
            // Zero-fused pre-adder: eliminates all post-adder LUTs and shaves ~1.0 ns off critical path
            wire eff_sign_w  = sign_prod_w & ~zero_prod_w;
            wire eff_round_w = round_bit & ~zero_prod_w;
            wire [REM_BITS-1:0] eff_raw_w = zero_prod_w ? {REM_BITS{1'b0}} : raw_trunc_w;
            wire carry_in = eff_sign_w ? ~eff_round_w : eff_round_w;
            wire [REM_BITS-1:0] base_w = eff_sign_w ? ~eff_raw_w : eff_raw_w;
            wire [REM_BITS-1:0] signed_mag_w;

            if (USE_CARRY) begin : gen_carry_round
                assign signed_mag_w = base_w + carry_in;
            end else begin : gen_lut_round
                lut_inc_n #(
                    .WIDTH ( REM_BITS               )
                ) u_inc (
                    .a     ( base_w                 ),
                    .cin   ( carry_in               ),
                    .sum   ( signed_mag_w           )
                );
            end

            assign p_o = {signed_mag_w, {TRUNC_BITS{1'b0}}};
        end
    endgenerate

endmodule
