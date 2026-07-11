module resource_allocation_engine #(
    parameter NUM_CLIENTS = 8,
    parameter NUM_RES     = 2,
    parameter CNT_W        = 32
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [1:0]             mode,
    input  wire [NUM_CLIENTS-1:0] req,

    output reg  [NUM_CLIENTS-1:0] gnt,
    output reg  [NUM_RES-1:0]     res_valid,

    output reg [CNT_W-1:0] res0_util_count,  
    output reg [CNT_W-1:0] res1_util_count,  
    output reg [CNT_W-1:0] contention_count, 
    output reg [CNT_W-1:0] idle_count         
);

    wire [NUM_CLIENTS-1:0] fixed_gnt, rr_gnt, dyn_gnt;
    wire [NUM_RES-1:0]     fixed_rv,  rr_rv,  dyn_rv;

    fixed_priority_arbiter #(
        .NUM_CLIENTS(NUM_CLIENTS), .NUM_RES(NUM_RES)
    ) u_fixed (
        .req(req), .gnt(fixed_gnt), .res_valid(fixed_rv)
    );

    round_robin_arbiter #(
        .NUM_CLIENTS(NUM_CLIENTS), .NUM_RES(NUM_RES)
    ) u_rr (
        .clk(clk), .rst_n(rst_n), .req(req), .gnt(rr_gnt), .res_valid(rr_rv)
    );

    dynamic_priority_arbiter #(
        .NUM_CLIENTS(NUM_CLIENTS), .NUM_RES(NUM_RES)
    ) u_dyn (
        .clk(clk), .rst_n(rst_n), .req(req), .gnt(dyn_gnt), .res_valid(dyn_rv)
    );

    always @(*) begin
        case (mode)
            2'b00:   begin gnt = fixed_gnt; res_valid = fixed_rv; end
            2'b01:   begin gnt = rr_gnt;    res_valid = rr_rv;    end
            2'b10:   begin gnt = dyn_gnt;   res_valid = dyn_rv;   end
            default: begin gnt = {NUM_CLIENTS{1'b0}}; res_valid = {NUM_RES{1'b0}}; end
        endcase
    end

    integer k;
    reg [3:0] req_popcount; 
    always @(*) begin
        req_popcount = 4'd0;
        for (k = 0; k < NUM_CLIENTS; k = k + 1)
            req_popcount = req_popcount + req[k];
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            res0_util_count  <= {CNT_W{1'b0}};
            res1_util_count  <= {CNT_W{1'b0}};
            contention_count <= {CNT_W{1'b0}};
            idle_count       <= {CNT_W{1'b0}};
        end else begin
            if (res_valid[0]) res0_util_count <= res0_util_count + 1'b1;
            if (res_valid[1]) res1_util_count <= res1_util_count + 1'b1;
            if (req_popcount > NUM_RES) contention_count <= contention_count + 1'b1;
            if (req_popcount == 4'd0)   idle_count       <= idle_count + 1'b1;
        end
    end

endmodule