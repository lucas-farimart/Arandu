//=====================================================================
// Modelo de memoria externa DRAM com latencia ajustavel
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   19/05/2026
//=====================================================================

module dram_model #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32,
    parameter MEM_WORDS  = 4096,
    parameter LATENCY    = 12
)(
    input  logic                  clk,
    input  logic                  rstn,
    input  logic                  req,
    output logic                  valid,
    input  logic [ADDR_WIDTH-1:0] addr,
    output logic [DATA_WIDTH-1:0] rdata
);

    //=========================================================
    // Memoria / Controle interno
    //=========================================================
    logic [DATA_WIDTH-1:0] mem [0:MEM_WORDS-1];
    logic                  busy;
    logic                  cooldown;
    logic [ADDR_WIDTH-1:0] latched_addr;
    integer                latency_counter;

    //=========================================================
    // Modelo DRAM
    //=========================================================

    always_ff @(posedge clk or posedge rstn) begin

        if (!rstn) begin
            valid  <= 0;     cooldown         <= 0;
            rdata  <= 0;     latched_addr     <= 0;
            busy   <= 0;     latency_counter  <= 0;
        end
        else begin

            if (cooldown) 
            cooldown <= 0; // Cooldown de 1 ciclo apos resposta valida
            valid <= 0; // valid dura apenas 1 ciclo

            // DRAM ocupada processando acesso
            if (busy) begin

                latency_counter <= latency_counter - 1;

                // Dados prontos
                if (latency_counter == 1) begin
                    rdata <= mem[latched_addr];
                    valid <= 1;
                    busy <= 0;
                    cooldown <= 1;
                end
            end
            
            // Nova requisicao
            else if (req && !cooldown) begin
                busy <= 1;
                latched_addr <= addr;
                latency_counter <= LATENCY + $urandom_range(1,5);
            end
        end
    end

endmodule