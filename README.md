# Multi-Client Arbitration and Resource Allocation Engine

---

This project implements a highly configurable, parameterizable shared-resource allocation engine in synthesizable Verilog HDL. The architecture supports simultaneous access requests from 8 independent client channels competing for 2 shared hardware resources, utilizing a unified arbitration interface to switch dynamically between three distinct scheduling strategies: Fixed Priority, Round Robin, and Dynamic Priority (Aging-Based) arbitration.

---

## Architecture Overview

The figure below illustrates the overall microarchitecture, layout blocks, and hardware data flow implemented within the resource allocation engine.

![Architecture Overview](images/resource_allocation_engine_block_diagram.svg)

### Subsystem Description

* **Client Request Inputs:** An 8-bit synchronous parallel bus (`req[7:0]`) that registers simultaneous incoming request vectors from independent master clients.
* **Arbitration Controller:** The central coordination logic block containing execution registers, state tracking sequencers, and operational status registers to manage scheduling windows.
* **Arbitration Mode Selection:** A 2-bit configuration input interface (`mode[1:0]`) used to dynamically command the arbiter core to toggle between its active hardware scheduling routines at runtime.
* **Arbitration Engines:** Three discrete scheduling primitives evaluated concurrently in hardware:
  * **Fixed Priority:** Evaluates requests through a static priority encoder tree.
  * **Round Robin:** Tracks access history via a rotating token pointer.
  * **Dynamic Priority:** Implements wait-time thresholds to dynamically adjust request weights.
* **Resource Allocation Logic:** A combinatorial mapping and masking matrix that matches the highest-priority client selected by the active engine to an available physical execution target.
* **Grant Generation:** A synchronized, hazard-free 8-bit output interface bus (`gnt[7:0]`) that drives single-cycle execution rights back to the winning clients.
* **Resource Status Feedback:** Real-time metrics output lines, including an active contention counter vector, feeding system load parameters back to the host controller.

---

### Complete Hardware Data Flow

1. **Request Ingestion:** Mastering clients assert execution requirements onto the parallel `req[7:0]` interface.
2. **Algorithmic Selection:** The core controller samples the `mode[1:0]` register configuration and selectively masks inputs into the active arbitration pipeline.
3. **Priority Resolution:** The targeted engine resolves internal channel weights through a lookahead encoder or structural state registers to declare a winner.
4. **Physical Mapping:** The resource allocation logic samples the availability of the 2 shared resources and connects the winning master to a free lane.
5. **Assertion & Feedback:** The engine asserts the matching bit line on the `gnt[7:0]` bus to latch the transaction, while simultaneously incrementing active status lines like the contention tracking matrix.

---
