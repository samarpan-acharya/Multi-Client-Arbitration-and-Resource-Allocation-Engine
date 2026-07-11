`timescale 1ns/1ps
module tb_resource_allocation_engine;

    localparam NUM_CLIENTS = 8;
    localparam NUM_RES     = 2;
    localparam CLK_PERIOD  = 10;

    reg                    clk;
    reg                    rst_n;
    reg  [1:0]             mode;
    reg  [NUM_CLIENTS-1:0] req;
    wire [NUM_CLIENTS-1:0] gnt;
    wire [NUM_RES-1:0]     res_valid;
    wire [31:0]            res0_util_count, res1_util_count, contention_count, idle_count;

    resource_allocation_engine #(
        .NUM_CLIENTS(NUM_CLIENTS), .NUM_RES(NUM_RES)
    ) dut (
        .clk(clk), .rst_n(rst_n), .mode(mode), .req(req),
        .gnt(gnt), .res_valid(res_valid),
        .res0_util_count(res0_util_count), .res1_util_count(res1_util_count),
        .contention_count(contention_count), .idle_count(idle_count)
    );

    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    task print_state(input [159:0] label);
        begin
            $display("[t=%0t] %-24s mode=%0d req=%b gnt=%b res_valid=%b | res0=%0d res1=%0d contend=%0d idle=%0d",
                       $time, label, mode, req, gnt, res_valid,
                       res0_util_count, res1_util_count, contention_count, idle_count);
        end
    endtask

    initial begin
        $display("========= Resource Allocation Engine :: Integration Tests =========");

        rst_n = 1'b0; mode = 2'b00; req = 8'b0;
        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        @(negedge clk); print_state("after_reset");

        mode = 2'b00;
        req  = 8'b1111_1111;
        repeat (4) begin @(negedge clk); print_state("mode_fixed_all_req"); end

        req = 8'b0000_0000;
        repeat (3) begin @(negedge clk); print_state("idle_cycles"); end

        req = 8'b0001_1111; 
        repeat (3) begin @(negedge clk); print_state("contention_5req"); end

        mode = 2'b01;
        req  = 8'b1111_1111;
        repeat (6) begin @(negedge clk); print_state("mode_rr_all_req"); end

        mode = 2'b10;
        req  = 8'b0000_0111; 
        repeat (6) begin @(negedge clk); print_state("mode_dyn_c012"); end

        mode = 2'b11;
        req  = 8'b1111_1111;
        repeat (2) begin @(negedge clk); print_state("mode_reserved_forced_zero"); end

        mode = 2'b00;
        req  = 8'b0000_0001;
        repeat (3) begin @(negedge clk); print_state("mode_fixed_single"); end

        req = 8'b0000_0000;
        repeat (2) begin @(negedge clk); print_state("final_idle"); end

        $display("========= Final Counter Values =========");
        $display("  res0_util_count  = %0d", res0_util_count);
        $display("  res1_util_count  = %0d", res1_util_count);
        $display("  contention_count = %0d", contention_count);
        $display("  idle_count       = %0d", idle_count);
        $display("========= Resource Allocation Engine Tests Complete =========");
        $finish;
    end

endmodule