//=====================================================================
// Unidade de Processamento Neural - NPU
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   08/05/2026
//=====================================================================

module neuron #(
    parameter DATA_W = 8
)(
    input  logic                      clk,
    input  logic                      rst_n,
    input  logic                      valid_in,
    output logic                      valid_out,
    input  logic signed  [DATA_W-1:0] x,
    input  logic signed  [DATA_W-1:0] w,
    output logic signed        [31:0] acc,
);

    //---------------------------------------------------------
    // MULT OUTPUTS
    //---------------------------------------------------------
    logic signed [2*DATA_W-1:0] p0;
    logic signed [4*DATA_W-1:0] ps;
    logic v0;

    //---------------------------------------------------------
    //  BOOTH MULTIPLIERS
    //---------------------------------------------------------
    booth_radix4 mult0 
    (
        .rst_n     ( rst_n     ),
        .clk       ( clk       ),
        .valid_in  ( valid_in  ),
        .a         ( x         ),
        .b         ( w         ),
        .valid_out ( v0        ),
        .p         ( p0        )
    );

    always_ff @(posedge clk or negedge rst_n) valid_out <= v0;

    //---------------------------------------------------------
    // ACCUMULATORS
    //---------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ps <= '0;
        end
        else begin
            if (v0) begin
                ps <= ps + p0;
            end
        end
    end

    //---------------------------------------------------------
    // ACTIVATION FUNC (ReLU)
    //---------------------------------------------------------
    always_comb begin
        acc = 'h0;
        if(neuron_done) acc = (ps>0) ? ps : 'h0;
    end


endmodule