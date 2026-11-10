//=====================================================================
// Arandu Core
//   32b floating point NPU + 2 SRAM Subsystem (2GB/s)
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   11/05/2026
// Update: 06/11/2026
//=====================================================================

module arandu_core #(
    parameter int  NEURONS     = 4,    
    parameter int  MUL_LAT     = 9,
    parameter int  ADDR_W      = 9,
    parameter int  DATA_W      = 32,
    parameter int  WORD_W      = 4*DATA_W, // 256
    parameter int  DEPTH       = 512,
    parameter int  MAX_SIZE    = 4,
    parameter time SYS_CLOCK   = 2ns,
    parameter time MEM_LATENCY = 8ns,
    parameter time V_TIME      = 2ns
)(
    input  logic       clk,
    input  logic       rst_n,
    input  logic       enb_i,
    input  logic       we_i,
    input  logic [3:0] size_i,
    input  logic       actv_selx_i,
    input  logic       actv_sely_i

    //-------------------------------------
    // PROXIMA ETAPA:
    //  - Dados de ESCRITA (DRAM -> SRAM) 
    //-------------------------------------
);

    //=========================================================
    //  SIGNALS
    //=========================================================
    logic [DATA_W-1:0]  weight_rdata [NEURONS];
    logic [DATA_W-1:0]  actv_wdata;
    logic [DATA_W-1:0]  actv_rdata;

    logic  [NEURONS-1:0] weight_valid;
    logic  [NEURONS-1:0] npu_valids;    
    logic  actv_valid;
    logic  npu_i_valid;
    logic  npu_o_valid;
    logic  neuron_done;
    logic  write_shift;

    //=========================================================
    //  NPU INSTANCE
    //=========================================================
    always_comb begin
        npu_valids[0] = actv_valid && weight_valid[0];
        npu_valids[1] = actv_valid && weight_valid[1];
        npu_valids[2] = actv_valid && weight_valid[2];
        npu_valids[3] = actv_valid && weight_valid[3];
        npu_i_valid   = &npu_valids;
    end

    npu_fp32 #(
        .DATA_W       ( DATA_W  ),
        .MUL_LAT      ( MUL_LAT )
    ) NPU (
        .clk          ( clk          ),
        .rst_n        ( rst_n        ),
        .valid_i      ( npu_i_valid  ),
        .valid_o      ( npu_o_valid  ),
        .neuron_done  ( neuron_done  ),
        .write_shift  ( write_shift  ),
        .x_i          ( actv_rdata   ),
        .w_i          ( weight_rdata ),
        .acc_o        ( actv_wdata   )
    );

    //=========================================================
    //  Weights Memory
    //=========================================================
    mem_weights #(
        .NEURONS      ( NEURONS      ),
        .ADDR_W       ( ADDR_W       ),
        .DATA_W       ( DATA_W       ),
        .DEPTH        ( DEPTH        ),
        .MAX_SIZE     ( MAX_SIZE     ),
        .SYS_CLOCK    ( SYS_CLOCK    ),
        .MEM_LATENCY  ( MEM_LATENCY  ),
        .V_TIME       ( V_TIME       )
    ) WEIGHT (
        .clk          ( clk          ),
        .rstn         ( rstn         ),
        .enb_i        ( enb_i        ),
        .size_i       ( size_i       ),
        .valid_o      ( weight_valid ),
        .rdata_o      ( weight_rdata )
    );

    //=========================================================
    //  Activation Memory
    //=========================================================
    mem_actvs #(
        .ADDR_W      ( ADDR_W      ),
        .DATA_W      ( DATA_W      ),
        .DEPTH       ( DEPTH       ),
        .MAX_SIZE    ( MAX_SIZE    ),
        .SYS_CLOCK   ( SYS_CLOCK   ),
        .MEM_LATENCY ( MEM_LATENCY ),
        .V_TIME      ( V_TIME      )
    ) ACTV (
        .clk         ( clk         ),
        .rstn        ( rstn        ),
        .selx_i      ( actv_selx_i ),
        .sely_i      ( actv_sely_i ),
        .enb_i       ( enb_i       ),
        .we_i        ( we_i        ),
        .size_i      ( size_i      ),
        .wdata_i     ( actv_wdata  ),
        .rdata_o     ( actv_rdata  ),
        .valid_o     ( actv_valid  )
    );


endmodule