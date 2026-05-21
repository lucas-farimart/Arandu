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
    parameter int NPU    = 1,
    parameter int DATA_W = 8,
    parameter int DEPTH  = 64
)(
    input  logic clk,
    input  logic rst_n,

    // BUS INPUT & STACK CONTROL
    input  logic                     bus_valid,
    input  logic   [$clog2(NPU)-1:0] bus_dest,
    input  logic signed [DATA_W-1:0] x,
    input  logic signed [DATA_W-1:0] w0,
    input  logic signed [DATA_W-1:0] w1,
    input  logic signed [DATA_W-1:0] w2,
    input  logic signed [DATA_W-1:0] w3,
    input  logic           [NPU-1:0] pop_stack,

    // DEBUG/STATUS
    output logic           [NPU-1:0] stack_empty,
    output logic           [NPU-1:0] stack_full,
    output logic        [DATA_W-1:0] zero_count  [NPU-1:0],
    output logic               [6:0] stack_level [NPU-1:0],

    // NPU OUTPUTS
    output logic signed       [31:0] acc0 [NPU-1:0],
    output logic signed       [31:0] acc1 [NPU-1:0],
    output logic signed       [31:0] acc2 [NPU-1:0],
    output logic signed       [31:0] acc3 [NPU-1:0]
);

    //=========================================================
    // SIGNALS
    //=========================================================
    logic           [NPU-1:0] push_stack;
    logic signed [DATA_W-1:0] stack_data_out   [NPU-1:0]; // STACK OUTPUTS
    logic                     valid_in_npu     [NPU-1:0]; // NPU VALID
    logic                     valid_out_unused [NPU-1:0];

    //=========================================================
    // VALID ROUTING
    //=========================================================
    always_comb begin
        push_stack = '0;
        if(bus_valid) push_stack[bus_dest] = 1'b1;
    end

    //=========================================================
    // NPU INSTANCES
    //=========================================================
    generate
    for(genvar g=0; g<NPU; g++) begin : GEN_NPU
        npu #(
            .DATA_W    ( DATA_W              )
        ) npu_u (
            .clk       ( clk                 ),
            .rst_n     ( rst_n               ),
            .valid_in  ( valid_in_npu[g]     ),
            .x         ( stack_data_out[g]   ),
            .w0        ( bus_w0              ),
            .w1        ( bus_w1              ),
            .w2        ( bus_w2              ),
            .w3        ( bus_w3              ),
            .valid_out ( valid_out_unused[g] ),
            .acc0      ( acc0[g]             ),
            .acc1      ( acc1[g]             ),
            .acc2      ( acc2[g]             ),
            .acc3      ( acc3[g]             )
        );
    end
    endgenerate

    generate  // VALID NPU: recebe valid quando ha pop
    for(genvar g=0; g<NPU; g++) begin : GEN_VALID
        always_comb valid_in_npu[g] = pop_stack[g] && !stack_empty[g];
    end
    endgenerate

    //=========================================================
    //  Requantizer for activations
    //=========================================================
    generate
    for(genvar g=0; g<NPU; g++) begin : GEN_RQNT
        requant_unit #(
            .OUTPUTS  ( NPU*4       ),
            .SHIFT    ( 7           )
        ) reqnt_u (
            .acc0_i   ( acc0[g]     ),
            .acc1_i   ( acc1[g]     ),
            .acc2_i   ( acc2[g]     ),
            .acc3_i   ( acc3[g]     ),
            .q0_o     ( q0[g]       ),
            .q1_o     ( q1[g]       ),
            .q2_o     ( q2[g]       ),
            .q3_o     ( q3[g]       )
        );
    end
    endgenerate

    //=========================================================
    // STACK INSTANCES
    //=========================================================
    generate
        for(genvar g=0; g<NPU; g++) begin : GEN_STACK
            neuron_stack #(
                .DATA_W        ( DATA_W             ),
                .DEPTH         ( DEPTH              )
            ) u_stack (
                .clk           ( clk                ),
                .rst_n         ( rst_n              ),
                .push          ( push_stack[g]      ),
                .pop           ( pop_stack[g]       ),
                .data_in       ( bus_x              ),
                .data_out      ( stack_data_out[g]  ),
                .full          ( stack_full[g]      ),
                .empty         ( stack_empty[g]     ),
                .level         ( stack_level[g]     )
            );
        end
    endgenerate

endmodule