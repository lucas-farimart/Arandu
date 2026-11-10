//=====================================================================
// Testbench: Arandu's processing core 
// Description:
//   Verifies the NPU processing
//---------------------------------------------------------------------
//  y = W * x     W: NEURONS x 3     x: 3
//
//  W = [  1.0   2.0   3.0 ]      x = [ 1.0 ]      y = [ 14.0 ]
//      [  0.5  -1.0   2.0 ]          [ 2.0 ]          [  4.5 ]
//      [  2.0   2.0   2.0 ]          [ 3.0 ]          [ 12.0 ]
//      [ -1.0   0.0   4.0 ]                           [ 11.0 ]
//
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   11/05/2026
//=====================================================================

//=====================================================================
//  ATENCAO - premissas (ajuste se for diferente no seu design):
//   1) A preload das SRAMs e feita por referencia hierarquica na task
//      preload_memories(). Nao tenho mem_weights/mem_actvs, entao os
//      nomes (mem) e o layout (1 palavra por entrada j, com os pesos
//      dos NEURONS lado a lado) sao suposicoes.
//   2) Cada resultado de neuronio e capturado quando npu_o_valid = 1.
//   3) size_i precisa ter pelo menos 2 bits para representar 3
//      (veja observacoes na resposta).
//=====================================================================

