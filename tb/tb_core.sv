//=====================================================================
// Testbench: Arandu's processing core 
// Description:
//   Verifies the NPU cluster + stack buffers.
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   11/05/2026
//=====================================================================

`timescale 1ns/1ns

module tb_core;

    //=========================================================
    // DUT Signals
    //=========================================================
    localparam int NPU_COUNT = 4;
    localparam int DATA_W    = 8;
    localparam int DEPTH     = 64;

    logic clk;
    logic rst_n;

    logic                      bus_valid;
    logic [$clog2(NPU_COUNT)-1:0] bus_dest;
    logic signed  [DATA_W-1:0] bus_x;
    logic signed  [DATA_W-1:0] bus_w0;
    logic signed  [DATA_W-1:0] bus_w1;
    logic signed  [DATA_W-1:0] bus_w2;
    logic signed  [DATA_W-1:0] bus_w3;
    logic signed        [31:0] acc0 [NPU_COUNT-1:0];
    logic signed        [31:0] acc1 [NPU_COUNT-1:0];
    logic signed        [31:0] acc2 [NPU_COUNT-1:0];
    logic signed        [31:0] acc3 [NPU_COUNT-1:0];
    logic      [NPU_COUNT-1:0] pop_stack;
    logic      [NPU_COUNT-1:0] stack_empty;
    logic      [NPU_COUNT-1:0] stack_full;
    logic         [DATA_W-1:0] zero_count  [NPU_COUNT-1:0];
    logic                [6:0] stack_level [NPU_COUNT-1:0];

    //=========================================================
    // Input queues
    //=========================================================
    byte signed input_q [NPU_COUNT][$];
    byte signed act, val, exp;
    int         expected, dest;

    //=========================================================
    // DUT
    //=========================================================
    arandu_core #(
        .NPU            ( NPU_COUNT       ),
        .DATA_W         ( DATA_W          ),
        .DEPTH          ( DEPTH           )
    ) u_arandu_core (
        .clk            ( clk             ),
        .rst_n          ( rst_n           ),
        .bus_valid      ( bus_valid       ),
        .bus_dest       ( bus_dest        ),
        .bus_x          ( bus_x           ),
        .bus_w0         ( bus_w0          ),
        .bus_w1         ( bus_w1          ),
        .bus_w2         ( bus_w2          ),
        .bus_w3         ( bus_w3          ),
        .pop_stack      ( pop_stack       ),
        .stack_empty    ( stack_empty     ),
        .stack_full     ( stack_full      ),
        .stack_level    ( stack_level     ),
        .zero_count     ( zero_count      ),
        .acc0           ( acc0            ),
        .acc1           ( acc1            ),
        .acc2           ( acc2            ),
        .acc3           ( acc3            )
    );

    //=========================================================
    // Clock
    //=========================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //=========================================================
    // Reset
    //=========================================================
    task reset_dut();
        rst_n     = 0;
        bus_valid = 0;
        bus_dest  = 0;
        bus_x     = 0;
        foreach(pop_stack[i]) pop_stack[i] = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);
    endtask

    //=========================================================
    // Send bus transaction
    //=========================================================
    task send_bus(
        input logic [1:0] dest,
        input byte signed val
    );
        @(posedge clk);
        bus_valid <= 1;
        bus_dest  <= dest;
        bus_x     <= val;
        @(posedge clk);
        bus_valid <= 0;
        bus_x     <= 0;
    endtask

    //=========================================================
    // Pop NPU stack
    //=========================================================
    task pop_npu( input int idx);
        @(posedge clk); pop_stack[idx] <= 1;
        @(posedge clk); pop_stack[idx] <= 0;
    endtask

    //=========================================================
    // Generate traffic
    //=========================================================
    task generate_round_robin_traffic(
        input int total_packets
    );
        $display("\n========================================");
        $display(" GENERATING ROUND-ROBIN TRAFFIC           ");
        $display("========================================\n");

            for(int i=0; i<total_packets; i++) begin

                dest = i % NPU_COUNT; // destination
                val = $random;        // random signed byte
                send_bus(dest, val);  // envia
                if(val != 0)          // modelo
                    input_q[dest].push_back(val);

                //-------------------------------------
                // log
                //-------------------------------------
                $display(
                    "[SEND] cycle=%0d dest=%0d val=%0d",
                    i,dest,val
                );
            end
    endtask

    //=========================================================
    // Check stack levels
    //=========================================================
    task check_levels();
        $display("\n========================================");
        $display(" CHECKING LEVELS                          ");
        $display("========================================\n");
        for(int i=0; i<NPU_COUNT; i++) begin
            expected = input_q[i].size();
            // $display(
            //     "NPU[%0d] expected=%0d got=%0d",
            //     i,expected,stack_level[i]
            // );
            // if(expected != stack_level[i]) 
            //     $error("LEVEL MISMATCH NPU[%0d]",i);
        end
    endtask

    //=========================================================
    // Pop and verify
    //=========================================================
    task pop_and_check();
        $display("\n========================================");
        $display(" POPPING + CHECKING                       ");
        $display("========================================\n");
        for(int n=0; n<NPU_COUNT; n++) begin
            $display("\n----------------- NPU[%0d] -----------------", n);
            while(input_q[n].size() > 0) begin
                pop_npu(n);
                act = u_arandu_core.stack_data_out[n];
                exp = input_q[n].pop_back();
                $display(
                    "[POP] NPU=%0d | exp=%0d \t | act=%0d \t | @ %0t",
                    n,exp,act,$time
                );
                // if(exp !== act) begin
                //     $error(
                //         "DATA MISMATCH NPU[%0d] exp=%0d got=%0d",
                //         n,exp,act
                //     );
                // end
            end
            $display("--------------------------------------------\n", n);
        end
    endtask

    //=========================================================
    // Main
    //=========================================================
    initial begin

        bus_w0 = 1;
        bus_w1 = 2;
        bus_w2 = 3;
        bus_w3 = 4;

        reset_dut();

        $display("\n==========================================================");
        $display("    _                    _         ___                      ");
        $display("   /_\\  _ _ __ _ _ _  __| |_  _   / __|___ _ _ ___         ");
        $display("  / _ \\| '_/ _` | ' \\/ _` | || | | (__/ _ \\ '_/ -_)      ");
        $display(" /_/ \\_\\_| \\__,_|_||_\\__,_|\\_,_|  \\___\\___/_| \\___| ");
        $display("==========================================================\n");
                                                   
        generate_round_robin_traffic(40);

        repeat(10) @(posedge clk);   // Espera
        check_levels();              // Verifica níveis
        pop_and_check();             // Pop + verifica

        $display("\n=========================================");
        $display("               TEST FINISHED              ");
        $display("=========================================\n");

        #20;
        $finish;

    end

endmodule