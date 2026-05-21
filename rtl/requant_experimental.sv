//=====================================================================
// Modulo PARAMETRIZADO de requantizacao simples com arredondamento
//   - Atualmente NAO esta sendo usado
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   20/05/2026
//=====================================================================

//------------------------------------------
//  Unit
//------------------------------------------
module requant_round #(
    parameter SHIFT = 7
)(
    input  logic signed [31:0] acc_i,
    output logic signed [7:0]  q_o
);

    logic signed [31:0] rounded;
    logic signed [31:0] shifted;

    localparam logic signed [31:0] ROUND = (1 <<< (SHIFT-1));

    always_comb begin

        rounded = acc_i + ROUND;     // rounding
        shifted = rounded >>> SHIFT; // shifting

        // saturationing?
        if (shifted > 127)       q_o = 8'sd127;
        else if (shifted < -128) q_o = -8'sd128;
        else                     q_o = shifted[7:0];
    end

endmodule

//------------------------------------------
//  Top Module
//------------------------------------------
module requant_unit #(
    parameter OUTPUTS = 4,
    parameter SHIFT   = 7
)(
    input  logic signed [31:0] acc_i [OUTPUTS],
    output logic signed [7:0]  q_o   [OUTPUTS],
);

    generate;
    for (genvar i=0; i<OUTPUTS; ++i) begin
        requant_round #(.SHIFT (7)) req_u (.acc_i(acc_i[i]),.q_o(q_i[i]));
    end
    endgenerate

endmodule