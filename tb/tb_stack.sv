//=====================================================================
// Testbench: Stack de neuronios
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   07/05/2026
//=====================================================================

`timescale 1ns/1ns

module tb_stack;

    //========================================================
    // Parameters
    //========================================================
    localparam int DATA_W = 8;
    localparam int DEPTH  = 64;

    //========================================================
    // DUT Signals
    //========================================================
    logic                     clk;
    logic                     rst_n;
    logic                     push;
    logic                     pop;
    logic signed [DATA_W-1:0] data_in;
    logic signed [DATA_W-1:0] data_out;
    logic                     full;
    logic                     empty;
    logic [7:0]               zero_count;

    //========================================================
    // Queues
    //========================================================
    byte signed input_queue   [$];
    byte signed golden_queue  [$];

    //========================================================
    // DUT
    //========================================================

    neuron_stack #(
        .DATA_W         ( DATA_W          ),
        .DEPTH          ( DEPTH           )
    ) dut (
        .clk            ( clk             ),
        .rst_n          ( rst_n           ),
        .push           ( push            ),
        .pop            ( pop             ),
        .data_in        ( data_in         ),
        .data_out       ( data_out        ),
        .full           ( full            ),
        .empty          ( empty           ),
        .level          ( level           ),
        .zero_count     ( zero_count      )
    );

    //========================================================
    // Clock
    //========================================================
    initial begin clk = 0; forever #5 clk = ~clk; end

    //========================================================
    // Tasks
    //========================================================

    task reset_dut();
        rst_n   = 0;
        push    = 0;
        pop     = 0;
        data_in = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);
    endtask

    task push_byte(input byte signed val);
        @(posedge clk);
        push    <= 1'b1;
        data_in <= val;
        @(posedge clk);
        push    <= 1'b0;
        data_in <= 0;
    endtask

    task pop_byte();
        @(posedge clk); pop <= 1;
        @(posedge clk); pop <= 0;
    endtask

    //========================================================
    // Queue Generation
    //========================================================

    task build_queue(
        input int size,
        input int zero_percent_min,
        input int zero_percent_max
    );

        int zero_percent;
        int rand_sel;
        byte signed val;

        begin

            input_queue.delete();
            golden_queue.delete();

            // escolhe % de zeros
            zero_percent =
                $urandom_range(
                    zero_percent_min,
                    zero_percent_max
                );

            $display("\n----------------------------------------");
            $display("QUEUE SIZE     = %0d", size);
            $display("ZERO PERCENT   = %0d%%", zero_percent);
            $display("----------------------------------------\n");

            for (int i = 0; i < size; i++) begin
                rand_sel = $urandom_range(0,99);
                if (rand_sel < zero_percent) 
                    val = 0;
                else
                    val = $random;

                input_queue.push_back(val);
                if (val != 0)
                golden_queue.push_back(val);

            end

            $display("\nINPUT QUEUE:"); foreach(input_queue[i]) $write("%0d ", input_queue[i]);
            $display("\n");
            $display("GOLDEN QUEUE:");  foreach(golden_queue[i]) $write("%0d ", golden_queue[i]);
            $display("\n");

        end

    endtask

    //========================================================
    // Execute Test
    //========================================================
    byte signed expected;
    byte signed received;
    int         golden_size;

    task execute_test(string test_name);


        begin

            $display("\n========================================");
            $display("RUNNING TEST: %s", test_name);
            $display("========================================");

            foreach(input_queue[i]) begin
                push_byte(input_queue[i]);
                if (zero_count) begin
                    pass
                end
                $display(
                    "[PUSH] idx=%0d  | data=%0d \t| level=%0d \t| zeros=%0d",
                    i,
                    input_queue[i],
                    level,
                    zero_count
                );
            end

            golden_size = golden_queue.size();

            //--------------------------------------------
            // pop + comparacao
            //--------------------------------------------

            $display("\nPOP CHECK:");

            while (!empty) begin
                pop_byte();
                #1ns;
                received = data_out;
                expected = golden_queue.pop_back();
                if (received !== expected) 
                $error("DATA MISMATCH exp=%0d got=%0d",expected,received);
            end

            //--------------------------------------------
            // final checks
            //--------------------------------------------

            if (golden_queue.size() != 0)
                $error("GOLDEN QUEUE NOT EMPTY");

            $display("\nTEST PASSED: %s", test_name);

        end

    endtask

    //========================================================
    // Main
    //========================================================

    initial begin

        int qsize;

        $display("\n================================================================================ ");
        $display("     _  _                         ___ _           _     _____       _              ");
        $display("    | \\| |___ _  _ _ _ ___ _ _   / __| |_ __ _ __| |__ |_   _|__ __| |_           ");
        $display("    | .` / -_) || | '_/ _ \\ ' \\  \\__ \\  _/ _` / _| / /   | |/ -_|_-<  _|       ");
        $display("    |_|\\_\\___|\\_,_|_| \\___/_||_| |___/\\__\\__,_\\__|_\\_\\   |_|\\___/__/\\__|");
        $display("================================================================================\n ");

        //--------------------------------------------
        // TEST 1
        // Random puro
        //--------------------------------------------

        reset_dut();
        qsize = $urandom_range(1, DEPTH);
        build_queue(qsize,0,50);
        execute_test("TEST1_RANDOM");

        //--------------------------------------------
        // TEST 2
        // 10% a 20% zeros
        //--------------------------------------------

        reset_dut();
        qsize = $urandom_range(DEPTH/2 + 1,DEPTH);
        build_queue(qsize,10,20);
        execute_test("TEST2_LOW_SPARSITY");

        //--------------------------------------------
        // TEST 3
        // 40% a 70% zeros
        //--------------------------------------------

        reset_dut();
        qsize = $urandom_range(DEPTH/2 + 1,DEPTH);
        build_queue(qsize,40,70);
        execute_test("TEST3_HIGH_SPARSITY");

        //--------------------------------------------
        // Finish
        //--------------------------------------------

        $display("\n========================================");
        $display("ALL TESTS FINISHED");
        $display("========================================");

        #20;
        $finish;

    end

endmodule