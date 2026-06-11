//=====================================================================
// Testbench da Maquina de Estados sugerida pelo GPT
//   Descricao: pergunta pra ele
//---------------------------------------------------------------------
// Author: Lucas Farias Martins (fiz o prompt ue)
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   02/06/2026
//=====================================================================

`timescale 1ns/1ns

module tb_fsm;

    logic clk;
    logic rst_n;
    logic start_i;

    logic [15:0] lnest0_i;
    logic [15:0] lnest1_i;

    logic pop_a_o;
    logic push_a_o;
    logic rc_pop_a_o;
    logic rc_push_a_o;

    fsm_gpt dut (
        .clk         ( clk         ),
        .rst_n       ( rst_n       ),
        .start_i     ( start_i     ),
        .lnest0_i    ( lnest0_i    ),
        .lnest1_i    ( lnest1_i    ),
        .pop_a_o     ( pop_a_o     ),
        .push_a_o    ( push_a_o    ),
        .rc_pop_a_o  ( rc_pop_a_o  ),
        .rc_push_a_o ( rc_push_a_o )
    );

    //--------------------------------------------------
    // Clock
    //--------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //--------------------------------------------------
    // Stimulus
    //--------------------------------------------------
    initial begin

        rst_n    = 0;
        start_i  = 0;
        lnest0_i = 8;
        lnest1_i = 4;

        repeat(5) @(posedge clk);

        rst_n = 1;

        @(posedge clk); start_i = 1; 
        @(posedge clk); start_i = 0;

        repeat(100) @(posedge clk);

        $finish;
    end

    //--------------------------------------------------
    // Monitor
    //--------------------------------------------------
    initial begin
        $display("time\tstart\trc_pop\trc_push");
        forever begin
            @(posedge clk);
            $display("%0t\t%b\t%b\t%b",
                     $time,start_i,rc_pop_a_o,rc_push_a_o
            );
        end
    end

endmodule