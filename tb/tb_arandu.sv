//=====================================================================
// Testbench para o Arandu
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   10/06/2026
//=====================================================================

`timescale 1ns/1ns

module tb_arandu;

    //==================================================
    // Parametros
    //==================================================
    parameter CFG_INPUT  = 18;  // tamanho do array de entrada
    parameter CFG_HIDDEN = 16;  // tamanho do array de pesos (linha da matriz)
    parameter CFG_OUTPUT = 10;  // tamanho do array de saida
    parameter CFG_MODEL  = 16;  // palavras 32b para shapes das camadas ocultas
    
    parameter DEPTH      = 16;
    parameter WORD_WIDTH = 32;
    parameter DATA_WIDTH = 8;

    logic        clk;
    logic        rst_n;
    logic        start;
    logic        done;
    logic [15:0] base_addr;
    logic [15:0] dram_addr;
    logic [31:0] dram_rdata;
    logic        dram_valid;
    logic        dram_req;

    //==================================================
    //  Instancia do Controle
    //==================================================
    arandu #(
        .CFG_INPUT         (  18  ),  
        .CFG_HIDDEN        (  16  ),   
        .CFG_OUTPUT        (  10  ),  
        .CFG_MODEL         (  16  )   
    ) top (
        .clk               ( clk                ),
        .rst_n             ( rst_n              ),
        .start_i           ( start              ),
        .done_o            ( done               ),

        .base_addr_i       ( base_addr          ),
        .dram_addr_o       ( dram_addr          ),
        .dram_rdata_i      ( dram_rdata         ),
        .dram_valid_i      ( dram_valid         ),
        .dram_req_o        ( dram_req           )

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

        $display("");
        $display("=====================================================================");
        $display("                     _                    _                          ");
        $display("                    /_\\  _ _ __ _ _ _  __| |_  _                    ");
        $display("                   / _ \\| '_/ _` | ' \\/ _` | || |                  ");
        $display("                  /_/ \\_\\_| \\__,_|_||_\\__,_|\\_,_|               ");
        $display("=====================================================================");
        $display("            The Naive DNN Accelerator for 32b microsystems           ");
        $display("=====================================================================");
        $display("\n");

        rst_n = 0; start = 0;
        base_addr = '0; $display("base_addr = %h\n",base_addr);

        repeat(5) @(posedge clk);
        rst_n = 1;

        repeat (1) begin
            @(posedge clk); start = 1;
            @(posedge clk); start = 0;
        end

        wait(done);

    end

    initial begin
        #10us $finish;
    end

endmodule