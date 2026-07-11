// ============================================================
// Module      : fixed_priority_arbiter
// Description : Grants up to NUM_RES resources per cycle to
//               requesting clients using fixed priority
//               (client 0 = highest priority, client N-1 = lowest).
//               Purely combinational -> no state -> can starve
//               low priority clients under sustained high-priority load.
// ============================================================
module fixed_priority_arbiter #(
    parameter NUM_CLIENTS = 8,
    parameter NUM_RES     = 2
)(
    input  wire [NUM_CLIENTS-1:0] req,     // client request vector
    output reg  [NUM_CLIENTS-1:0] gnt,     // client grant vector
    output reg  [NUM_RES-1:0]     res_valid // which resources got assigned this cycle
);

    integer r, c;
    reg [NUM_CLIENTS-1:0] req_remaining; // requests not yet serviced this cycle

    always @(*) begin
        gnt            = {NUM_CLIENTS{1'b0}};
        res_valid      = {NUM_RES{1'b0}};
        req_remaining  = req;

        // For each of the NUM_RES resources, scan clients 0..N-1 in order
        // and grant the resource to the first requester still remaining.
        for (r = 0; r < NUM_RES; r = r + 1) begin
            for (c = 0; c < NUM_CLIENTS; c = c + 1) begin
                if (req_remaining[c] && !res_valid[r]) begin
                    gnt[c]        = 1'b1;
                    res_valid[r]  = 1'b1;
                    req_remaining[c] = 1'b0; // remove so 2nd resource loop skips it
                end
            end
        end
    end

endmodule
