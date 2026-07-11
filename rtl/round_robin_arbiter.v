// ============================================================
// Module      : round_robin_arbiter
// Description : Grants up to NUM_RES resources per cycle among
//               NUM_CLIENTS requesters using a rotating-priority
//               (round robin) scheme. After any cycle with at
//               least one grant, the priority pointer advances
//               past the highest-index client serviced, so every
//               client eventually becomes top priority. This makes
//               the arbiter starvation-free under persistent
//               requests, at the cost of needing clk/rst_n state.
//
// LIMITATION  : rotation is implemented with barrel shifts + a
//               bitmask (NUM_CLIENTS-1) for the pointer wraparound.
//               This trick requires NUM_CLIENTS to be a power of 2.
//               (interview point: how would you generalize this
//               to e.g. NUM_CLIENTS=6? -> need a real mod-N adder
//               or a compare-and-subtract instead of a mask.)
// ============================================================
module round_robin_arbiter #(
    parameter NUM_CLIENTS = 8,
    parameter NUM_RES     = 2
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [NUM_CLIENTS-1:0] req,
    output reg  [NUM_CLIENTS-1:0] gnt,
    output reg  [NUM_RES-1:0]     res_valid
);

    // NOTE: PTR_W is hand-computed instead of using $clog2() to avoid
    // older-XSim elaboration quirks with $clog2 inside localparam exprs.
    // Valid for NUM_CLIENTS up to 32 as written; extend the ladder if needed.
    localparam PTR_W = (NUM_CLIENTS <= 2)  ? 1 :
                       (NUM_CLIENTS <= 4)  ? 2 :
                       (NUM_CLIENTS <= 8)  ? 3 :
                       (NUM_CLIENTS <= 16) ? 4 : 5;

    reg [PTR_W-1:0] rr_ptr;      // registered rotation base = current "highest priority" client
    reg [PTR_W-1:0] next_ptr;    // combinational next-pointer value
    reg             grant_seen;  // did any grant happen this cycle?

    wire [NUM_CLIENTS-1:0] req_rotated;
    reg  [NUM_CLIENTS-1:0] gnt_rotated;
    reg  [NUM_CLIENTS-1:0] req_remaining;
    reg  [PTR_W-1:0]       last_rot_pos; // highest rotated-frame position granted this cycle

    integer r, c;

    // ---- rotate requests so rr_ptr's client lands on bit position 0 ----
    assign req_rotated = (rr_ptr == 0) ? req :
                          ((req >> rr_ptr) | (req << (NUM_CLIENTS - rr_ptr)));

    // ---- priority-encode in the rotated domain (identical structure to Module 1) ----
    always @(*) begin
        gnt_rotated   = {NUM_CLIENTS{1'b0}};
        res_valid     = {NUM_RES{1'b0}};
        req_remaining = req_rotated;
        last_rot_pos  = {PTR_W{1'b0}};
        grant_seen    = 1'b0;

        for (r = 0; r < NUM_RES; r = r + 1) begin
            for (c = 0; c < NUM_CLIENTS; c = c + 1) begin
                if (req_remaining[c] && !res_valid[r]) begin
                    gnt_rotated[c]   = 1'b1;
                    res_valid[r]     = 1'b1;
                    req_remaining[c] = 1'b0;
                    last_rot_pos     = c[PTR_W-1:0];
                    grant_seen       = 1'b1;
                end
            end
        end

        // ---- rotate grants back to real client numbering ----
        gnt = (rr_ptr == 0) ? gnt_rotated :
              ((gnt_rotated << rr_ptr) | (gnt_rotated >> (NUM_CLIENTS - rr_ptr)));

        // ---- next pointer = one past the last (absolute-frame) client serviced ----
        if (grant_seen)
            next_ptr = (rr_ptr + last_rot_pos + 1'b1) & (NUM_CLIENTS - 1);
        else
            next_ptr = rr_ptr; // nobody requested -> pointer holds position
    end

    // ---- pointer state register ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rr_ptr <= {PTR_W{1'b0}};
        else
            rr_ptr <= next_ptr;
    end

endmodule
