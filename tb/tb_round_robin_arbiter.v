`timescale 1ns/1ps
module tb_round_robin_arbiter;

    localparam NUM_CLIENTS = 8;
    localparam NUM_RES     = 2;
    localparam CLK_PERIOD  = 10;

    reg                     clk;
    reg                     rst_n;
    reg  [NUM_CLIENTS-1:0]  req;
    wire [NUM_CLIENTS-1:0]  gnt;
    wire [NUM_RES-1:0]      res_valid;

    integer grant_count [0:NUM_CLIENTS-1];
    integer i, cycle_num;

    round_robin_arbiter #(
        .NUM_CLIENTS(NUM_CLIENTS),
        .NUM_RES(NUM_RES)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .req(req),
        .gnt(gnt),
        .res_valid(res_valid)
    );

    // ---- clock generation ----
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // ---- grant counter (fairness / starvation monitor) ----
    always @(posedge clk) begin
        if (rst_n) begin
            for (i = 0; i < NUM_CLIENTS; i = i + 1)
                if (gnt[i]) grant_count[i] = grant_count[i] + 1;
        end
    end

    task print_state(input [127:0] label);
        begin
            $display("[t=%0t] %-20s req=%b gnt=%b res_valid=%b ptr_dbg(see waveform)",
                       $time, label, req, gnt, res_valid);
        end
    endtask

    initial begin
        $display("========= Round Robin Arbiter :: Directed + Fairness Tests =========");
        for (i = 0; i < NUM_CLIENTS; i = i + 1) grant_count[i] = 0;

        // ---- reset ----
        rst_n = 1'b0;
        req   = 8'b0000_0000;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        @(negedge clk); print_state("after_reset");

        // ---- Test 1: only client 0 requests, alone, for a few cycles ----
        req = 8'b0000_0001;
        repeat (3) begin @(negedge clk); print_state("client0_only"); end

        // ---- Test 2: two non-adjacent clients request together ----
        req = 8'b0010_0100; // clients 2 and 5
        repeat (3) begin @(negedge clk); print_state("client2_5"); end

        // ---- Test 3: ALL 8 clients request persistently for 16 cycles ----
        // This is the fairness/starvation proof: with 2 grants/cycle and
        // 8 clients, every client should be serviced exactly once every
        // 4 cycles once the pointer has made a full loop.
        req = 8'b1111_1111;
        for (cycle_num = 0; cycle_num < 16; cycle_num = cycle_num + 1) begin
            @(negedge clk);
            print_state("all_req_persistent");
        end

        // ---- Test 4: requests drop out mid-stream (dynamic pattern) ----
        req = 8'b0000_1111; // clients 0-3 only
        repeat (4) begin @(negedge clk); print_state("clients0to3"); end

        req = 8'b0000_0000; // idle
        repeat (2) begin @(negedge clk); print_state("idle"); end

        // ---- Fairness report ----
        $display("========= Grant Count per Client (fairness check) =========");
        for (i = 0; i < NUM_CLIENTS; i = i + 1)
            $display("  client[%0d] : %0d grants", i, grant_count[i]);

        $display("========= Round Robin Tests Complete =========");
        $finish;
    end

endmodule
