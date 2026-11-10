//=====================================================================
// NPU considerando dataflow de 32 bits 
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   22/05/2026
//=====================================================================

module npu_32b #(
    parameter DATA_W = 8
)(
    input  logic clk,
    input  logic rst_n,

    input  logic valid_i,
    output logic valid_o,
    input  logic neuron_done,

    input  logic signed [DATA_W-1:0] x,
    input  logic signed [DATA_W-1:0] w0,
    input  logic signed [DATA_W-1:0] w1,
    input  logic signed [DATA_W-1:0] w2,
    input  logic signed [DATA_W-1:0] w3,

    output logic signed       [31:0] acc0,
    output logic signed       [31:0] acc1,
    output logic signed       [31:0] acc2,
    output logic signed       [31:0] acc3

);

    //---------------------------------------------------------
    //  NEURONS
    //---------------------------------------------------------
    neuron #(.DATA_W(8)) neuron_0 
    (
        .clk         ( clk          ),
        .rst_n       ( rst_n        ),
        .neuron_done ( neuron_done  ),
        .valid_in    ( valid_i      ),
        .valid_out   ( valid_o_0    ),
        .x           ( x            ),
        .w           ( w0           ),
        .acc         ( acc0         )
    );

    neuron #(.DATA_W(8)) neuron_1
    ( 
        .clk         ( clk          ),
        .rst_n       ( rst_n        ),
        .neuron_done ( neuron_done  ),
        .valid_in    ( valid_i      ),
        .valid_out   ( valid_o_1    ),
        .x           ( x            ),
        .w           ( w1           ),
        .acc         ( acc1         )
    );

    neuron #(.DATA_W(8)) neuron_2 
    (
        .clk         ( clk          ),
        .rst_n       ( rst_n        ),
        .neuron_done ( neuron_done  ),
        .valid_in    ( valid_i      ),
        .valid_out   ( valid_o_2    ),
        .x           ( x            ),
        .w           ( w2           ),
        .acc         ( acc2         )
    );

    neuron #(.DATA_W(8)) neuron_3 
    (
        .clk         ( clk          ),
        .rst_n       ( rst_n        ),
        .neuron_done ( neuron_done  ),
        .valid_in    ( valid_i      ),
        .valid_out   ( valid_o_3    ),
        .x           ( x            ),
        .w           ( w3           ),
        .acc         ( acc3         )
    );

    //---------------------------------------------------------
    //  OUT VALID
    //---------------------------------------------------------
    always_comb 
    valid_o = valid_o_0 && valid_o_1 && valid_o_2 && valid_o_3;

endmodule