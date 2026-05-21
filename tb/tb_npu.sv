//=====================================================================
// Testbench: Neural network streaming engine 
// Description:
//   Verifies integration between mac_system and simple_dram_model,
//   including latency tolerance, double buffering, and MAC execution.
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   08/05/2026
//=====================================================================

`timescale 1ns/1ns

module tb_npu;

    parameter NUM_TESTS = 10000;

    logic clk;
    logic rst_n;
    logic valid_in;
    logic valid_out;

    logic signed [7:0]  x;
    logic signed [7:0]  w0;
    logic signed [7:0]  w1;
    logic signed [7:0]  w2;
    logic signed [7:0]  w3;
    
    logic signed [31:0] acc0;
    logic signed [31:0] acc1;
    logic signed [31:0] acc2;
    logic signed [31:0] acc3;

    //==========================================================
    //  DUT / Clock
    //==========================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    npu u_npu (
        .clk       ( clk          ),
        .rst_n     ( rst_n        ),
        .valid_in  ( valid_in     ),
        .x         ( x            ),
        .w0        ( w0           ),
        .w1        ( w1           ),
        .w2        ( w2           ),
        .w3        ( w3           ),
        .valid_out ( valid_out    ),
        .acc0      ( acc0         ),
        .acc1      ( acc1         ),
        .acc2      ( acc2         ),
        .acc3      ( acc3         )
    );

    //==========================================================
    //  GOLDEN MODEL
    //==========================================================
    int golden_acc0;
    int golden_acc1;
    int golden_acc2;
    int golden_acc3;
    int fail_tests, pass_tests;

    //==========================================================
    //  RESET
    //==========================================================
    task reset_dut();
        rst_n    = 0;
        valid_in = 0;

        x  = 0;
        w0 = 0;   golden_acc0 = 0;
        w1 = 0;   golden_acc1 = 0;
        w2 = 0;   golden_acc2 = 0;
        w3 = 0;   golden_acc3 = 0;

        repeat(5) @(posedge clk); rst_n = 1;
        repeat(2) @(posedge clk);
    endtask

    //==========================================================
    //  SEND VECTOR
    //==========================================================
    task send_vector(
        input signed [7:0] tx,
        input signed [7:0] tw0,
        input signed [7:0] tw1,
        input signed [7:0] tw2,
        input signed [7:0] tw3
    );
        @(posedge clk);
        valid_in <= 1;
        x  <= tx;
        w0 <= tw0;
        w1 <= tw1;
        w2 <= tw2;
        w3 <= tw3;

        // GOLDEN MODEL UPDATE
        golden_acc0 += tx * tw0;
        golden_acc1 += tx * tw1;
        golden_acc2 += tx * tw2;
        golden_acc3 += tx * tw3;

    endtask

    //==========================================================
    //  STOP VALID
    //==========================================================
    task stop_valid();
        @(posedge clk);
        valid_in <= 0;
        x  <= 0;
        w0 <= 0;
        w1 <= 0;
        w2 <= 0;
        w3 <= 0;
    endtask

    //==========================================================
    //  TESTE BASE
    //==========================================================
    task base_test(input int size);
        byte signed x, w[4];
        reset_dut();
        for (int i=0; i<size; ++i) begin
            foreach (w[i]) 
            w[i] = $urandom_range(-128,127);
            x    = $urandom_range(-128,127);
            send_vector( x, w[0], w[1], w[2], w[3]);
        end
        stop_valid();
    endtask

    //==========================================================
    //  Initial
    //==========================================================
    initial begin

        $display("\n=============================================================================");
        $display("    _                    _        _  _ ___ _   _   _____       _               ");
        $display("   /_\\  _ _ __ _ _ _  __| |_  _  | \\| | _ \\ | | | |_   _|__ __| |_          ");
        $display("  / _ \\| '_/ _` | ' \\/ _` | || | | .` |  _/ |_| |   | |/ -_|_-<  _|          ");
        $display(" /_/ \\_\\_| \\__,_|_||_\\__,_|\\_,_| |_|\\_|_|  \\___/    |_|\\___/__/\\__|   ");
        $display("                                                                               ");
        $display("=============================================================================\n");

        for (int i=0; i<NUM_TESTS; ++i) begin

            //-----------------------------------
            // EFFECTIVE TEST
            //-----------------------------------
            base_test($urandom_range(3,50));
            @(negedge valid_out);

            //-----------------------------------
            // CHECK
            //-----------------------------------
            if ( acc0 != golden_acc0 ) begin
                fail_tests++;
                $error("Acc0 = %0d wrong, expecting %0d",acc0,golden_acc0);          
            end else
            if ( acc1 != golden_acc1 ) begin
                fail_tests++;
                $error("Acc1 = %0d wrong, expecting %0d",acc1,golden_acc1);         
            end else
            if ( acc2 != golden_acc2 ) begin
                fail_tests++;
                $error("Acc2 = %0d wrong, expecting %0d",acc2,golden_acc2);         
            end else
            if ( acc3 != golden_acc3 ) begin
                fail_tests++;
                $error("Acc3 = %0d wrong, expecting %0d",acc3,golden_acc3); 
            end else
                pass_tests++;

            if (i%1000==0) $display("Tests %0d/%0d", i, NUM_TESTS);

        end

        $display("\n");
        $display("======================================");
        $display("            FINAL REPORT              ");
        $display("======================================");
        $display(" Total de testes:  %0d", NUM_TESTS);
        $display(" Numero de erros:  %0d", fail_tests);
        $display(" Taxa de acerto:   %0d", pass_tests);
        $display("======================================\n");
        $display("\n");

        $finish;

    end

endmodule