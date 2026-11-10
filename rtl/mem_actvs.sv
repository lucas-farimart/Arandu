//================================================================
// Subsistema de Memoria SRAM para Pesos
//----------------------------------------------------------------
// Autor: Lucas Farias Martins
// Email: lucas.martins@ee.ufcg.edu.br
// Data:  09-11-2026
//================================================================

module mem_actvs #(
    parameter int  ADDR_W      = 9,
    parameter int  DATA_W      = 32,
    parameter int  DEPTH       = 512,
    parameter int  MAX_SIZE    = 4,
    parameter time SYS_CLOCK   = 2ns,
    parameter time MEM_LATENCY = 8ns,
    parameter time V_TIME      = 2ns
)(
    input  logic              clk,
    input  logic              rstn,

    input  logic              selx_i,
    input  logic              sely_i,
    
    input  logic              enb_i,
    input  logic              we_i,
    input  logic [3:0]        size_i,
    input  logic [DATA_W-1:0] wdata_i,
    output logic [DATA_W-1:0] rdata_o,
    output logic              valid_o
);

    //===================================================
    //  Internos
    //===================================================
    logic [DATA_W-1:0] rdata_r [2]; // MUX
    logic [DATA_W-1:0] wdata_r [2]; // DEMUX
    logic              valid_r [2];
    logic              we_r [2];

    //===================================================
    //  MUX/DEMUX
    //===================================================
    always_comb begin
        //----- MUX
        rdata_o = (selx_i && enb_i) ? rdata_r[0] : rdata_r[1];
        valid_o = (selx_i && enb_i) ? valid_r[0] : valid_r[1];
        //----- DEMUX
        wdata_r[0] = ( sely_i && enb_i) ? wdata_i : '0;
        wdata_r[1] = (~sely_i && enb_i) ? wdata_i : '0;
        we_r[0] = ( sely_i) ? we_i : 0;
        we_r[1] = (~sely_i) ? we_i : 0;
    end

    //===================================================
    //  Memory Arrangement
    //===================================================
    generate
    for (genvar j=0; j<2; j++) begin : actv_gen
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
            .valid_o      ( valid_r[j]  ),
            .rdata_o      ( rdata_r[j]  )
        );
    end
    endgenerate

endmodule
