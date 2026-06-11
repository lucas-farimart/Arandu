//=====================================================================
// Dupla de Stack de neuronios para processamento MxV
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   01/06/2026
//=====================================================================

module dual_neuron_stack #(
    parameter WORD_W = 32,
    parameter DEPTH  = 16,
    parameter ADDR_W = $clog2(DEPTH+1)
)(
    input  logic  clk,
    input  logic  rst_n,

    //------------------------------ Controle 
    input  logic  push_a_i,        
    input  logic  pop_a_i,         
    input  logic  rc_push_a_i, 
    input  logic  rc_pop_a_i,  

    input  logic  push_b_i,
    input  logic  pop_b_i,
    input  logic  rc_push_b_i,
    input  logic  rc_pop_b_i,

    //--------------------------------- Dados 
    input  logic  [WORD_W-1:0] data_a_i,
    input  logic  [WORD_W-1:0] data_b_i,
    output logic  [WORD_W-1:0] data_a_o,
    output logic  [WORD_W-1:0] data_b_o,

    //-------------------------------- Status 
    output logic  full_a_o,
    output logic  full_b_o,
    output logic  empty_a_o,
    output logic  empty_b_o
);

    //-----------------------------------------------------------------
    // Internos
    //-----------------------------------------------------------------
    // logic rc_push_a_r, rc_pop_a_r;
    // logic rc_push_b_r, rc_pop_b_r;
    logic [WORD_W-1:0] data_head_a, data_head_b;
    logic [WORD_W-1:0] data_tail_a, data_tail_b;

    //-----------------------------------------------------------------
    // Logica de saida
    //-----------------------------------------------------------------    
    // always_ff @(posedge clk or negedge rst_n) rc_push_a_r <= (rst_n) ? '0 : rc_push_a_i;
    // always_ff @(posedge clk or negedge rst_n) rc_push_b_r <= (rst_n) ? '0 : rc_push_b_i;
    // always_ff @(posedge clk or negedge rst_n) rc_pop_b_r  <= (rst_n) ? '0 : rc_pop_b_i;
    // always_ff @(posedge clk or negedge rst_n) rc_pop_a_r  <= (rst_n) ? '0 : rc_pop_a_i;

    always_comb begin
        case ({rc_push_a_i,rc_pop_a_i})
            2'b10:   data_a_o = data_tail_a;
            2'b01:   data_a_o = data_head_a;
            default: data_a_o = '0;
        endcase
    end

    always_comb begin
        case ({rc_push_b_i,rc_pop_b_i})
            2'b10:   data_b_o = data_tail_b;
            2'b01:   data_b_o = data_head_b;
            default: data_b_o = '0;
        endcase
    end

    //-----------------------------------------------------------------
    // Stack A
    //-----------------------------------------------------------------
    neuron_stack #(
        .WORD_W        ( WORD_W  ),
        .DEPTH         ( DEPTH   )
    ) a_stack (
        .clk           ( clk         ),
        .rst_n         ( rst_n       ),
        .push_i        ( push_a_i    ),
        .pop_i         ( pop_a_i     ),
        .recirc_push_i ( rc_push_a_i ),
        .recirc_pop_i  ( rc_pop_a_i  ),
        .data_i        ( data_a_i    ),
        .data_head_o   ( data_head_a ),
        .data_tail_o   ( data_tail_a ),
        .full_o        ( full_a_o    ),
        .empty_o       ( empty_a_o   )
    );

    //-----------------------------------------------------------------
    // Stack B
    //-----------------------------------------------------------------
    neuron_stack #(
        .WORD_W        ( WORD_W  ),
        .DEPTH         ( DEPTH   )
    ) b_stack (
        .clk           ( clk         ),
        .rst_n         ( rst_n       ),
        .push_i        ( push_b_i    ),
        .pop_i         ( pop_b_i     ),
        .recirc_push_i ( rc_push_b_i ),
        .recirc_pop_i  ( rc_pop_b_i  ),
        .data_i        ( data_b_i    ),
        .data_head_o   ( data_head_b ),
        .data_tail_o   ( data_tail_b ),
        .full_o        ( full_b_o    ),
        .empty_o       ( empty_b_o   )
    );

endmodule