//=====================================================================
// Stack de neuronios
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   07/05/2026
//=====================================================================

module neuron_stack #(
    parameter DATA_W = 8,
    parameter DEPTH  = 64,
    parameter ADDR_W = $clog2(DEPTH+1)
)(
    input  logic                      clk,
    input  logic                      rst_n,
    //--------------------------------------- Controle 
    input  logic                      push,
    input  logic                      pop,
    //------------------------------------------ Dados 
    input  logic signed [DATA_W-1:0]  data_in,
    output logic signed [DATA_W-1:0]  data_out,
    //----------------------------------------- Status 
    output logic                      full,
    output logic                      empty,
    output logic        [ADDR_W-1:0]  level  // num de elementos validos
);

    //========================================================
    //  Internos
    //========================================================
    logic signed [DATA_W-1:0] stack_mem [0:DEPTH-1]; // Memoria
    logic        [ADDR_W-1:0] s_ptr;      // Stack pointer (zero counter)
    logic          [ADDR_W:0] zero_count; // num de zeros descartados
    logic                     push_valid;

    //========================================================
    //  Logica combinacional 
    //========================================================
    always_comb push_valid = push && (data_in != 0);
    always_comb empty = (s_ptr == 0);
    always_comb full  = (s_ptr == DEPTH);
    always_comb level = s_ptr;

    //========================================================
    //  Byte de saida e ponteiro
    //========================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_ptr    <= '0;
            data_out <= '0;
        end
        else begin
            case ({push_valid, pop})
                2'b00: begin
                end
                2'b10: begin // PUSH
                    if (!full) begin
                        stack_mem[s_ptr] <= data_in;
                        s_ptr            <= s_ptr + 1'b1;
                    end
                end
                2'b01: begin // POP
                    if (!empty) begin
                        data_out <= stack_mem[s_ptr-1];
                        s_ptr    <= s_ptr - 1'b1;
                    end
                end
                2'b11: begin // PUSH + POP
                    if (!empty) begin
                        data_out <= stack_mem[s_ptr-1]; // retorna topo atual
                        stack_mem[s_ptr-1] <= data_in;  // substitui topo
                    end
                    else begin // stack vazia
                        if (!full) begin
                            stack_mem[s_ptr] <= data_in;
                            s_ptr            <= s_ptr + 1'b1;
                        end
                    end
                end
            endcase
        end
    end

    

    //========================================================
    //  Contador de zeros
    //========================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)                      
            zero_count <= '0;
        else if (push && (data_in == 0)) 
            zero_count <= zero_count + 1'b1;
    end

endmodule