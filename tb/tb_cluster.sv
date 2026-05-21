`timescale 1ns/1ns

module tb_tiny_npu_cluster;

    //---------------------------------------------------------
    // PARAMETERS
    //---------------------------------------------------------

    localparam NPU_COUNT = 4;

    logic              clk;
    logic              rst_n;
    logic              bus_valid;
    logic        [1:0] bus_dest;
    logic signed [7:0] bus_x;
    logic signed [7:0] bus_w0;
    logic signed [7:0] bus_w1;
    logic signed [7:0] bus_w2;
    logic signed [7:0] bus_w3;

    //---------------------------------------------------------
    // CLOCK / RESET
    //---------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    //---------------------------------------------------------
    // DUT
    //---------------------------------------------------------
    npu_cluster #(
        .NPU_COUNT ( NPU_COUNT   )
    ) dut (
        .clk       ( clk         ),
        .rst_n     ( rst_n       ),
        .bus_valid ( bus_valid   ),
        .bus_dest  ( bus_dest    ),
        .bus_x     ( bus_x       ),
        .bus_w0    ( bus_w0      ),
        .bus_w1    ( bus_w1      ),
        .bus_w2    ( bus_w2      ),
        .bus_w3    ( bus_w3      )
    );

    //---------------------------------------------------------
    // GOLDEN MODEL
    //---------------------------------------------------------
    int golden_acc0 [0:NPU_COUNT-1];
    int golden_acc1 [0:NPU_COUNT-1];
    int golden_acc2 [0:NPU_COUNT-1];
    int golden_acc3 [0:NPU_COUNT-1];

    //---------------------------------------------------------
    // RESET
    //---------------------------------------------------------
    task reset_dut();

        rst_n = 0;

        bus_valid = 0;
        bus_dest  = 0;

        bus_x  = 0;
        bus_w0 = 0;
        bus_w1 = 0;
        bus_w2 = 0;
        bus_w3 = 0;

        for(int i=0;i<NPU_COUNT;i++) begin
            golden_acc0[i] = 0;
            golden_acc1[i] = 0;
            golden_acc2[i] = 0;
            golden_acc3[i] = 0;
        end

        repeat(5) @(posedge clk); rst_n = 1;
        repeat(2) @(posedge clk);

    endtask

    //---------------------------------------------------------
    // SEND BUS PACKET
    //---------------------------------------------------------

    task send_packet
    (
        input        [1:0] dest,
        input signed [7:0] tx,
        input signed [7:0] tw0,
        input signed [7:0] tw1,
        input signed [7:0] tw2,
        input signed [7:0] tw3
    );
        @(posedge clk);
        bus_valid <= 1'b1;
        bus_dest  <= dest;
        bus_x     <= tx;
        bus_w0    <= tw0;
        bus_w1    <= tw1;
        bus_w2    <= tw2;
        bus_w3    <= tw3;

        // GOLDEN UPDATE
        golden_acc0[dest] += tx * tw0;
        golden_acc1[dest] += tx * tw1;
        golden_acc2[dest] += tx * tw2;
        golden_acc3[dest] += tx * tw3;

        // DISPLAY
        $display("\n");
        $display("--------------------------------------");
        $display("SEND PACKET");
        $display("DEST = %0d", dest);

        $display("X=%0d W=[%0d %0d %0d %0d]",
                tx,tw0,tw1,tw2,tw3);

    endtask

    //---------------------------------------------------------
    // STOP BUS
    //---------------------------------------------------------
    task stop_bus();
        @(posedge clk);
        bus_valid <= 0;
        bus_dest  <= 0;
        bus_x     <= 0;
        bus_w0    <= 0;
        bus_w1    <= 0;
        bus_w2    <= 0;
        bus_w3    <= 0;
    endtask

    //---------------------------------------------------------
    // CHECK TASK
    //---------------------------------------------------------
    task check_cluster();

        $display("\n======================================");
        $display("CHECKING CLUSTER");
        $display("======================================\n");

        for(int i=0;i<NPU_COUNT;i++) begin

            $display("\n");
            $display("NPU[%0d]", i);
            $display("ACC0 DUT=%0d GOLDEN=%0d", dut.acc0[i], golden_acc0[i]);
            $display("ACC1 DUT=%0d GOLDEN=%0d", dut.acc1[i], golden_acc1[i]);
            $display("ACC2 DUT=%0d GOLDEN=%0d", dut.acc2[i], golden_acc2[i]);
            $display("ACC3 DUT=%0d GOLDEN=%0d", dut.acc3[i], golden_acc3[i]);

            //---------------------------------------------
            // CHECKS
            //---------------------------------------------
            if(dut.acc0[i] !== golden_acc0[i]) begin
                $error("ACC0 ERROR NPU=%0d", i);
            end

            if(dut.acc1[i] !== golden_acc1[i]) begin
                $error("ACC1 ERROR NPU=%0d", i);
            end

            if(dut.acc2[i] !== golden_acc2[i]) begin
                $error("ACC2 ERROR NPU=%0d", i);
            end

            if(dut.acc3[i] !== golden_acc3[i]) begin
                $error("ACC3 ERROR NPU=%0d", i);
            end

        end

    endtask

    //---------------------------------------------------------
    // TEST SEQUENCE
    //---------------------------------------------------------
    initial begin

        reset_dut();
        send_packet(0, 8'sd3, 8'sd1, 8'sd2, 8'sd3, 8'sd4);     // SEND TO NPU0
        send_packet(1, 8'sd2, 8'sd5, 8'sd6, 8'sd7, 8'sd8);     // SEND TO NPU1        
        send_packet(2,-8'sd4, 8'sd2,-8'sd3, 8'sd1,-8'sd2);     // SEND TO NPU2
        send_packet(3, 8'sd10,8'sd1, 8'sd1, 8'sd1, 8'sd1);     // SEND TO NPU3
        send_packet(0, 8'sd7, 8'sd2, 8'sd2, 8'sd2, 8'sd2);     // SEND ANOTHER TO NPU0
        stop_bus();

        @(negedge valid_out)
        check_cluster();

        $display("\n======================================");
        $display("          CLUSTER TEST PASSED           ");
        $display("======================================\n");
        $finish;

    end

endmodule