//=====================================================================
// Unidade de Processamento Neural - NPU
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   08/05/2026
//=====================================================================

module npu #(
    parameter int DATA_W = 8
)(
    input  logic clk,
    input  logic rst_n,
    input  logic valid_in,
    output logic valid_out,

    input  logic signed  [DATA_W-1:0] x,
    input  logic signed  [DATA_W-1:0] w0,
    input  logic signed  [DATA_W-1:0] w1,
    input  logic signed  [DATA_W-1:0] w2,
    input  logic signed  [DATA_W-1:0] w3,

    output logic signed [31:0] acc0,
    output logic signed [31:0] acc1,
    output logic signed [31:0] acc2,
    output logic signed [31:0] acc3

);

    //---------------------------------------------------------
    // MULT OUTPUTS
    //---------------------------------------------------------
    logic signed [2*DATA_W-1:0] p0;
    logic signed [2*DATA_W-1:0] p1;
    logic signed [2*DATA_W-1:0] p2;
    logic signed [2*DATA_W-1:0] p3;
    logic v0;
    logic v1;
    logic v2;
    logic v3;

    //---------------------------------------------------------
    //  BOOTH MULTIPLIERS
    //---------------------------------------------------------

    booth_radix4 mult0 
    (
        .rst_n     ( rst_n     ),
        .clk       ( clk       ),
        .valid_in  ( valid_in  ),
        .a         ( x         ),
        .b         ( w0        ),
        .valid_out ( v0        ),
        .p         ( p0        )
    );

    booth_radix4 mult1 
    (
        .clk       ( clk       ),
        .rst_n     ( rst_n     ),
        .valid_in  ( valid_in  ),
        .a         ( x         ),
        .b         ( w1        ),
        .valid_out ( v1        ),
        .p         ( p1        )
    );

    booth_radix4 mult2 
    (
        .clk       ( clk       ),
        .rst_n     ( rst_n     ),
        .valid_in  ( valid_in  ),
        .a         ( x         ),
        .b         ( w2        ),
        .valid_out ( v2        ),
        .p         ( p2        )
    );

    booth_radix4 mult3 
    (
        .clk       ( clk       ),
        .rst_n     ( rst_n     ),
        .valid_in  ( valid_in  ),
        .a         ( x         ),
        .b         ( w3        ),
        .valid_out ( v3        ),
        .p         ( p3        )
    );

    always_ff @(posedge clk or negedge rst_n) valid_out <= v0;

    //---------------------------------------------------------
    // ACCUMULATORS
    //---------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc0 <= '0;
            acc1 <= '0;
            acc2 <= '0;
            acc3 <= '0;
        end
        else begin
            if (v0) begin
                acc0 <= acc0 + p0;
                acc1 <= acc1 + p1;
                acc2 <= acc2 + p2;
                acc3 <= acc3 + p3;
            end
        end
    end

endmodule