`timescale 1ns/10ps

module tb_core;

    //-----------------------------------------------------------------
    // Parametros
    //-----------------------------------------------------------------
    parameter int  SIZE        = 3;
    parameter int  NEURONS     = 4;    
    parameter int  MUL_LAT     = 9;
    parameter int  ADDR_W      = 9;
    parameter int  DATA_W      = 32;
    parameter int  WORD_W      = 4*DATA_W; // 256
    parameter int  DEPTH       = 512;
    parameter int  MAX_SIZE    = 4;
    parameter time CLK_PER     = 2ns;
    parameter time MEM_LATENCY = 8ns;
    parameter time V_TIME      = 2ns;
    parameter time TIMEOUT     = 2000ns;

    //-----------------------------------------------------------------
    // Sinais do DUT
    //-----------------------------------------------------------------
    logic       clk;
    logic       rst_n;
    logic       enb_i;
    logic       we_i;
    logic [3:0] size_i;                       // precisa de >= 2 bits p/ valor 3
    logic       actv_selx_i;
    logic       actv_sely_i;

    //-----------------------------------------------------------------
    // DUT
    //-----------------------------------------------------------------
    arandu_core #(
        .NEURONS      ( NEURONS      ),    
        .MUL_LAT      ( MUL_LAT      ),
        .ADDR_W       ( ADDR_W       ),
        .DATA_W       ( DATA_W       ),
        .WORD_W       ( WORD_W       ),
        .DEPTH        ( DEPTH        ),
        .MAX_SIZE     ( MAX_SIZE     ),
        .SYS_CLOCK    ( CLK_PER      ),
        .MEM_LATENCY  ( MEM_LATENCY  ),
        .V_TIME       ( V_TIME       )
    ) DUT (
        .clk          ( clk          ),
        .rst_n        ( rst_n        ),
        .enb_i        ( enb_i        ),
        .we_i         ( we_i         ),
        .size_i       ( size_i       ),
        .actv_selx_i  ( actv_selx_i  ),
        .actv_sely_i  ( actv_sely_i  )
    );

    //-----------------------------------------------------------------
    // Clock
    //-----------------------------------------------------------------
    initial clk = 1'b0;
    always #(CLK_PER/2.0) clk = ~clk;

    //-----------------------------------------------------------------
    // Dados de teste + modelo de referencia (golden)
    //-----------------------------------------------------------------
    shortreal W_r [NEURONS][SIZE] = '{
        '{ 1.0,  2.0, 3.0 },
        '{ 0.5, -1.0, 2.0 },
        '{ 2.0,  2.0, 2.0 },
        '{-1.0,  0.0, 4.0 }
    };
    shortreal X_r [SIZE] = '{ 1.0, 2.0, 3.0 };

    logic [DATA_W-1:0] W_bits [NEURONS][SIZE];
    logic [DATA_W-1:0] X_bits [SIZE];
    logic [DATA_W-1:0] Y_exp  [NEURONS];

    task automatic build_golden();
        shortreal acc;
        for (int j = 0; j < SIZE; j++) X_bits[j] = $shortrealtobits(X_r[j]);
        for (int n = 0; n < NEURONS; n++) begin
            acc = 0.0;
            for (int j = 0; j < SIZE; j++) begin
                W_bits[n][j] = $shortrealtobits(W_r[n][j]);
                acc += W_r[n][j] * X_r[j];
            end
            Y_exp[n] = $shortrealtobits(acc);
        end
    endtask

    //-----------------------------------------------------------------
    // Preload das memorias (referencia hierarquica - AJUSTAR!)
    //-----------------------------------------------------------------
    // task automatic preload_memories();
    //     logic [NEURONS*DATA_W-1:0] w_word;
    //     for (int j = 0; j < SIZE; j++) begin
    //         // palavra de pesos: [neuronio0 | neuronio1 | ...] para a entrada j
    //         for (int n = 0; n < NEURONS; n++)
    //             w_word[n*DATA_W +: DATA_W] = W_bits[n][j];
    //         // >>> ajuste os nomes abaixo para o seu mem_weights / mem_actvs <<<
    //         DUT.WEIGHT.rdata_o = w_word;
    //         DUT.ACTV.rdata_o   = X_bits[j];
    //     end
    // endtask

    //-----------------------------------------------------------------
    // Captura dos resultados
    //-----------------------------------------------------------------
    logic [DATA_W-1:0] y_got [$];

    always @(posedge clk) begin
        if (rst_n && DUT.npu_o_valid) begin
            y_got.push_back(DUT.actv_wdata);
            $display("[%0t] resultado #%0d capturado: 0x%08h (%f)",
                     $time, y_got.size()-1, DUT.actv_wdata,
                     $bitstoshortreal(DUT.actv_wdata));
        end
    end

    //-----------------------------------------------------------------
    // Estimulo
    //-----------------------------------------------------------------
    int errors;
    int cycles;

    initial begin
        errors      = 0;
        enb_i       = 1'b0;
        we_i        = 1'b0;
        size_i      = '0;
        actv_selx_i = 1'b0;   // le do banco X
        actv_sely_i = 1'b1;   // escreve no banco Y
        rst_n       = 1'b0;

        build_golden();

        // Reset
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        // Carrega dados
        // preload_memories();

        // Dispara a inferencia da camada (size = 3)
        @(posedge clk);
        size_i = SIZE[1:0];
        enb_i  = 1'b1;
        @(posedge clk);
        enb_i  = 1'b0;

        // Espera os NEURONS resultados (ou timeout)
        cycles = 0;
        while (y_got.size() < NEURONS && cycles < TIMEOUT) begin
            @(posedge clk);
            cycles++;
        end

        repeat (5) @(posedge clk);

        // Verificacao
        if (y_got.size() != NEURONS) begin
            $error("Esperava %0d resultados, recebi %0d (timeout=%0d ciclos)",
                   NEURONS, y_got.size(), cycles);
            errors++;
        end

        for (int n = 0; n < y_got.size() && n < NEURONS; n++) begin
            if (y_got[n] !== Y_exp[n]) begin
                $error("Neuronio %0d: obtido 0x%08h (%f) | esperado 0x%08h (%f)",
                       n, y_got[n], $bitstoshortreal(y_got[n]),
                       Y_exp[n],   $bitstoshortreal(Y_exp[n]));
                errors++;
            end else begin
                $display("Neuronio %0d OK: %f", n, $bitstoshortreal(y_got[n]));
            end
        end

        if (errors == 0) $display("\n*** TESTE PASSOU ***\n");
        else             $display("\n*** TESTE FALHOU: %0d erro(s) ***\n", errors);

        $finish;
    end

    // Watchdog global
    initial begin
        #(CLK_PER * (TIMEOUT + 100));
        $display("WATCHDOG: simulacao excedeu o tempo limite");
        $finish;
    end
    
endmodule