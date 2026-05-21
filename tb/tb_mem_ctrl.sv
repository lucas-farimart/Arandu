//=====================================================================
// Testbench: Arandu's DRAM access control
// Description: READ THE NAME DUDE 
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   18/05/2026
//=====================================================================

`timescale 1ns/1ns

module tb_mem_ctrl;

    logic clk;
    logic rstn;

    logic start;
    logic done;

    logic        dram_req;
    logic [15:0] dram_addr;
    logic        dram_valid;
    logic [31:0] dram_rdata;

    logic        out_valid;
    logic [7:0]  out_data;
    logic        out_ready;

    //====================================================
    //  DRAM MODEL AND CONTROLLER
    //====================================================
    mem_ctrl #(
        .ADDR_WIDTH    ( 16 ),
        .DATA_WIDTH    ( 32 ),
        .BUFFER_WORDS  ( 16 )
    ) dut (
        .clk           ( clk            ),
        .rstn          ( rstn           ),
        .start         ( start          ),
        .done          ( done           ),
        .base_addr     ( 0              ),
        .dram_req      ( dram_req       ),
        .dram_addr     ( dram_addr      ),
        .dram_rdata    ( dram_rdata     ),
        .dram_valid    ( dram_valid     ),
        .out_valid     ( out_valid      ),
        .out_data      ( out_data       )
    );

    dram_model #(
        .ADDR_WIDTH    ( 16   ),
        .DATA_WIDTH    ( 32   ),
        .MEM_WORDS     ( 4096 ),
        .LATENCY       ( 5    )
    ) dram (
        .clk           ( clk         ),
        .rstn          ( rstn        ),
        .req           ( dram_req    ),
        .addr          ( dram_addr   ),
        .valid         ( dram_valid  ),
        .rdata         ( dram_rdata  )
    );

    //====================================================
    //  effective test
    //====================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    integer i;

    initial begin

        $display("\n");
        $display("  ___  ___    _   __  __    ___         _           _        ");
        $display(" |   \\| _ \\  /_\\ |  \\/  |  / __|___ _ _| |_ _ _ ___| |   ");
        $display(" | |) |   / / _ \\| |\\/| | | (__/ _ \\ ' \\  _| '_/ _ \\ |  ");
        $display(" |___/|_|_\\/_/ \\_\\_|  |_|  \\___\\___/_||_\\__|_| \\___/_|");
        $display("\n");                                              

        #10ns;
        rstn  = 0; 
        start = 0;
        done  = 0;

        #50ns;
        rstn = 1;

        // Inicializa DRAM
        for (i = 0; i < 256; i++) begin
            // dram.mem[i] = 32'h10000000 + i;
            dram.mem[i] = $random();
        end

        @(posedge clk) start = 1;
        @(posedge clk) start = 0;

        #2000;
        $finish;
    end

    always_ff @(posedge clk) begin
        if (out_valid && out_ready) begin
            $display(
                "[%0t] STREAM BYTE = %02x",
                $time,out_data
            );
        end
    end

endmodule