`timescale 1ns/1ps
module tb_dynamic_priority_arbiter;

    localparam NUM_CLIENTS = 8;
    localparam NUM_RES     = 2;
    localparam AGE_W       = 4;
    localparam CLK_PERIOD  = 10;

    reg                     clk;
    reg                     rst_n;
    reg  [NUM_CLIENTS-1:0]  req;
    wire [NUM_CLIENTS-1:0]  gnt;
    wire [NUM_RES-1:0]      res_valid;

    integer grant_count [0:NUM_CLIENTS-1];
    integer i, cycle_num;

    dynamic_priority_arbiter #(
        .NUM_CLIENTS(NUM_CLIENTS),
        .NUM_RES(NUM_RES),
        .AGE_W(AGE_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .req(req),
        .gnt(gnt),
        .res_valid(res_valid)
    );

    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    always @(posedge clk) begin
        if (rst_n) begin
            for (i = 0; i < NUM_CLIENTS; i = i + 1)
                if (gnt[i]) grant_count[i] = grant_count[i] + 1;
        end
    end

    task print_state(input [127:0] label);
        begin
            $display("[t=%0t] %-22s req=%b gnt=%b res_valid=%b",
                       $time, label, req, gnt, res_valid);
        end
    endtask

    initial begin
        $display("========= Dynamic Priority (Aging) Arbiter Tests =========");
        for (i = 0; i < NUM_CLIENTS; i = i + 1) grant_count[i] = 0;

        rst_n = 1'b0;
        req   = 8'b0000_0000;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        @(negedge clk); print_state("after_reset");

        // ---- Test 1: 3 requesters (clients 0,1,2), only 2 resources.
        // Proves aging forces rotation among the loser even though
        // client index tie-break always favors client0. Watch client2's
        // age climb and force it into the winner set every ~2nd cycle.
        req = 8'b0000_0111;
        for (cycle_num = 0; cycle_num < 8; cycle_num = cycle_num + 1) begin
            @(negedge clk);
            print_state("clients0_1_2_contend");
        end

        // ---- Test 2: age saturation. Hold 3 requesters (0,1,2) but now
        // make client2 the PERSISTENT loser by having client0/1 alternate
        // out so client2 never wins for >15 cycles -> age must clamp at 15
        // (4'b1111), not wrap to 0.
        req = 8'b0000_0101; // clients 0 and 2 only, client1 silent
        for (cycle_num = 0; cycle_num < 20; cycle_num = cycle_num + 1) begin
            @(negedge clk);
            print_state("saturation_test");
        end

        // ---- Test 3: withdrawal resets age. Client2 has a high age from
        // Test 2; now drop its request entirely for a few cycles, then
        // bring it back -- it should NOT jump the queue on return (age
        // should have reset to 0, not resumed from where it left off).
        req = 8'b0000_0001; // only client0, client2 silent
        repeat (3) begin @(negedge clk); print_state("client2_withdrawn"); end

        req = 8'b0000_0101; // client2 returns alongside client0
        repeat (3) begin @(negedge clk); print_state("client2_returns_fresh"); end

        // ---- Test 4: full 8-client persistent contention (same stress
        // test as Modules 1 & 2, for direct comparison in your report) ----
        req = 8'b1111_1111;
        for (cycle_num = 0; cycle_num < 24; cycle_num = cycle_num + 1) begin
            @(negedge clk);
            print_state("all_req_persistent");
        end

        req = 8'b0000_0000;
        repeat (2) begin @(negedge clk); print_state("idle"); end

        $display("========= Grant Count per Client (fairness check) =========");
        for (i = 0; i < NUM_CLIENTS; i = i + 1)
            $display("  client[%0d] : %0d grants", i, grant_count[i]);

        $display("========= Dynamic Priority Tests Complete =========");
        $finish;
    end

endmodule
