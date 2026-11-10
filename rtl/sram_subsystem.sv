//================================================================
// Controlador de memoria & Gerador de burst
//----------------------------------------------------------------
// Autor: Lucas Farias Martins
// Email: lucas.martins@ee.ufcg.edu.br
// Data:  15-10-2026
//================================================================

module sram_subsystem #(
    parameter int  ADDR_W      = 9,
    parameter int  DATA_W      = 32,
    parameter int  DEPTH       = 512,
    parameter int  MAX_SIZE    = 4,
    parameter time SYS_CLOCK   = 2ns,
    parameter time MEM_LATENCY = 8ns,
    parameter time V_TIME      = 2ns
)(
    input  logic              clk,
    input  logic              rstn,
    input  logic              enb_i,
    input  logic [3:0]        size_i,
    output logic              valid_o,
    output logic [DATA_W-1:0] rdata_o
);

    //==========================================================
    //  Internos
    //==========================================================
    logic  next_is_send;
    logic  curr_is_idle;
    logic  curr_is_wait;

    logic [MAX_SIZE-1:0]   req;
    logic [MAX_SIZE-1:0]   we;
    logic [MAX_SIZE-1:0]   valid;
    logic [MAX_SIZE-1:0]   busy;
    
    logic [ADDR_W-1:0] addr;
    logic [DATA_W-1:0] wdata [MAX_SIZE];
    logic [DATA_W-1:0] rdata [MAX_SIZE];

    //==========================================================
    //  Write Data Assignment
    //==========================================================
    generate
    for (genvar l = 0; l < MAX_SIZE; l++) begin
        always_ff @(posedge clk or negedge rstn) begin : wdata_gen
            if (!rstn)           wdata[l] <= '0;
            else if(req[size_i]) wdata[l] <= '0;
        end
    end
    endgenerate

    //==========================================================
    //  Address Generator
    //==========================================================
    always_ff @(posedge clk or negedge rstn) begin : addr_gen
        if (!rstn)           addr <= '0;
        else if(req[size_i]) addr <= addr + 1;
    end

    //==========================================================
    //  Maquina de estados para requisicao (req) 
    //==========================================================
    typedef enum logic [1:0] {
        IDLE_REQ, 
        SEND_REQ, 
        WAIT_REQ
    } state_req;

    state_req  CS_REQ, NS_REQ; 

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) CS_REQ <= IDLE_REQ;
        else       CS_REQ <= NS_REQ;
    end

    `ifdef USE_SRAM
        always_comb begin
            case (CS_REQ)
                IDLE_REQ: NS_REQ = (enb_i) ? SEND_REQ : IDLE_REQ;
                SEND_REQ: NS_REQ = (req[size_i]) ? WAIT_REQ : SEND_REQ;
                WAIT_REQ: NS_REQ = SEND_REQ;
                default:  NS_REQ = IDLE_REQ;
            endcase
        end
    `else
        always_comb begin
            case (CS_REQ)
                IDLE_REQ: NS_REQ = (enb_i) ? SEND_REQ : IDLE_REQ;
                SEND_REQ: NS_REQ = (req[size_i]) ? WAIT_REQ : SEND_REQ;
                WAIT_REQ: NS_REQ = (valid[0])  ? SEND_REQ : WAIT_REQ;
                default:  NS_REQ = IDLE_REQ;
            endcase
        end
    `endif

    always_comb next_is_send = (NS_REQ==SEND_REQ);
    always_comb curr_is_wait = (CS_REQ==WAIT_REQ);
    always_comb curr_is_idle = (CS_REQ==IDLE_REQ);
    always_comb we = (CS_REQ == SEND_REQ);
    // assign we = '0;  // só leitura por enquanto
    
    //==========================================================
    //  Maquina de estados para resposta (rsp) 
    //==========================================================
    // Ajeitar depois para valid[i] && size > SIZE
    typedef enum logic [2:0] {
        IDLE_RSP, 
        GET_RSP_0,
        GET_RSP_1,
        GET_RSP_2,
        GET_RSP_3,
        WAIT_RSP
    } state_rsp;

    state_rsp  CS_RSP, NS_RSP; 
    
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) CS_RSP <= IDLE_RSP;
        else       CS_RSP <= NS_RSP;
    end

    `ifdef USE_SRAM
        always_comb begin
            case (CS_RSP)
                IDLE_RSP:  NS_RSP = (enb_i)       ? WAIT_RSP  : IDLE_RSP;
                WAIT_RSP:  NS_RSP = (req[size_i]) ? GET_RSP_0 : WAIT_RSP;
                GET_RSP_0: NS_RSP = GET_RSP_1;
                GET_RSP_1: NS_RSP = GET_RSP_2;
                GET_RSP_2: NS_RSP = GET_RSP_3;
                GET_RSP_3: NS_RSP = WAIT_RSP;
                default:   NS_RSP = IDLE_RSP;
            endcase
        end  
    `else
        always_comb begin
            case (CS_RSP)
                IDLE_RSP:  NS_RSP = (enb_i)       ? WAIT_RSP  : IDLE_RSP;
                WAIT_RSP:  NS_RSP = (req[size_i]) ? GET_RSP_0 : WAIT_RSP;
                GET_RSP_0: NS_RSP = (valid[0])    ? GET_RSP_1 : GET_RSP_0;
                GET_RSP_1: NS_RSP = (valid[1])    ? GET_RSP_2 : GET_RSP_1;
                GET_RSP_2: NS_RSP = (valid[2])    ? GET_RSP_3 : GET_RSP_2;
                GET_RSP_3: NS_RSP = (valid[3])    ? WAIT_RSP  : GET_RSP_3;
                default:   NS_RSP = IDLE_RSP;
            endcase
        end
    `endif

    //===================================================
    //  Requisition Shift Array
    //===================================================
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) 
            req[MAX_SIZE-1:1] <= '0;
        else begin 
            if (NS_REQ==SEND_REQ) 
                req[MAX_SIZE-1:1] <= {req[MAX_SIZE-2:1], req[0]};
            else
                req[MAX_SIZE-1:1] <= '0;
        end
    end

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) 
            req[0] <= 0;
        else begin 
            if ((enb_i && curr_is_idle) || (next_is_send && curr_is_wait))
                req[0] <= 1;
            else
                req[0] <= 0;
        end
    end   

    //===================================================
    //  Memory MAX_SIZE
    //===================================================
    generate
    for (genvar j=0; j<MAX_SIZE; j++) begin : mem_gen

    `ifdef USE_SRAM
        sram_32x512_1rw u_mem 
        (
            .clk0  ( clk      ),
            .csb0  ( req[j]   ),
            .web0  ( we[j]    ),
            .addr0 ( addr     ),
            .din0  ( wdata[j] ),
            .dout0 ( rdata[j] ) 
        );
    `else
        memory_model #(
            .ADDR_W   ( ADDR_W      ),
            .DATA_W   ( DATA_W      ),
            .DEPTH    ( DEPTH       ),
            .LATENCY  ( MEM_LATENCY ),
            .V_TIME   ( V_TIME      )
        ) u_mem (
            .clk      ( clk         ),
            .req      ( req[j]      ),
            .we       ( we[j]       ),    
            .addr     ( addr        ),
            .wdata    ( wdata[j]    ),
            .rdata    ( rdata[j]    ),
            .valid    ( valid[j]    ),
            .busy     ( busy[j]     )
        );
    `endif

    end
    endgenerate

    //===================================================
    //  Valid Read Data 
    //===================================================
    always_comb begin
        case (CS_RSP)
            GET_RSP_0: rdata_o = rdata[0];
            GET_RSP_1: rdata_o = rdata[1];
            GET_RSP_2: rdata_o = rdata[2];
            GET_RSP_3: rdata_o = rdata[3];
            default:   rdata_o = '1;
        endcase
    end

    `ifdef USE_SRAM
        always_comb valid_o = '0;
    `else
        always_comb valid_o = |valid; // qualquer valid vale
    `endif

endmodule