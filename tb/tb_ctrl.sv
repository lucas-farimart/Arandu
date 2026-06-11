//=====================================================================
// Testbench para o Controle do Arandu
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   09/06/2026
// Update: 10/06/2026
//=====================================================================

`timescale 1ns/1ns

module tb_ctrl;

    //==================================================
    // Parametros
    //==================================================
    parameter CFG_INPUT  = 18;  // tamanho do array de entrada
    parameter CFG_HIDDEN = 16;  // tamanho do array de pesos (linha da matriz)
    parameter CFG_OUTPUT = 10;  // tamanho do array de saida
    parameter CFG_MODEL  = 16;  // palavras 32b para shapes das camadas ocultas
    
    logic clk;
    logic rst_n;
    logic start;

    // DATA SIGNALS (stacks)
    logic        core_stackA_empty;
    logic        core_stackB_empty;
    logic        core_stackA_full;
    logic        core_stackB_full;

    // MEM CONTROL INTERFACE
    logic [15:0] base_addr;
    logic [15:0] dram_addr;
    logic [31:0] dram_rdata;
    logic        dram_valid;
    logic        dram_req;

    // FSM CONTROL SIGNALS
    logic        ctrl_stackA_push; 
    logic        ctrl_stackA_pop;
    logic        ctrl_stackA_rcpush; 
    logic        ctrl_stackA_rcpop;  
    logic        ctrl_stackA_clean;

    logic        ctrl_stackB_push; 
    logic        ctrl_stackB_pop;
    logic        ctrl_stackB_rcpush;
    logic        ctrl_stackB_rcpop;
    logic        ctrl_stackB_clean;

    //==================================================
    //  Instancia do Controle
    //==================================================
    arandu_ctrl #(
        .CFG_INPUT         (  18  ),  
        .CFG_HIDDEN        (  16  ),   
        .CFG_OUTPUT        (  10  ),  
        .CFG_MODEL         (  16  )   
    ) u_ctrl (
        .clk               ( clk                ),
        .rst_n             ( rst_n              ),
        .start             ( start              ),

        .stackA_empty_i    ( core_stackA_empty  ),
        .stackB_empty_i    ( core_stackB_empty  ),
        .stackA_full_i     ( core_stackA_full   ),
        .stackB_full_i     ( core_stackB_full   ),

        .base_addr_i       ( base_addr          ),
        .dram_addr_o       ( dram_addr          ),
        .dram_rdata_i      ( dram_rdata         ),
        .dram_valid_i      ( dram_valid         ),
        .dram_req_o        ( dram_req           ),

        .stackA_push_o     ( ctrl_stackA_push   ), 
        .stackA_pop_o      ( ctrl_stackA_pop    ),
        .stackA_rcpush_o   ( ctrl_stackA_rcpush ), 
        .stackA_rcpop_o    ( ctrl_stackA_rcpop  ),  
        .stackA_clean_o    ( ctrl_stackA_clean  ),  
        .stackB_push_o     ( ctrl_stackB_push   ), 
        .stackB_pop_o      ( ctrl_stackB_pop    ),
        .stackB_rcpush_o   ( ctrl_stackB_rcpush ),
        .stackB_rcpop_o    ( ctrl_stackB_rcpop  ),
        .stackB_clean_o    ( ctrl_stackB_clean  )
    );

    //==================================================
    //  Instancia de Memoria
    //==================================================
    dram_model #(
        .ADDR_WIDTH   ( 16          ),
        .DATA_WIDTH   ( 32          ),
        .MEM_WORDS    ( 4096        ),
        .LATENCY      ( 4           )
    ) u_memory (
        .clk          ( clk         ),
        .rstn         ( rst_n       ),
        .req          ( dram_req    ),
        .valid        ( dram_valid  ),
        .addr         ( dram_addr   ),
        .rdata        ( dram_rdata  )
    );


    //==================================================
    // Clock
    //==================================================
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    //==================================================
    // Stimulus
    //==================================================
    initial begin

        rst_n = 0;
        start = 0;
        base_addr = '0;

        core_stackA_empty = 0;
        core_stackB_empty = 0;
        core_stackA_full  = 0;
        core_stackB_full  = 0;

        repeat(5) @(posedge clk);
        rst_n = 1;

        @(negedge clk); start = 1; 
        @(negedge clk); start = 0;

        // #10us
        #10us
        $finish;
    end


endmodule