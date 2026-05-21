//=====================================================================
// Testbench: Booth algorithm for 8b multiplication 
// Description:
//   Verifies the operation functionality, throughput, latency, etc
//---------------------------------------------------------------------
// Author: Lucas Farias Martins
// Email:  lucas.martins@ee.ufcg.edu.br
// Date:   05/05/2026
//=====================================================================

`timescale 1ns/1ns

module tb_booth;

    logic                clk;
    logic                rst_n;
    logic                valid_in;
    logic signed  [7:0]  a_in, b_in;
    logic                valid_out;
    logic signed [15:0]  p_out;

    //---------------------------------
    // DUT
    //---------------------------------
    booth_radix4 dut (
        .clk       ( clk         ),
        .rst_n     ( rst_n       ),
        .valid_in  ( valid_in    ),
        .valid_out ( valid_out   ),
        .a         ( a_in        ),
        .b         ( b_in        ),
        .p         ( p_out       )
    );

    // clock
    always #5 clk = ~clk;

    //---------------------------------
    // Scoreboard com ID
    //---------------------------------
    typedef struct {
        int id;
        logic signed [7:0]  a;
        logic signed [7:0]  b;
        logic signed [15:0] expected;
    } txn_t;

    txn_t queue[$], t;
    int   tx_id = 0;

    //---------------------------------
    // Reset
    //---------------------------------
    task reset_dut();
        rst_n = 0;
        valid_in = 0;
        a_in = 0;
        b_in = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;
    endtask

    //---------------------------------
    // Envio de estímulo
    //---------------------------------
    task send(input logic signed [7:0] a,
              input logic signed [7:0] b);
        txn_t t;
        @(posedge clk);
        valid_in <= 1;
        a_in <= a;
        b_in <= b;

        t.id = tx_id++;
        t.a  = a;
        t.b  = b;
        t.expected = a * b;

        queue.push_back(t);
        $display("[IN ] id=%0d a=%0d b=%0d", t.id, a, b);
    endtask

    task idle();
        @(posedge clk);
        valid_in <= 0;
        a_in <= 0;
        b_in <= 0;
    endtask

    //---------------------------------
    // Checker
    //---------------------------------
    always @(posedge clk) begin
        if (valid_out) begin
            if (queue.size() == 0) begin
                $display("ERRO: saída sem entrada!");
                $stop;
            end

            t = queue.pop_front();

            if (p_out !== t.expected) begin
                $display("\n--------------------------------");
                $display("ERRO id=%0d", t.id);
                $display(" a=%0d b=%0d", t.a, t.b);
                $display(" esperado=%0d \n obtido=%0d", t.expected, p_out);
                // $stop;
            end else begin
                $display("[OUT] id=%0d OK -> %0d", t.id, p_out);
            end
        end
    end

    //---------------------------------
    // Teste principal
    //---------------------------------
    initial begin
        clk = 0;

        reset_dut();

        // sequência inicial (fácil de rastrear)
        send(3, 4);     // id 0
        send(2, 5);     // id 1
        send(-3, 6);    // id 2

        // fluxo contínuo (enche pipeline)
        repeat (15) begin
            send($urandom_range(-10,10),
                 $urandom_range(-10,10));
        end

        repeat (3) idle();
        repeat (10) @(posedge clk);

        $display("\n============================================");
        $display("                 END OF TESTS                 ");
        $display("============================================\n");
        $finish;
    end

endmodule