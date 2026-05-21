//=====================================================================
// Arandu Top: Core + S Buffers
//   Cada NPU possui sua propria stack esparsa. Os zeros sao 
//   automaticamente descartados pela stack.
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   20/05/2026
//=====================================================================

module arandu (
    port_list
);
    
    parameter NPU    = 1;
    parameter DATA_W = 8;
    parameter DEPTH  = 64;

    logic clk,
    logic rst_n,

    // BUS INPUT & STACK CONTROL
    logic                     bus_valid,
    logic   [$clog2(NPU)-1:0] bus_dest,
    logic signed [DATA_W-1:0] bus_x,
    logic signed [DATA_W-1:0] bus_w0,
    logic signed [DATA_W-1:0] bus_w1,
    logic signed [DATA_W-1:0] bus_w2,
    logic signed [DATA_W-1:0] bus_w3,
    logic           [NPU-1:0] pop_stack,

    // DEBUG/STATUS
    logic           [NPU-1:0] stack_empty,
    logic           [NPU-1:0] stack_full,
    logic        [DATA_W-1:0] zero_count  [NPU-1:0],
    logic               [6:0] stack_level [NPU-1:0],

    // NPU 
    logic signed       [31:0] acc0 [NPU-1:0],
    logic signed       [31:0] acc1 [NPU-1:0],
    logic signed       [31:0] acc2 [NPU-1:0],
    logic signed       [31:0] acc3 [NPU-1:0]

    //=========================================
    //  Sinais da requantizacao
    //=========================================
    logic signed [31:0] acc0, 
    logic signed [31:0] acc1, 
    logic signed [31:0] acc2, 
    logic signed [31:0] acc3;
    
    logic signed [7:0]  q0;
    logic signed [7:0]  q1;
    logic signed [7:0]  q2;
    logic signed [7:0]  q3;

    //=========================================================
    //  PROCESSING CORE
    //=========================================================
    arandu_core #(
        .NPU            ( NPU           ),    
        .DATA_W         ( DATA_W        ), 
        .DEPTH          ( DEPTH         )
    ) core_u (
        .clk            ( clk           ),
        .rst_n          ( rst_n         ),
        .bus_valid      ( bus_valid     ),
        .bus_dest       ( bus_dest      ),
        .bus_x          ( bus_x         ),
        .bus_w0         ( bus_w0        ),
        .bus_w1         ( bus_w1        ),
        .bus_w2         ( bus_w2        ),
        .bus_w3         ( bus_w3        ),
        .pop_stack      ( pop_stack     ),
        .stack_empty    ( stack_empty   ),
        .stack_full     ( stack_full    ),
        .zero_count     ( zero_count    ),
        .stack_level    ( stack_level   ), 
        .acc0           ( acc0          ), 
        .acc1           ( acc1          ), 
        .acc2           ( acc2          ), 
        .acc3           ( acc3          ) 
    )

    //=========================================================
    //  Requantizer for activations
    //=========================================================
    requant_unit #(
        .OUTPUTS  (     4     ),
        .SHIFT    (     7     )
    ) reqnt_u (
        .acc0_i   ( acc0      ),
        .acc1_i   ( acc1      ),
        .acc2_i   ( acc2      ),
        .acc3_i   ( acc3      ),
        .q0_o     ( q0        ),
        .q1_o     ( q1        ),
        .q2_o     ( q2        ),
        .q3_o     ( q3        )
    );

endmodule