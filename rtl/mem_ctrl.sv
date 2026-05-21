//=====================================================================
// Controlador de memoria externa DRAM
//   - Esconde latencia por meio de double-buffering
//   - Envia bytes sequencialmente (stream) 
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   18/05/2026
//=====================================================================

module mem_ctrl #(
    parameter ADDR_WIDTH   = 16,
    parameter DATA_WIDTH   = 32,
    parameter BUFFER_WORDS = 16
)(
    input  logic clk,
    input  logic rstn,
    input  logic start,
    input  logic done,

    input  logic [ADDR_WIDTH-1:0] base_addr,
    output logic [ADDR_WIDTH-1:0] dram_addr,
    input  logic [DATA_WIDTH-1:0] dram_rdata,
    input  logic                  dram_valid,
    output logic                  dram_req,

    output logic [7:0] out_data,
    output logic       out_valid
);

    //======================================================
    //  INTERNALS
    //======================================================
    localparam BYTES = DATA_WIDTH/8;
    logic                     streamed;
    logic                     ping_read;
    logic [$clog2(BYTES)-1:0] stream_ptr;
    logic    [ADDR_WIDTH-1:0] current_addr;
    logic    [DATA_WIDTH-1:0] ping;
    logic               [7:0] pong [BYTES];

    typedef enum logic [3:0] {IDLE,REQ,WAIT,STREAM,DONE} state_t;
    state_t CS, NS;
    
    //======================================================
    //  STATES
    //======================================================
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) CS <= IDLE;
        else       CS <= NS;
    end

    always_comb begin
        case(CS)
            REQ:    NS = WAIT;
            IDLE:   NS = (start)      ? REQ    : IDLE;
            WAIT:   NS = (dram_valid) ? STREAM : WAIT;
            STREAM: NS = (streamed)   ? DONE   : STREAM;
            DONE:   NS = (done)       ? IDLE   : WAIT;
        endcase
    end

    //======================================================
    //  ADDRESS BUFFERS
    //======================================================
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) 
            current_addr <= 'h0;
        else if (dram_valid) 
            current_addr <= current_addr+1;
    end

    always_comb dram_addr = current_addr;
    always_comb dram_req  = (CS==REQ) || (CS==STREAM && !out_valid);

    //======================================================
    //  DOUBLE BUFFERING (PING and PONG)
    //======================================================
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn)           ping <= 'h0;
        else if (dram_valid) ping <= dram_rdata;
    end

    always_ff @(posedge clk or negedge rstn) begin
        ping_read <= (rstn) ? (NS==STREAM) && (CS==WAIT) : 0;
        out_valid <= (rstn) ? (CS==STREAM) : 0;
    end

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin 
            foreach(pong[i]) 
            pong[i] <= 'h0;
            // out_data <= 'h0;
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
                // out_data <= pong[BYTES-1];
            end
        end
    end

    //======================================================
    //  STREAM POINTER 
    //======================================================
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) 
            stream_ptr <= 'h0;
        else begin
            if(out_valid) 
                stream_ptr <= stream_ptr+1;
            else 
                stream_ptr <= 0;
        end
    end

    always_comb out_data = pong[BYTES-1];
    always_comb streamed = (stream_ptr == $clog2(BYTES));

endmodule 