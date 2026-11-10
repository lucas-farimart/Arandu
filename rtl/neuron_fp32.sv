//=====================================================================
// Neuronio com multiplicador FP32 (mul.v)
//  - Operandos e resultado como FP32 (IEEE-754)
//  - mul.v nao possui valid/reset: latencia fixa de 9 clocks,
//    entao o valid_in eh atrasado por um shift register
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   08/05/2026
// Update: 05/11/2026
//=====================================================================

module neuron_fp32 #(
    parameter DATA_W  = 32,   // FP32
    parameter MUL_LAT = 9     // Latencia do mul.v
)(
    input  logic              clk,
    input  logic              rst_n,
    input  logic              neuron_done,
    input  logic              valid_in,
    output logic              valid_out,
    input  logic [DATA_W-1:0] x, w,
    output logic [DATA_W-1:0] acc
);

    //---------------------------------------------------------
    //  MULT OUTPUTS
    //---------------------------------------------------------
    logic               v0;
    logic [DATA_W-1:0]  p0;
    logic [DATA_W-1:0]  ps, ps_next;
    logic [MUL_LAT-1:0] vpipe;

    //---------------------------------------------------------
    //  FP32 MULTIPLIER (substitui booth_radix4)
    //---------------------------------------------------------
    mul mult0 (
        .clk   ( clk ),
        .mul_a ( x   ),
        .mul_b ( w   ),
        .mul_z ( p0  )
    );

    // alinha o valid com a latencia do multiplicador
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) vpipe <= '0;
        else        vpipe <= {vpipe[MUL_LAT-2:0], valid_in};
    end

    always_comb v0 = vpipe[MUL_LAT-1];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) valid_out <= 1'b0;
        else        valid_out <= v0;
    end

    //---------------------------------------------------------
    //  ACCUMULATOR (soma em ponto flutuante)
    //---------------------------------------------------------
    fp32_add u_acc_add (
        .a ( ps      ),
        .b ( p0      ),
        .z ( ps_next )
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)   ps <= 32'd0;
        else if (v0)  ps <= ps_next;
    end

    //---------------------------------------------------------
    //  ACTIVATION FUNC (ReLU) -> bit de sinal = 0 e valor != 0
    //---------------------------------------------------------
    always_comb begin
        acc = 32'd0;
        if (neuron_done) acc = ps[31] ? 32'd0 : ps;
    end

endmodule