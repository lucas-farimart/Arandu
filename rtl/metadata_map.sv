//=====================================================================
// Network Metadata Mapping:
//   Larguras das camadas de entrada, saida e ocultas (16)
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   24/05/2026
//=====================================================================

module metadata_map #(
    parameter HIDDEN_BUFF = 8,
    parameter INPUT_BITS  = 18, // tamanho do array de entrada
    parameter HIDDEN_BITS = 16, // tamanho do array de pesos (linha da matriz)
    parameter OUTPUT_BITS = 10  // tamanho do array de saida
)(
    input  logic clk,
    input  logic rst_n,

    input  logic        io_enable_i,
    input  logic        hdn_enable_i,
    input  logic [3:0]  layers_i,
    input  logic [17:0] input_width_i,
    input  logic [9:0]  output_width_i,
    input  logic [5:0]  width_addr_i,
    input  logic [31:0] width_data_i,
 
    output logic [17:0] width_18_o,
    output logic [15:0] width_16_o
);

    //======================================================
    //  INTERNALS
    //======================================================
    logic [15:0] hidden_width_r [HIDDEN_BUFF];
    logic [15:0] input_width_r;
    logic [9:0]  output_width_r;

    //======================================================
    //  BUFFERS
    //======================================================

    // input / output
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_width_r  <= 'h0;
            output_width_r <= 'h0;
        end
        else if (io_enable_i) begin
            input_width_r  <= input_width_i;
            output_width_r <= output_width_i;
        end
    end

    // hiddens
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            hidden_width_r <= '{default: 0};
        else if (hdn_enable_i) begin
            hidden_width_r[width_addr_i  ] <= width_data_i[31:16];
            hidden_width_r[width_addr_i+1] <= width_data_i[15:0];
        end
    end

    //======================================================
    //  OUTPUT DECOD
    //======================================================
    always_comb begin
        case(width_addr_i)

            // REG 0: {input_width, hidden_1}
            6'h0: begin
                width_18_o = input_width_r;
                width_16_o = hidden_width_r[0];
            end

            // Ultimo registrador
            HIDDEN_BUFF-1: begin
                width_18_o = {2'b0,hidden_width_r[HIDDEN_BUFF-1][15:0]};
                width_16_o = {6'b0,output_width_r};
            end

            // REGs intermediarios: {hidden_i, hidden_i+1}
            default: begin 
                width_18_o = {2'b0,hidden_width_r[width_addr_i-1]};
                width_16_o = {2'b0,hidden_width_r[width_addr_i]}; 
            end

        endcase
    end

endmodule