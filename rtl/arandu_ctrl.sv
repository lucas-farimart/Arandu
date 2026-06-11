//=====================================================================
// Arandu Control: State logic and Flags generation
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   11/05/2026
//=====================================================================

module arandu_ctrl #(
    parameter CFG_INPUT  = 18,  // tamanho do array de entrada
    parameter CFG_HIDDEN = 16,  // tamanho do array de pesos (linha da matriz)
    parameter CFG_OUTPUT = 10,  // tamanho do array de saida
    parameter CFG_MODEL  = 8    // palavras 32b para shapes das camadas ocultas
)(
    input  logic  clk,
    input  logic  rst_n,
    input  logic  start,

    // MEM CONTROL INTERFACE
    input  logic [15:0] base_addr_i,
    output logic [15:0] dram_addr_o,
    input  logic [31:0] dram_rdata_i,
    input  logic        dram_valid_i,
    output logic        dram_req_o,

    // FSM CONTROL SIGNALS
    input  logic        stackA_empty_i,
    input  logic        stackA_full_i,
    output logic        stackA_push_o, 
    output logic        stackA_pop_o,
    output logic        stackA_rcpush_o, 
    output logic        stackA_rcpop_o,  
    output logic        stackA_clean_o,  

    input  logic        stackB_empty_i,
    input  logic        stackB_full_i,
    output logic        stackB_push_o, 
    output logic        stackB_pop_o,
    output logic        stackB_rcpush_o,
    output logic        stackB_rcpop_o,
    output logic        stackB_clean_o  
    
);
    //======================================================
    //  INTERNOS
    //======================================================
    logic [3:0]   cfg_layers;
    logic [17:0]  cfg_input_width;
    logic [9:0]   cfg_output_width;
    logic [5:0]   cfg_width_addr;
    logic [31:0]  cfg_width_data;
    logic [17:0]  cfg_width_18;
    logic [15:0]  cfg_width_16;
    logic [17:0]  cfg_lnest0; // inner loop nest
    logic [15:0]  cfg_lnest1; // outer loop nest

    logic         ctrl_enb;
    logic         ctrl_io_enable;
    logic         ctrl_hdn_enable;
    logic         ctrl_incr_layer;
    logic         ctrl_incr_addr;
    logic         ctrl_last;
    logic         ctrl_first;
    logic [7:0]   ctrl_out_byte;
    logic [31:0]  ctrl_out_word;
    logic         ctrl_out_valid;

    logic [7:0]   w_model;     
    logic [7:0]   w_input;     
    logic [7:0]   w_output;    
    logic [7:0]   w_hidden;    
    logic         cfg_words_load;
    logic         cfg_words_input;
    logic         cfg_words_output;
    logic         cfg_words_hidden;

    //======================================================
    // CONTADOR DE CAMADAS (num layers) e 
    // TIMER GLOBAL (contador de clock)
    //======================================================
    logic [15:0] layer_counter;
    logic [15:0] global_timer;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)          layer_counter <= 'h1; else 
        if (ctrl_incr_layer) layer_counter <= layer_counter + 1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) global_timer <= 'h0;
        else        global_timer <= global_timer + 1;
    end

    //======================================================
    // INFERENCIA DAS DIMENSOES DO MODELO
    //======================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)         cfg_layers <= '0; else
        if (ctrl_io_enable) cfg_layers <= dram_rdata_i[31:28];
    end

    always_comb w_model  = (cfg_layers   >> 1) + 1;   // 2 de 16b
    always_comb w_input  = (cfg_width_18 >> 2) + 3;   // 4 de 8b por palavra
    always_comb w_output = (cfg_width_16 >> 2) + 3;   // 4 de 8b

    always_comb ctrl_last  = (layer_counter == cfg_layers-2);    
    always_comb ctrl_first = (layer_counter == 0); 

    always_comb cfg_lnest0       = cfg_width_18;
    always_comb cfg_lnest1       = cfg_width_16;
    always_comb cfg_words_load   = (dram_addr_o == w_model-1) && dram_valid_i;
    always_comb cfg_width_data   = (ctrl_hdn_enable) ? dram_rdata_i : '0;
    always_comb cfg_output_width = (ctrl_io_enable)  ? dram_rdata_i[27:18] : '0;
    always_comb cfg_input_width  = (ctrl_io_enable)  ? dram_rdata_i[17:0]  : '0;
    // always_comb cfg_layers       = (ctrl_io_enable)  ? dram_rdata_i[31:28] : '0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || cfg_words_load) 
            cfg_width_addr <= 'h0;
        else if (ctrl_hdn_enable)
            cfg_width_addr <= cfg_width_addr + 2;
        else if (ctrl_incr_layer)
            cfg_width_addr <= cfg_width_addr + 1;
    end

    //======================================================
    //  CONTROLADOR DE MEMORIA
    //======================================================
    mem_controller u_mem_ctrl 
    (
        .clk          ( clk               ),
        .rst_n        ( rst_n             ),
        .start_i      ( start             ),
        .enb_i        ( ctrl_enb          ),
        .base_addr_i  ( base_addr_i       ),
        .dram_addr_o  ( dram_addr_o       ),
        .dram_rdata_i ( dram_rdata_i      ),
        .dram_valid_i ( dram_valid_i      ),
        .dram_req_o   ( dram_req_o        ),
        .out_byte     ( ctrl_out_byte     ),
        .out_word     ( ctrl_out_word     ),
        .out_valid    ( ctrl_out_valid    )
    );

    //======================================================
    //  MAPEAMENTO DOS METADADOS DA REDE
    //======================================================
    metadata_map #(
        .HIDDEN_BUFF    ( CFG_MODEL         ),
        .INPUT_BITS     ( CFG_INPUT         ), 
        .HIDDEN_BITS    ( CFG_HIDDEN        ), 
        .OUTPUT_BITS    ( CFG_OUTPUT        )
    ) metadata_u (
        .clk            ( clk               ),
        .rst_n          ( rst_n             ),
        
        .io_enable_i    ( ctrl_io_enable    ),
        .hdn_enable_i   ( ctrl_hdn_enable   ),
        .layers_i       ( cfg_layers        ),
        .input_width_i  ( cfg_input_width   ),
        .output_width_i ( cfg_output_width  ),
        .width_addr_i   ( cfg_width_addr    ),
        .width_data_i   ( cfg_width_data    ),

        .width_18_o     ( cfg_width_18      ),
        .width_16_o     ( cfg_width_16      )
    );

    //======================================================
    // FSM: UMA MAQUINA MINHA
    //======================================================
    fsm_controller FSM (
        .clk          ( clk              ),
        .rst_n        ( rst_n            ),

        .start_i      ( start            ),
        .first_i      ( ctrl_first       ),
        .last_i       ( ctrl_last        ),
        .pop_result_i ( 1'b0             ),
        .mem_valid_i  ( dram_valid_i     ),
        .w_model_i    ( cfg_words_load   ),
        .lnest0_i     ( cfg_lnest0       ),
        .lnest1_i     ( cfg_lnest1       ),

        .io_enable_o  ( ctrl_io_enable   ),
        .hdn_enable_o ( ctrl_hdn_enable  ),
        .incr_layer_o ( ctrl_incr_layer  ),
        .incr_addr_o  ( ctrl_incr_addr   ),
        .mem_enb_o    ( ctrl_enb         ),

        .push_a_o     ( stackA_pop_o     ),
        .push_b_o     ( stackB_pop_o     ),
        .pop_a_o      ( stackA_push_o    ),
        .pop_b_o      ( stackB_push_o    ),
        .clean_a_o    ( stackA_clean_o   ),
        .clean_b_o    ( stackB_clean_o   ),
        .rc_pop_b_o   ( stackB_rcpush_o  ),
        .rc_pop_a_o   ( stackA_rcpush_o  ),
        .rc_push_a_o  ( stackA_rcpop_o   ),
        .rc_push_b_o  ( stackB_rcpop_o   )
    );

endmodule
