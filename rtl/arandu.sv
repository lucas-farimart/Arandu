//=====================================================================
// Arandu Top: Core + Control
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   20/05/2026
// Update: 15/06/2026
//=====================================================================

module arandu #(
    parameter DATA_W = 8,
    parameter WORD_W = 32,
    parameter DEPTH  = 16,
    parameter CFG_INPUT  = 18,  
    parameter CFG_HIDDEN = 16,  
    parameter CFG_OUTPUT = 10,  
    parameter CFG_MODEL  = 8
)(
    input  logic        clk,
    input  logic        rst_n,

    input  logic        start_i,
    input  logic        done_o,

    input  logic [15:0] base_addr_i,
    output logic [15:0] dram_addr_o,
    input  logic [31:0] dram_rdata_i,
    input  logic        dram_valid_i,
    output logic        dram_req_o
);

    //=========================================================
    //  INTERNALS
    //=========================================================
    logic  input_write, neuron_enb;
    logic  [31:0] memctrl_data;
    logic  [7:0]  memctrl_byte;

    logic  stackA_push,    stackB_push; 
    logic  stackA_pop,     stackB_pop;
    logic  stackA_rcpush,  stackB_rcpush; 
    logic  stackA_rcpop,   stackB_rcpop;  
    logic  stackA_clean,   stackB_clean;  

    logic  stackA_empty;
    logic  stackB_empty;
    logic  stackA_full;
    logic  stackB_full;

    //=========================================================
    //  PROCESSING CORE
    //=========================================================
    arandu_core #(
        .DATA_W          ( DATA_W ),
        .WORD_W          ( WORD_W ),
        .DEPTH           ( DEPTH  )
    ) core_u (
        .clk             ( clk    ),
        .rst_n           ( rst_n  ),

        .neuron_enb_i    ( neuron_enb     ),
        .buff_select_i   ( buff_select    ),   
        .input_write_i   ( input_write    ),  

        .memctrl_data_i  ( memctrl_data   ),
        .memctrl_byte_i  ( memctrl_byte   ),

        .stackA_push_i   ( stackA_push    ), 
        .stackA_pop_i    ( stackA_pop     ),
        .stackA_rcpush_i ( stackA_rcpush  ), 
        .stackA_rcpop_i  ( stackA_rcpop   ),  
        .stackA_clean_i  ( stackA_clean   ),  

        .stackB_push_i   ( stackB_push    ), 
        .stackB_pop_i    ( stackB_pop     ),
        .stackB_rcpush_i ( stackB_rcpush  ), 
        .stackB_rcpop_i  ( stackB_rcpop   ),  
        .stackB_clean_i  ( stackB_clean   ),  

        .stackA_empty_o  ( stackA_empty   ),
        .stackB_empty_o  ( stackB_empty   ),
        .stackA_full_o   ( stackA_full    ),
        .stackB_full_o   ( stackB_full    )
    );

    //=========================================================
    //  CONTROL UNIT
    //=========================================================
    arandu_ctrl #(
        .CFG_INPUT        ( CFG_INPUT     ),  
        .CFG_HIDDEN       ( CFG_HIDDEN    ),  
        .CFG_OUTPUT       ( CFG_OUTPUT    ),  
        .CFG_MODEL        ( CFG_MODEL     )  
    ) control_u (
        .clk              ( clk           ),
        .rst_n            ( rst_n         ),
        .start            ( start_i       ),
        .done             ( done_o        ),
        .input_write_o    ( input_write   ),
        .neuron_enb_o     ( neuron_enb    ),

        .base_addr_i      ( base_addr_i   ),
        .dram_addr_o      ( dram_addr_o   ),
        .dram_rdata_i     ( dram_rdata_i  ),
        .dram_valid_i     ( dram_valid_i  ),
        .dram_req_o       ( dram_req_o    ),

        .stackA_empty_i   ( stackA_empty  ),
        .stackA_full_i    ( stackA_full   ),
        .stackA_push_o    ( stackA_push   ), 
        .stackA_pop_o     ( stackA_pop    ),
        .stackA_rcpush_o  ( stackA_rcpush ), 
        .stackA_rcpop_o   ( stackA_rcpop  ),  
        .stackA_clean_o   ( stackA_clean  ),  

        .stackB_empty_i   ( stackB_empty  ),
        .stackB_full_i    ( stackB_full   ),
        .stackB_push_o    ( stackB_push   ), 
        .stackB_pop_o     ( stackB_pop    ),
        .stackB_rcpush_o  ( stackB_rcpush ),
        .stackB_rcpop_o   ( stackB_rcpop  ),
        .stackB_clean_o   ( stackB_clean  ),
        
        .memctrl_data_o   ( memctrl_data  ),
        .memctrl_byte_o   ( memctrl_byte ) 
    );

endmodule