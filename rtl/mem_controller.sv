//=====================================================================
// Controlador de memoria externa DRAM
//   - Esconde latencia por meio de double-buffering
//   - Envia bytes sequencialmente (stream) 
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   18/05/2026
//=====================================================================

module mem_controller
(
    input  logic clk,
    input  logic rst_n,

    input  logic        start_i,
    input  logic        enb_i,
    input  logic [15:0] base_addr_i,
    output logic [15:0] dram_addr_o,
    input  logic [31:0] dram_rdata_i,
    input  logic        dram_valid_i,
    output logic        dram_req_o,

    output logic [7:0]  out_byte,
    output logic [31:0] out_word,
    output logic        out_valid
);

    //======================================================
    //  INTERNALS
    //======================================================
    localparam   BYTES = 4;
    logic        streamed;
    logic        ping_read;
    logic  [1:0] stream_ptr;
    logic [15:0] current_addr;
    logic [31:0] ping;
    logic  [7:0] pong [4];

    typedef enum logic [3:0] {IDLE,REQ,WAIT,STREAM,DONE} state_t;
    state_t CS, NS;
    
    //======================================================
    //  STATES
    //======================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) CS <= IDLE;
        else        CS <= NS;
    end

    always_comb begin
        case(CS)
            IDLE:   NS = (start_i)      ? REQ    : IDLE;
            WAIT:   NS = (dram_valid_i) ? STREAM : WAIT;
            REQ:    NS = WAIT;
            STREAM: NS = (streamed)     ? DONE   : STREAM;
            DONE:   NS = WAIT;
        endcase
    end

    //======================================================
    //  BUFFERS ADDRESS
    //======================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            current_addr <= 'h0;
        else if (dram_valid_i) 
            current_addr <= current_addr+1;
    end

    // always_comb dram_req_o  = (CS==REQ) && enb_i;
    always_comb dram_req_o  = (CS==REQ) || (CS==STREAM && !out_valid);
    always_comb dram_addr_o = current_addr;

    //======================================================
    //  DOUBLE BUFFERING (PING and PONG)
    //======================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)            ping <= 'h0;
        else if (dram_valid_i) ping <= dram_rdata_i;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        ping_read <= (rst_n) ? (NS==STREAM) && (CS==WAIT) : 0;
        out_valid <= (rst_n) ? (CS==STREAM) : 0;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin 
            foreach(pong[i]) 
            pong[i] <= 'h0;
            // out_byte <= 'h0;
        end
        else begin 
            if (ping_read) begin
                pong[3] <= ping[31:24];
                pong[2] <= ping[23:16];
                pong[1] <= ping[15:8];
                pong[0] <= ping[7:0];
            end
            else begin
                for (int i=1; i<BYTES-1; ++i)
                pong[i] <= pong[i-1];
                pong[0] <= 'h0;
                pong[BYTES-1] <= pong[BYTES-2];    
                // out_byte <= pong[BYTES-1];
            end
        end
    end

    //======================================================
    //  STREAM POINTER 
    //======================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            stream_ptr <= 'h0;
        else begin
            if(out_valid) stream_ptr <= stream_ptr+1;
            else          stream_ptr <= 0;
        end
    end

    always_comb out_byte = pong[BYTES-1];
    always_comb out_word = {pong[0],pong[2],pong[3],pong[3]};
    always_comb streamed = (stream_ptr == $clog2(BYTES));

endmodule 