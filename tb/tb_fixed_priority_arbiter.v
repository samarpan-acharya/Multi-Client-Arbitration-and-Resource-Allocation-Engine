`timescale 1ns/1ps
module tb_fixed_priority_arbiter;

    localparam NUM_CLIENTS = 8;
    localparam NUM_RES     = 2;

    reg  [NUM_CLIENTS-1:0] req;
    wire [NUM_CLIENTS-1:0] gnt;
    wire [NUM_RES-1:0]     res_valid;

    fixed_priority_arbiter #(
        .NUM_CLIENTS(NUM_CLIENTS),
        .NUM_RES(NUM_RES)
    ) dut (
        .req(req),
        .gnt(gnt),
        .res_valid(res_valid)
    );

    task apply(input [NUM_CLIENTS-1:0] r, input [127:0] label);
        begin
            req = r;
            #10;
            $display("[%0t] %-28s req=%b gnt=%b res_valid=%b", $time, label, req, gnt, res_valid);
        end
    endtask

    initial begin
        $display("========= Fixed Priority Arbiter :: Directed Tests =========");

        // 1. No requests
        apply(8'b0000_0000, "no_requests");

        // 2. Single request (lowest priority client only)
        apply(8'b1000_0000, "client7_only");

        // 3. Single request (highest priority client only)
        apply(8'b0000_0001, "client0_only");

        // 4. Two requests, non-adjacent -> both should be granted (2 resources available)
        apply(8'b0000_0101, "client0_and_2");

        // 5. Exactly 2 requests, adjacent
        apply(8'b0000_0011, "client0_and_1");

        // 6. Three requests -> only top 2 priority granted, 3rd starves this cycle
        apply(8'b0000_0111, "client0_1_2_contend");

        // 7. All 8 requesting -> only client0,client1 granted (worst-case starvation snapshot)
        apply(8'b1111_1111, "all_clients_request");

        // 8. Low priority clients only requesting, high priority idle
        apply(8'b1100_0000, "client6_7_only");

        // 9. Middle clients only
        apply(8'b0001_1000, "client3_4_only");

        $display("========= Directed Tests Complete =========");
        $finish;
    end

endmodule
