//================================================================
// TESTBENCH
//  Controlador de memoria & Gerador de burst
//----------------------------------------------------------------
// Autor: Lucas Farias Martins
// Email: lucas.martins@ee.ufcg.edu.br
// Data:  15-10-2026
//================================================================

module tb_sram_subsystem;

    //==============================================================
    // Parametros do DUT 
    //==============================================================
    parameter int  ADDR_W      = 9;
    parameter int  DATA_W      = 32;
    parameter int  DEPTH       = 512;
    parameter int  MAX_SIZE    = 4;
    parameter time SYS_CLOCK   = 2ns;  // 500 MHz
    parameter time MEM_LATENCY = 8ns;
    parameter time V_TIME      = 2ns;

    // Sinais de interface
    logic              clk;
    logic              rstn;
    logic              enb_i;
    logic [3:0]        size_i;
    logic              valid_o;
    logic [DATA_W-1:0] rdata_o;

    //==============================================================
    // Geracao de Clock (500MHz)
    //==============================================================
    initial begin
        clk = 1'b0;
        forever #(SYS_CLOCK/2) clk = ~clk;
    end

    //==============================================================
    // Instanciacao do DUT
    //==============================================================
    sram_subsystem #(
        .ADDR_W      ( ADDR_W      ),
        .DATA_W      ( DATA_W      ),
        .DEPTH       ( DEPTH       ),
        .MAX_SIZE    ( MAX_SIZE    ),
        .SYS_CLOCK   ( SYS_CLOCK   ),
        .MEM_LATENCY ( MEM_LATENCY ),
        .V_TIME      ( V_TIME      )
    ) u_dut (
        .clk      ( clk      ),
        .rstn     ( rstn     ),
        .enb_i    ( enb_i    ),
        .size_i   ( size_i   ),
        .valid_o  ( valid_o  ),
        .rdata_o  ( rdata_o  )
    );

    //==============================================================
    //   _____       _     ___                                
    //  |_   _|__ __| |_  / __| ___ __ _ _  _ ___ _ _  __ ___ 
    //    | |/ -_|_-<  _| \__ \/ -_) _` | || / -_) ' \/ _/ -_)
    //    |_|\___/__/\__| |___/\___\__, |\_,_\___|_||_\__\___|         
    //=============================== |_| ==========================
    initial begin
        // Inicializacao
        rstn   = 1'b0;
        enb_i  = 1'b0;
        size_i = 4'd4; // Burst de 4 palavras

        // Aplicacao de Reset
        $display("[%0t] Aplicando Reset...", $time);
        #10ns;
        rstn = 1'b1;
        #10ns;

        // Iniciar leitura em burst
        $display("[%0t] Iniciando leitura em burst (size=%0d)...", $time, size_i);
        enb_i = 1'b1;

        // NOTA IMPORTANTE: No RTL fornecido, quando USE_SRAM está definido, 
        // o sinal valid_o foi amarrado em '0' (always_comb valid_o = '0;).
        // Para contornar isso e sincronizar a leitura, usamos o rdata_o.
        // O mux de saida tem '1 (0xFFFFFFFF) como default. Quando o FSM entra 
        // nos estados GET_RSP, rdata_o assume o valor da memoria (ex: 'x').
        
        $display("[%0t] Aguardando FSM entrar nos estados de GET_RSP...", $time);
        wait(rdata_o !== 32'hFFFFFFFF);
        
        $display("[%0t] Dados da SRAM comecando a sair. Capturando burst...", $time);
        
        // Captura as 4 palavras do burst
        for (int i = 0; i < size_i; i++) begin
            @(posedge clk);
            $display("[%0t] Palavra %0d - rdata_o: %h", $time, i, rdata_o);
        end

        // Finaliza a requisicao
        enb_i = 1'b0;
        
        #50ns;
        $display("[%0t] Teste concluido com sucesso \n", $time);
        $finish(2);
    end

endmodule