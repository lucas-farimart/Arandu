//=====================================================================
// Testbench para produto interno usando dual_stack
// Implementa: (v · v) onde v = [1,2,3,4,5,6,7,8]
// Processo: 
//   1. Carrega Stack A com vetor v
//   2. Para 8 ciclos: alterna rc_push/rc_pop em Stack A
//   3. Multiplica valor lido por ele mesmo (x²)
//   4. Acumula resultado em Stack B
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   01/06/2026
// Date:   02/06/2026
//=====================================================================

`timescale 1ns/1ns

module tb_dual;

    //-----------------------------------------------------------------
    // Parametros
    //-----------------------------------------------------------------
    localparam WORD_W = 32;
    localparam DEPTH  = 16;
    localparam VECTOR_SIZE = 8;
    localparam CLK_PERIOD = 10; // ns
    
    // Vetor de teste
    localparam logic [WORD_W-1:0] TEST_VECTOR[0:VECTOR_SIZE-1] = '{
        32'd1, 32'd2, 32'd3, 32'd4,32'd5, 32'd6, 32'd7, 32'd8
    };
    
    //-----------------------------------------------------------------
    // Sinais do testbench
    //-----------------------------------------------------------------
    logic clk;
    logic rst_n;
    
    // Controle
    logic push_a_i, pop_a_i, rc_push_a_i, rc_pop_a_i;
    logic push_b_i, pop_b_i, rc_push_b_i, rc_pop_b_i;
    
    // Dados
    logic [WORD_W-1:0] data_a_i;
    logic [WORD_W-1:0] data_b_i;
    logic [WORD_W-1:0] data_a_o;
    logic [WORD_W-1:0] data_b_o;
    
    // Status
    logic full_a_o, full_b_o;
    logic empty_a_o, empty_b_o;
    
    // Variaveis para acumulacao
    logic signed [63:0] accumulator;
    logic [WORD_W-1:0]  current_value;
    logic [WORD_W-1:0]  squared_value;
    logic [WORD_W-1:0]  expected_result;
    
    // Controles
    int   cycle_count;
    int   total_cycles;
    logic cycle_complete;
    logic [WORD_W-1:0] final_result;
    
    //-----------------------------------------------------------------
    // Instanciacao do modulo
    //-----------------------------------------------------------------
    dual_neuron_stack #(
        .WORD_W      ( WORD_W        ),
        .DEPTH       ( DEPTH         )
    ) u_dual (
        .clk         ( clk           ),
        .rst_n       ( rst_n         ),
        .push_a_i    ( push_a_i      ),
        .pop_a_i     ( pop_a_i       ),
        .rc_push_a_i ( rc_push_a_i   ),
        .rc_pop_a_i  ( rc_pop_a_i    ),
        .push_b_i    ( push_b_i      ),
        .pop_b_i     ( pop_b_i       ),
        .rc_push_b_i ( rc_push_b_i   ),
        .rc_pop_b_i  ( rc_pop_b_i    ),
        .data_a_i    ( data_a_i      ),
        .data_b_i    ( data_b_i      ),
        .data_a_o    ( data_a_o      ),
        .data_b_o    ( data_b_o      ),
        .full_a_o    ( full_a_o      ),
        .full_b_o    ( full_b_o      ),
        .empty_a_o   ( empty_a_o     ),
        .empty_b_o   ( empty_b_o     )
    );
    
    //-----------------------------------------------------------------
    // Geracao do clock / Inicializacao
    //-----------------------------------------------------------------
    initial begin
        clk = 0;
        push_a_i    = 0;        push_b_i    = 0;
        pop_a_i     = 0;        pop_b_i     = 0;
        rc_push_a_i = 0;        rc_push_b_i = 0;
        rc_pop_a_i  = 0;        rc_pop_b_i  = 0;

        accumulator    = 0;     data_a_i = 0;
        cycle_count    = 0;     data_b_i = 0;
        cycle_complete = 0;
        total_cycles   = VECTOR_SIZE;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    //-----------------------------------------------------------------
    //               ___ _  _ ___ _____ ___   _   _    
    //              |_ _| \| |_ _|_   _|_ _| /_\ | |   
    //               | || .` || |  | |  | | / _ \| |__ 
    //              |___|_|\_|___| |_| |___/_/ \_\____|
    //-----------------------------------------------------------------
    initial begin
        $display("================================================================");
        $display("Testbench: Produto Interno usando Dual Neuron Stack");
        $display("Vetor: [1, 2, 3, 4, 5, 6, 7, 8]");
        $display("Calculo: v · v = Σ(x²) para x = 1 a 8");
        $display("Resultado esperado: %0d", 1*1 + 2*2 + 3*3 + 4*4 + 5*5 + 6*6 + 7*7 + 8*8);
        $display("================================================================");
        
        //-----------------------------------------------------------------
        // Reset do sistema
        //-----------------------------------------------------------------
        rst_n = 0; repeat(3) @(posedge clk);
        rst_n = 1; repeat(1) @(posedge clk);
        $display("\n[INFO] Sistema resetado");
        
        //-----------------------------------------------------------------
        // Passo 1: Carregar Stack A com o vetor [1..8]
        //-----------------------------------------------------------------
        for(int i = 0; i < VECTOR_SIZE; i++) begin
            data_a_i = TEST_VECTOR[i];
            push_a_i = 1;
            @(posedge clk);
            $display("  Push A[%0d] = %0d", i, data_a_i);
            // push_a_i = 0;
            // @(posedge clk);
        end
        $display("[OK] Stack A carregada com %0d elementos", VECTOR_SIZE);
        push_a_i = 0;
        @(posedge clk);

        //-----------------------------------------------------------------
        // Passo 2: Processamento do produto interno
        //-----------------------------------------------------------------
        $display("----------------------------------------------------------------");
        $display("Formato: [Ciclo: Tipo] valor_original -> valor_quadrado | Acumulador");
        $display("----------------------------------------------------------------");
        
        for(int cycle = 0; cycle < total_cycles; cycle++) begin

            // Alterna entre rc_push e rc_pop a cada ciclo
            if (cycle % 2 == 0) begin
                for (int i=0; i<VECTOR_SIZE; ++i) begin
                    rc_pop_a_i <= 1;
                    @(posedge clk);
                    current_value = data_a_o;
                    accumulator += current_value*current_value;
                end
                rc_pop_a_i <= 0;
                @(posedge clk);
                current_value <= 0;
            end else begin
                for (int i=0; i<8; ++i) begin
                    rc_push_a_i <= 1;
                    @(posedge clk);
                    current_value = data_a_o;
                    accumulator += current_value*current_value;
                end
                rc_push_a_i <= 0;
                @(posedge clk);
                current_value = 0;
            end
            
            expected_result = 204;

            if (accumulator == expected_result) $write(" [OK]");
            else $write(" [ERRO! Esperado=%0d]", expected_result);
        
            // Armazenar resultado final na Stack B
            data_b_i = accumulator;
            push_b_i = 1;
            @(posedge clk);
            $display("  Push B: resultado acumulado = %0d (0x%0h)", accumulator, accumulator);
            data_b_i = 0;
            push_b_i = 0;
            accumulator = 0;

        end
        
        //-----------------------------------------------------------------
        // Passo 3: Limpar stack A 
        //-----------------------------------------------------------------
        repeat(5) @(posedge clk);

        push_a_i = 1; 
        pop_a_i = 1;
        @(posedge clk);
        
        push_a_i = 0; 
        pop_a_i = 0;

        //-----------------------------------------------------------------
        // Passo 4: Inverter 
        //-----------------------------------------------------------------
        repeat(5) @(posedge clk);

        for(int cycle = 0; cycle < total_cycles; cycle++) begin

            // Alterna entre rc_push e rc_pop a cada ciclo
            if (cycle % 2 == 0) begin
                for (int i=0; i<VECTOR_SIZE; ++i) begin
                    rc_pop_b_i <= 1;
                    @(posedge clk);
                    current_value = data_b_o;
                    accumulator += current_value * i;
                end
                rc_pop_b_i <= 0;
                @(posedge clk);
                current_value <= 0;
            end else begin
                for (int i=0; i<8; ++i) begin
                    rc_push_b_i <= 1;
                    @(posedge clk);
                    current_value = data_b_o;
                    accumulator += current_value*current_value;
                end
                rc_push_b_i <= 0;
                @(posedge clk);
                current_value = 0;
            end
            
            // Armazenar resultado final na Stack A
            data_a_i = accumulator;
            push_a_i = 1;
            @(posedge clk);
            $display("  Push A: resultado acumulado = %0d (0x%0h)", accumulator, accumulator);
            data_a_i = 0;
            push_a_i = 0;
            accumulator = 0;

        end
        
        $display("\n================================================================");
        $display("RESULTADO FINAL:");
        $display("  Acumulado: %0d", final_result);
        $display("  Esperado:  %0d", expected_result);
        $display("----------------------------------------------------------------  ");
        $display("Testbench finalizado!");
        $display("Demonstrou: produto interno usando rc_push/rc_pop alternados      ");
        $display("Resultado armazenado em Stack B e verificado                      ");
        $display("================================================================\n");
        
        repeat(10) @(posedge clk);
        $finish;
    end
    
endmodule