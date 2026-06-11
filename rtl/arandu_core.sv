//=====================================================================
// Arandu Core: NPU Cluster + Sparse LIFO Buffers
//   Cada NPU possui sua propria stack esparsa. Os zeros sao 
//   automaticamente descartados pela stack.
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   11/05/2026
//=====================================================================

module arandu_core #(
    parameter NPU    = 1,
    parameter STACKS = 2,
    parameter DATA_W = 8,
    parameter WORD_W = 8,
    parameter DEPTH  = 16
)(
    input  logic clk,
    input  logic rst_n,
    input  logic neuron_done,    // All mults are done, full sum
    input  logic shift_buff,     // Shift activation stream buffer
    input  logic buff_select,    // Select between stack A and B
    input  logic input_write,    // Write input on stack B

    input  logic write_Abuff,    // Write commands for stacks A and B (push)
    input  logic write_Bbuff, 
    input  logic read_Abuff,     // Read commands for stacks A and B (pop)
    input  logic read_Bbuff,

    input  logic [31:0] mem_ctrl_data,
    input  logic        mem_ctrl_valid,

    // DEBUG/STATUS
    output logic  stackA_empty,
    output logic  stackB_empty,
    output logic  stackA_full,
    output logic  stackB_full
);

    //=========================================================
    // SIGNALS
    //=========================================================
    logic [31:0] actv_shiftbuff;
    logic [31:0] actv_buffselect;
    logic [31:0] stackA_data_in;
    logic [31:0] stackB_data_in;
    logic [31:0] neuron_pkt;

    logic [31:0] stackA_data_out;  // A-STACK OUTPUTS
    logic [31:0] stackB_data_out;  // B-STACK OUTPUTS
    logic        valid_in_npu ;    // NPU VALID
    logic        valid_out_npu;

    // NPU INPUTS/OUTPUTS
    logic signed [DATA_W-1:0] core_w0;
    logic signed [DATA_W-1:0] core_w1;
    logic signed [DATA_W-1:0] core_w2;
    logic signed [DATA_W-1:0] core_w3;

    logic signed [31:0] core_acc0;
    logic signed [31:0] core_acc1;
    logic signed [31:0] core_acc2;
    logic signed [31:0] core_acc3;

    //=========================================================
    // WEIGHTS/VALID ROUTING
    //=========================================================
    always_comb begin
        core_w3 = mem_ctrl_data[31:24]; 
        core_w2 = mem_ctrl_data[24:16];
        core_w1 = mem_ctrl_data[15:8];
        core_w0 = mem_ctrl_data[7:0];
    end

    //=========================================================
    // Activation 32b-to-8b Shift Buffer
    //=========================================================
    always_comb begin
        case (buff_select)
            1'b0: actv_buffselect = stackA_data_out;
            1'b1: actv_buffselect = stackB_data_out;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            actv_shiftbuff <= 'h0;
        else if (shift_buff) begin 
            actv_shiftbuff[31:24] <= actv_shiftbuff[24:16];
            actv_shiftbuff[24:16] <= actv_shiftbuff[15:8];
            actv_shiftbuff[15:8]  <= actv_shiftbuff[7:0];
            // actv_shiftbuff[7:0]   <= 'h0;
        end else 
            actv_shiftbuff <= actv_buffselect;
    end

    //=========================================================
    // NPU INSTANCE
    //=========================================================
    npu #(
        .DATA_W    ( DATA_W            )
    ) npu_u (
        .clk       ( clk                   ),
        .rst_n     ( rst_n                 ),
        .valid_in  ( valid_in_npu          ),
        .valid_out ( valid_out_npu         ),
        .x         ( actv_shiftbuff[31:24] ),
        .w0        ( core_w0               ),
        .w1        ( core_w1               ),
        .w2        ( core_w2               ),
        .w3        ( core_w3               ),
        .acc0      ( core_acc0             ),
        .acc1      ( core_acc1             ),
        .acc2      ( core_acc2             ),
        .acc3      ( core_acc3             )
    );

    always_comb valid_in_npu = mem_ctrl_valid;
    //=========================================================
    //  Requantizer for activations
    //=========================================================
    requant_unit #(
        .OUTPUTS    ( NPU*4        ),
        .SHIFT      ( 7            )
    ) reqnt_u (
        .clk        ( clk          ),
        .rst_n      ( rst_n        ),
        .acc0_i     ( core_acc0    ),
        .acc1_i     ( core_acc1    ),
        .acc2_i     ( core_acc2    ),
        .acc3_i     ( core_acc3    ),
        .neuron_pkt ( neuron_pkt   )
    );

    //=========================================================
    // STACK A INSTANCE
    //=========================================================
    always_comb stackA_data_in = neuron_pkt;

    neuron_stack #(
        .WORD_W        ( WORD_W           ),
        .DEPTH         ( DEPTH            )
    ) stack_A (
        .clk           ( clk              ),
        .rst_n         ( rst_n            ),
        .push          ( write_Abuff      ),
        .pop           ( read_Abuff       ),
        .data_in       ( stackA_data_in   ),
        .data_out      ( stackA_data_out  ),
        .full          ( stackA_full      ),
        .empty         ( stackA_empty     )
    );

    //=========================================================
    // STACK B INSTANCE
    //=========================================================
    always_comb begin 
        case (input_write)
            1'b1: stackB_data_in = mem_ctrl_data;
            1'b0: stackB_data_in = neuron_pkt; 
        endcase
    end

    neuron_stack #(
        .WORD_W        ( WORD_W           ),
        .DEPTH         ( DEPTH            )
    ) stack_B (
        .clk           ( clk              ),
        .rst_n         ( rst_n            ),
        .push          ( write_Bbuff      ),
        .pop           ( read_Bbuff       ),
        .data_in       ( stackB_data_in   ),
        .data_out      ( stackB_data_out  ),
        .full          ( stackB_full      ),
        .empty         ( stackB_empty     )
    );

endmodule