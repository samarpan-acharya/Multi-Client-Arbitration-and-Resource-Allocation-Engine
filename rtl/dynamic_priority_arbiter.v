// ============================================================
// Module      : dynamic_priority_arbiter
// Description : Aging-based dynamic priority arbiter. Every
//               requesting-but-not-granted client's age counter
//               increments each cycle (saturating). A granted
//               client's age resets to 0. A client that stops
//               requesting also resets to 0 (no banked priority
//               for a request it already withdrew). Each cycle,
//               the arbiter grants up to NUM_RES resources to the
//               requesting clients with the HIGHEST age, breaking
//               ties by lowest client index.
//
// WHY THIS BEATS FIXED PRIORITY : age strictly increases for any
// client that keeps losing, so eventually its age exceeds every
// other requester's age and it MUST win -> bounded worst-case
// wait, unlike Fixed Priority where low-index clients can starve
// a low-priority client forever.
//
// WHY THIS DIFFERS FROM ROUND ROBIN : priority here is driven by
// actual measured wait time, not a blind rotating pointer -- a
// client that just started requesting doesn't jump the queue, and
// a client that has been waiting long gets serviced sooner than
// strict rotation would guarantee. Trade-off: needs an age counter
// PER CLIENT (more area than Round Robin's single pointer) and a
// max-finder instead of a simple priority encoder (more comb. depth).
// ============================================================
module dynamic_priority_arbiter #(
    parameter NUM_CLIENTS = 8,
    parameter NUM_RES     = 2,
    parameter AGE_W        = 4   // 4-bit age counter -> saturates at 15
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [NUM_CLIENTS-1:0] req,
    output reg  [NUM_CLIENTS-1:0] gnt,
    output reg  [NUM_RES-1:0]     res_valid
);

    localparam PTR_W = (NUM_CLIENTS <= 2)  ? 1 :
                       (NUM_CLIENTS <= 4)  ? 2 :
                       (NUM_CLIENTS <= 8)  ? 3 :
                       (NUM_CLIENTS <= 16) ? 4 : 5;

    // ---- per-client age counters (this is the arbiter's state) ----
    reg [AGE_W-1:0] age [0:NUM_CLIENTS-1];
    integer i;

    // ---- combinational winner-selection variables ----
    integer w, c;
    reg [NUM_CLIENTS-1:0] req_remaining;
    reg [AGE_W-1:0]       best_age;
    reg [PTR_W-1:0]       best_idx;
    reg                   found;

    // ---- winner selection: find NUM_RES requesting clients with
    //      the highest age, tie-broken by lowest index ----
    always @(*) begin
        gnt           = {NUM_CLIENTS{1'b0}};
        res_valid     = {NUM_RES{1'b0}};
        req_remaining = req;

        for (w = 0; w < NUM_RES; w = w + 1) begin
            best_age = {AGE_W{1'b0}};
            best_idx = {PTR_W{1'b0}};
            found    = 1'b0;

            for (c = 0; c < NUM_CLIENTS; c = c + 1) begin
                if (req_remaining[c] && !found) begin
                    // first requesting client found this pass -> provisional winner
                    best_age = age[c];
                    best_idx = c[PTR_W-1:0];
                    found    = 1'b1;
                end else if (req_remaining[c] && found && (age[c] > best_age)) begin
                    // strictly greater age required -> keeps lowest index on ties
                    best_age = age[c];
                    best_idx = c[PTR_W-1:0];
                end
            end

            if (found) begin
                gnt[best_idx]          = 1'b1;
                res_valid[w]           = 1'b1;
                req_remaining[best_idx] = 1'b0; // remove winner before next pass
            end
        end
    end

    // ---- age counter update (this is the only sequential state) ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < NUM_CLIENTS; i = i + 1)
                age[i] <= {AGE_W{1'b0}};
        end else begin
            for (i = 0; i < NUM_CLIENTS; i = i + 1) begin
                if (gnt[i])
                    age[i] <= {AGE_W{1'b0}};                 // serviced -> reset
                else if (req[i])
                    age[i] <= (age[i] == {AGE_W{1'b1}}) ? age[i] : age[i] + 1'b1; // waiting -> age up (saturate)
                else
                    age[i] <= {AGE_W{1'b0}};                 // not requesting -> no banked priority
            end
        end
    end

endmodule
