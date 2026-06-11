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

    localparam CLK_PERIOD = 20;
    localparam DEPTH      = 16;

    //=========================================================
    // DUT SIGNALS
    //=========================================================
    logic clk;
    logic rst_n;

    logic neuron_done;
    logic shift_buff;
    logic buff_select;
    logic input_write;

    logic write_Abuff;
    logic write_Bbuff;
    logic read_Abuff;
    logic read_Bbuff;

    logic [31:0] mem_ctrl_data;
    logic        mem_ctrl_valid;

    logic stackA_empty;
    logic stackB_empty;
    logic stackA_full;
    logic stackB_full;

    //=========================================================
    // CLOCK
    //=========================================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    //=========================================================
    // DUT
    //=========================================================
    arandu_core #(
        .NPU            ( 1     ),
        .STACKS         ( 2     ),
        .DATA_W         ( 8     ),
        .WORD_W         ( 32    ),
        .DEPTH          ( DEPTH )
    ) dut (
        .clk            ( clk             ),
        .rst_n          ( rst_n           ),
        .neuron_done    ( neuron_done     ),
        .shift_buff     ( shift_buff      ),
        .buff_select    ( buff_select     ),
        .input_write    ( input_write     ),
        .write_Abuff    ( write_Abuff     ),
        .write_Bbuff    ( write_Bbuff     ),
        .read_Abuff     ( read_Abuff      ),
        .read_Bbuff     ( read_Bbuff      ),
        .mem_ctrl_data  ( mem_ctrl_data   ),
        .mem_ctrl_valid ( mem_ctrl_valid  ),
        .stackA_empty   ( stackA_empty    ),
        .stackB_empty   ( stackB_empty    ),
        .stackA_full    ( stackA_full     ),
        .stackB_full    ( stackB_full     )
    );

    //=========================================================
    // RESET + DEFAULTS
    //=========================================================
    initial begin

        $display("\n==========================================================");
        $display("    _                    _         ___                      ");
        $display("   /_\\  _ _ __ _ _ _  __| |_  _   / __|___ _ _ ___         ");
        $display("  / _ \\| '_/ _` | ' \\/ _` | || | | (__/ _ \\ '_/ -_)      ");
        $display(" /_/ \\_\\_| \\__,_|_||_\\__,_|\\_,_|  \\___\\___/_| \\___| ");
        $display("==========================================================\n");

        rst_n          = 0;
        neuron_done    = 0;
        shift_buff     = 0;
        buff_select    = 0;
        input_write    = 0;
        write_Abuff    = 0;
        write_Bbuff    = 0;
        read_Abuff     = 0;
        read_Bbuff     = 0;
        mem_ctrl_data  = 0;
        mem_ctrl_valid = 0;

        repeat(5) @(posedge clk);
        rst_n = 1;

        repeat(2) @(posedge clk);

        //=====================================================
        // FASE 1
        // Carrega STACK B com entradas externas
        //=====================================================
        $display("\n============================");
        $display("LOAD STACK B");
        $display("============================\n");

        input_write = 1;

        push_B(32'h01020304);
        push_B(32'h11121314);
        push_B(32'h21222324);
        push_B(32'h31323334);

        input_write = 0;

        repeat(2) @(posedge clk);

        //=====================================================
        // FASE 2
        // Consome STACK B enquanto produz resultados em A
        //=====================================================
        $display("\n============================");
        $display("CONSUME B / PRODUCE A");
        $display("============================\n");

        buff_select = 1'b1;

        repeat(4) begin

            pop_B();

            mem_ctrl_valid = 1;
            mem_ctrl_data  = $random;

            @(posedge clk);

            write_Abuff = 1;
            @(posedge clk);
            write_Abuff = 0;

            shift_bytes(4);

            mem_ctrl_valid = 0;

            repeat(2) @(posedge clk);
        end

        //=====================================================
        // FASE 3
        // Troca buffers
        //=====================================================
        $display("\n============================");
        $display("SWAP BUFFERS");
        $display("============================\n");

        repeat(5) @(posedge clk);

        //=====================================================
        // FASE 4
        // Consome STACK A enquanto recarrega B
        //=====================================================
        $display("\n============================");
        $display("CONSUME A / RELOAD B");
        $display("============================\n");

        buff_select = 1'b0;
        input_write = 1;

        fork

            begin
                repeat(4) begin

                    pop_A();

                    mem_ctrl_valid = 1;
                    mem_ctrl_data  = $random;

                    @(posedge clk);

                    write_Bbuff = 1;
                    @(posedge clk);
                    write_Bbuff = 0;

                    shift_bytes(4);

                    mem_ctrl_valid = 0;

                    repeat(2) @(posedge clk);
                end
            end

            begin
                push_B(32'hAAAA5555);
                push_B(32'h12345678);
                push_B(32'hCAFEBABE);
                push_B(32'hDEADBEEF);
            end

        join

        repeat(20) @(posedge clk);

        $display("\nTB FINISHED\n");
        $finish;
    end

    //=========================================================
    // TASKS
    //=========================================================
    task push_A(input [31:0] data);
    begin
        @(posedge clk);
        mem_ctrl_data = data;
        write_Abuff   = 1;

        @(posedge clk);
        write_Abuff   = 0;

        $display("[%0t] PUSH A = %h", $time, data);
    end
    endtask

    task push_B(input [31:0] data);
    begin
        @(posedge clk);
        mem_ctrl_data = data;
        write_Bbuff   = 1;

        @(posedge clk);
        write_Bbuff   = 0;

        $display("[%0t] PUSH B = %h", $time, data);
    end
    endtask

    task pop_A();
    begin
        @(posedge clk);
        read_Abuff = 1;

        @(posedge clk);
        read_Abuff = 0;

        $display("[%0t] POP A -> %h", $time, dut.stackA_data_out);
    end
    endtask

    task pop_B();
    begin
        @(posedge clk);
        read_Bbuff = 1;

        @(posedge clk);
        read_Bbuff = 0;

        $display("[%0t] POP B -> %h", $time, dut.stackB_data_out);
    end
    endtask

    task shift_bytes(input int n);
    begin
        repeat(n) begin
            @(posedge clk);
            shift_buff = 1;
        end

        @(posedge clk);
        shift_buff = 0;
    end
    endtask

    //=========================================================
    // DEBUG MONITOR
    //=========================================================
    always @(posedge clk) begin

        if (rst_n) begin
            $display(
                "[%0t] sel=%0d shift=%0d A_empty=%0d B_empty=%0d actv=%h",
                $time,
                buff_select,
                shift_buff,
                stackA_empty,
                stackB_empty,
                dut.actv_shiftbuff
            );
        end
    end

endmodule

