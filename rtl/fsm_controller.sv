//=====================================================================
// Finite State Machine:
//   Gerencia as flags para o Core e submodulos
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   08/06/2026
//=====================================================================

module fsm_controller #(
    parameter VECTOR_SIZE = 8,
    parameter MTXROW_SIZE = 8
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start_i,
    input  logic        first_i, 
    input  logic        last_i, 
    input  logic        pop_result_i,
    input  logic        mem_valid_i,
    input  logic        w_model_i,

    input  logic [17:0] lnest0_i,
    input  logic [15:0] lnest1_i,
    output logic        io_enable_o,
    output logic        hdn_enable_o,
    output logic        incr_layer_o,
    output logic        incr_addr_o,
    output logic        mem_enb_o,

    output logic        push_a_o,
    output logic        push_b_o,
    output logic        pop_a_o,
    output logic        pop_b_o,
    output logic        clean_a_o,
    output logic        clean_b_o,
    output logic        rc_pop_a_o,
    output logic        rc_pop_b_o,
    output logic        rc_push_a_o,
    output logic        rc_push_b_o
    
);

    //==========================================================
    //  Internos
    //==========================================================
    typedef enum logic [4:0] {
        IDLE,       INOUT_CFG,
        MODEL_CFG,  IS_INPUT,
        PUSH_IN,    RC_POP,
        PUSH_ON,    RC_PUSH,
        IS_LAST,    DONE
    } state_t;

    state_t      CS, NS;
    logic        all_cols;
    logic        all_rows;
    logic        alter_read;
    logic        alter_stack;
    logic [16:0] row_cnt, col_cnt;

    //==========================================================
    //                   MAQUINA DE ESTADOS 
    //              Atual e Proximo desacoplados
    //==========================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) CS <= IDLE;
        else        CS <= NS;
    end

    always_comb begin
        case (CS)
            IDLE:      NS = (start_i)     ? INOUT_CFG : IDLE; 
            INOUT_CFG: NS = (mem_valid_i) ? MODEL_CFG : INOUT_CFG;
            MODEL_CFG: NS = (w_model_i)   ? IS_INPUT  : MODEL_CFG;
            IS_INPUT:  NS = (first_i)     ? PUSH_IN   : RC_POP;
            PUSH_IN:   NS = (all_cols)    ? RC_POP    : PUSH_IN;
            RC_POP:    NS = (all_cols)    ? PUSH_ON   : RC_POP; 
            RC_PUSH:   NS = (all_cols)    ? PUSH_ON   : RC_PUSH;
            PUSH_ON: begin
                if(all_rows)        NS = IS_LAST;
                else if(alter_read) NS = RC_POP; 
                else                NS = RC_PUSH; 
            end
            IS_LAST:   NS = (last_i)        ? IS_INPUT : RC_POP;
            DONE:      NS = (!pop_result_i) ? DONE     : IDLE;
            default:   NS = IDLE;
        endcase
    end

    //==========================================================
    //  Contadores 
    //==========================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            col_cnt <= 0;
            row_cnt <= 0;
        end
        else begin
            case(CS)
                IDLE:    col_cnt <= '0;
                PUSH_IN: col_cnt <= (all_cols) ? '0 : col_cnt + 1;
                RC_POP:  col_cnt <= (all_cols) ? '0 : col_cnt + 1;
                RC_PUSH: col_cnt <= (all_cols) ? '0 : col_cnt + 1;
                PUSH_ON: row_cnt <= (all_rows) ? '0 : row_cnt + 1; 
                // default: col_cnt <= col_cnt;
            endcase
        end
    end

    //==========================================================
    //  Flags alternadoras
    //==========================================================
    always_comb all_cols = (col_cnt == lnest0_i-1);
    always_comb all_rows = (row_cnt == lnest1_i-1);

    // Alternadora de colunas
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            alter_read <= 0;
        else begin
            case(CS)
                IDLE:    alter_read <= 0;
                PUSH_IN: alter_read <= 1;
                RC_POP:  alter_read <= (all_cols) ? ~alter_read : alter_read;
                RC_PUSH: alter_read <= (all_cols) ? ~alter_read : alter_read;
                // PUSH_ON: alter_read <= 0;
            endcase
        end
    end

    // Alternadora de linhas
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            alter_stack <= 0;
        else if(CS==PUSH_ON) 
            alter_stack <= (all_rows) ? ~alter_stack : alter_stack;
    end


    //==========================================================
    //  Saidas para escrita de metadados e 
    //  controlador de memoria
    //==========================================================  
    always_comb io_enable_o   = (CS==INOUT_CFG) && mem_valid_i;
    always_comb hdn_enable_o  = (CS==MODEL_CFG) && mem_valid_i;
    always_comb incr_layer_o  = (CS==IS_LAST) || (CS==IS_INPUT);
    always_comb incr_addr_o   = (CS==PUSH_ON);
    always_comb mem_enb_o     = io_enable_o || hdn_enable_o;


    //==========================================================
    //  Saidas para as pilhas
    //==========================================================    
    // always_comb pop_b_o     = (CS==POP_OUT && ~alter_stack) ? 1'b1 : 1'b0;
    // always_comb pop_a_o     = (CS==POP_OUT &&  alter_stack) ? 1'b1 : 1'b0;
    always_comb push_b_o    = (CS==PUSH_ON && ~alter_stack) ? 1'b1 : 1'b0;
    always_comb push_a_o    = (CS==PUSH_ON &&  alter_stack) ? 1'b1 : 1'b0;

    always_comb rc_pop_a_o  = (CS==RC_POP  && ~alter_stack) ? alter_read  : 1'b0;
    always_comb rc_pop_b_o  = (CS==RC_POP  &&  alter_stack) ? alter_read  : 1'b0;
    always_comb rc_push_a_o = (CS==RC_PUSH && ~alter_stack) ? ~alter_read : 1'b0;
    always_comb rc_push_b_o = (CS==RC_PUSH &&  alter_stack) ? ~alter_read : 1'b0;


endmodule