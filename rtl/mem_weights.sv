//================================================================
// Subsistema de Memoria SRAM para Pesos
//----------------------------------------------------------------
// Autor: Lucas Farias Martins
// Email: lucas.martins@ee.ufcg.edu.br
// Data:  09-11-2026
//================================================================

module mem_weights #(
    parameter int  NEURONS     = 4,
    parameter int  ADDR_W      = 9,
    parameter int  DATA_W      = 32,
    parameter int  DEPTH       = 512,
    parameter int  MAX_SIZE    = 4,
    parameter time SYS_CLOCK   = 2ns,
    parameter time MEM_LATENCY = 8ns,
    parameter time V_TIME      = 2ns
)(
    input  logic               clk,
    input  logic               rstn,
    input  logic               enb_i,
    input  logic [3:0]         size_i,
    output logic [NEURONS-1:0] valid_o,
    output logic [DATA_W-1:0]  rdata_o [NEURONS]
);

    //===================================================
    //  Memory Arrangement
    //===================================================
    generate
    for (genvar j=0; j<4; j++) begin : weight_gen
        sram_subsystem #(
            .ADDR_W       ( ADDR_W      ),
            .DATA_W       ( DATA_W      ),
            .DEPTH        ( DEPTH       ),
            .MAX_SIZE     ( MAX_SIZE    ),
            .SYS_CLOCK    ( SYS_CLOCK   ),
            .MEM_LATENCY  ( MEM_LATENCY ),
            .V_TIME       ( V_TIME      )
        ) SRAM (
            .clk          ( clk         ),
            .rstn         ( rstn        ),
            .enb_i        ( enb_i       ),
            .size_i       ( size_i      ),
            .valid_o      ( valid_o[j]  ),
            .rdata_o      ( rdata_o[j]  )
        );
    end
    endgenerate

endmodule
