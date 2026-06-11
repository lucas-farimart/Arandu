//=====================================================================
// Testbench para o Stack Dual + FSM para gerar flags 
// (push, pop, recirc_push e recirc_pop)
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   01/06/2026
// Date:   02/06/2026
//=====================================================================

`timescale 1ns/1ns

module tb_fsm_dual;

    //==================================================
    // Parametros
    //==================================================
    localparam WORD_W = 32;
    localparam DEPTH  = 16;
    localparam VECTOR_SIZE = 8;
    
    logic clk;
    logic rst_n;
    logic start;
    logic last;

    logic [15:0] lnest0;
    logic [15:0] lnest1;

    logic  push_a, pop_a;
    logic  push_b, pop_b;

    logic  rc_push_a, rc_push_b;
    logic  rc_pop_a,  rc_pop_b;

    logic [WORD_W-1:0] data_a_i, data_b_i;    
    logic [WORD_W-1:0] data_a_o, data_b_o;   

    logic full_a,  full_b;    
    logic empty_a, empty_b;    

    //==================================================
    //  Instanciais: FSM e Dual Stack
    //==================================================
    fsm_gpt FSM (
        .clk         ( clk           ),
        .rst_n       ( rst_n         ),
        .start_i     ( start         ),
        .last_i      ( last          ),

        .lnest0_i    ( lnest0        ),
        .lnest1_i    ( lnest1        ),

        .pop_a_o     ( pop_a         ),
        .push_a_o    ( push_a        ),
        .rc_pop_a_o  ( rc_pop_a      ),
        .rc_push_a_o ( rc_push_a     ),

        .pop_b_o     ( pop_b         ),
        .push_b_o    ( push_b        ),
        .rc_pop_b_o  ( rc_pop_b      ),
        .rc_push_b_o ( rc_push_b     )
    );

    dual_neuron_stack #(
        .WORD_W      ( WORD_W        ),
        .DEPTH       ( DEPTH         )
    ) u_dual (
        .clk         ( clk           ),
        .rst_n       ( rst_n         ),

        .push_a_i    ( push_a        ),
        .pop_a_i     ( pop_a         ),
        .rc_push_a_i ( rc_push_a     ),
        .rc_pop_a_i  ( rc_pop_a      ),

        .push_b_i    ( push_b        ),
        .pop_b_i     ( pop_b         ),
        .rc_push_b_i ( rc_push_b     ),
        .rc_pop_b_i  ( rc_pop_b      ),

        .data_a_i    ( data_a_i      ),
        .data_b_i    ( data_b_i      ),
        .data_a_o    ( data_a_o      ),
        .data_b_o    ( data_b_o      ),

        .full_a_o    ( full_a        ),
        .full_b_o    ( full_b        ),
        .empty_a_o   ( empty_a       ),
        .empty_b_o   ( empty_b       )
    );

    //==================================================
    // Clock
    //==================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //==================================================
    // Stimulus
    //==================================================
    initial begin

        rst_n  = 0;
        start  = 0;
        last   = 0;

        lnest0 = 8;
        lnest1 = 4;

        repeat(5) @(posedge clk);

        rst_n = 1;

        @(posedge clk); start = 1; 
        data_a_i = 1;
        @(posedge clk); start = 0;
        for (int i=1; i<VECTOR_SIZE; ++i) begin
            data_a_i = i + 1;
            @(posedge clk);
        end
        data_a_i = 0;

        repeat(36) @(posedge clk); last = 0;
        repeat(36) @(posedge clk); last = 0;
        repeat(36) @(posedge clk); last = 1;
        repeat(10) @(posedge clk);

        $finish;
    end

    //==================================================
    // Monitor
    //==================================================
    // initial begin
    //     $display("time\tstart\trc_pop\trc_push");
    //     forever begin
    //         @(posedge clk);
    //         $display("%0t\t%b\t%b\t%b",
    //                  $time,start,rc_pop_a,rc_push_a
    //         );
    //     end
    // end

endmodule