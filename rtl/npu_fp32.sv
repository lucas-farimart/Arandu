//=====================================================================
// NPU: Unidade de Processamento Neural para FP32 
//  - 4 neuronios em paralelo
//  - 2 subsistemas de memoria SRAM (pesos e ativacoes) 
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   22/05/2026
// Update: 05/11/2026
//=====================================================================

module npu_fp32 #(
    parameter DATA_W  = 32,
    parameter NEURONS = 4,
    parameter MUL_LAT = 9
)(
    input  logic clk,
    input  logic rst_n,

    input  logic               valid_i,
    output logic               valid_o,
    input  logic               neuron_done,
    input  logic               write_shift,
    input  logic [DATA_W-1:0]  x_i,
    input  logic [DATA_W-1:0]  w_i [NEURONS],
    output logic [DATA_W-1:0]  acc_o
);

    //============================================================= 
    //  INTERNOS
    //=============================================================
    logic [DATA_W-1:0]   acc_r [NEURONS];   // Dados para FIFO
    logic [DATA_W*4-1:0] shift_acc_r;       // FIFO para escrever
    logic                valid_n [NEURONS]; // Processamento feito

    //=============================================================
    //  NEURONIOS
    //=============================================================
    generate
    for (genvar i=0; i<NEURONS; ++i) begin 
        neuron_fp32 #(
            .DATA_W      ( DATA_W       ),
            .MUL_LAT     ( MUL_LAT      )
        ) NEURON (
            .clk         ( clk          ),
            .rst_n       ( rst_n        ),
            .neuron_done ( neuron_done  ),
            .valid_in    ( valid_i      ),
            .valid_out   ( valid_n[i]   ),
            .x           ( x_i          ),
            .w           ( w_i[i]       ),
            .acc         ( acc_r[i]     )
        );
    end
    endgenerate

    //=============================================================
    //  256-to-32 SHIFT REGISTERS
    //=============================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_acc_r <= '0;
        end else begin
            if(neuron_done) begin
                shift_acc_r[4*DATA_W-1:3*DATA_W] <= acc_r[0];
                shift_acc_r[3*DATA_W-1:2*DATA_W] <= acc_r[1];
                shift_acc_r[2*DATA_W-1:1*DATA_W] <= acc_r[2];
                shift_acc_r[1*DATA_W-1:0*DATA_W] <= acc_r[3];
            end 
            else if (write_shift) begin
                shift_acc_r <= {shift_acc_r[3*DATA_W-1:0], {DATA_W{1'b0}}};
            end
        end
    end

    //=============================================================
    //  OUT DATA/VALID
    //=============================================================
    always_comb begin
        valid_o = valid_n[0] || valid_n[1] || valid_n[2] || valid_n[3];
        acc_o = shift_acc_r[4*DATA_W-1:3*DATA_W];
    end


endmodule