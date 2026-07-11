# Multi-Client Arbitration and Resource Allocation Engine

This project implements a highly configurable, parameterizable shared-resource allocation engine in synthesizable Verilog HDL. The architecture supports simultaneous access requests from 8 independent client channels competing for 2 shared hardware resources, utilizing a unified arbitration interface to switch dynamically between three distinct scheduling strategies: Fixed Priority, Round Robin, and Dynamic Priority (Aging-Based) arbitration.

## Architecture Overview

The figure below illustrates the overall microarchitecture, layout blocks, and hardware data flow implemented within the resource allocation engine.

![Architecture Overview](images/resource_allocation_engine_block_diagram.svg)

### Subsystem Description
* **Client Request Inputs:** An 8-bit synchronous parallel bus (`req[7:0]`) that registers simultaneous incoming request vectors from independent master clients.
* **Arbitration Controller:** The central coordination logic block containing execution registers, state tracking sequencers, and operational status registers to manage scheduling windows.
* **Arbitration Mode Selection:** A 2-bit configuration input interface (`mode[1:0]`) used to dynamically command the arbiter core to toggle between its active hardware scheduling routines at runtime.
* **Arbitration Engines:** Three discrete scheduling primitives evaluated concurrently in hardware:
  * *Fixed Priority:* Evaluates requests through a static priority encoder tree.
  * *Round Robin:* Tracks access history via a rotating token pointer.
  * *Dynamic Priority:* Implements wait-time thresholds to dynamically adjust request weights.
* **Resource Allocation Logic:** A combinatorial mapping and masking matrix that matches the highest-priority client selected by the active engine to an available physical execution target.
* **Grant Generation:** A synchronized, hazard-free 8-bit output interface bus (`gnt[7:0]`) that drives single-cycle execution rights back to the winning clients.
* **Resource Status Feedback:** Real-time metrics output lines, including an active contention counter vector, feeding system load parameters back to the host controller.

### Complete Hardware Data Flow
1. **Request Ingestion:** Mastering clients assert execution requirements onto the parallel `req[7:0]` interface.
2. **Algorithmic Selection:** The core controller samples the `mode[1:0]` register configuration and selectively masks inputs into the active arbitration pipeline.
3. **Priority Resolution:** The targeted engine resolves internal channel weights through a lookahead encoder or structural state registers to declare a winner.
4. **Physical Mapping:** The resource allocation logic samples the availability of the 2 shared resources and connects the winning master to a free lane.
5. **Assertion & Feedback:** The engine asserts the matching bit line on the `gnt[7:0]` bus to latch the transaction, while simultaneously incrementing active status lines like the contention tracking matrix.
## Project Overview

In advanced System-on-Chip (SoC) architectures and high-throughput networking pipelines, functional sub-blocks frequently compete for a limited pool of shared hardware resources, such as communication buses, memory controllers, or hardware accelerators. If multiple master entities attempt to lock these blocks simultaneously without an organized scheduling layer, the system encounters data path conflicts, bus stall lockups, or significant latency penalties.

This project implements a parameterizable hardware engine to solve this multi-master resource contention problem. By completely decoupling the scheduling policy layer from the structural physical allocation matrix, it accurately models a flexible real-world SoC interconnect manager. The engine balances high-speed, single-cycle selection with highly configurable fairness algorithms, preventing low-priority master blocks from experiencing infinite starvation during high-load execution intervals.

### Target Applications
* Multi-master shared system buses (AMBA AXI4/AHB crossbars, Wishbone interconnect fabrics).
* High-bandwidth SoC Network-on-Chip (NoC) routers and virtual-channel schedulers.
* Multi-port DDR/LPDDR memory controller front-ends scheduling CPU, GPU, and DMA access.
* Coordinated resource management for shared cryptographic, DSP, or Edge-AI hardware primitives.

---

## Key Highlights

- Configurable multi-client arbitration architecture separating prioritization from layout mapping.
- Supports 8 request sources via a dedicated 8-bit parallel incoming interface bus.
- Supports 2 shared resources by dynamically multiplexing physical execution target ports.
- Three arbitration policies integrated within a unified core for comparative evaluation.
- Unified arbitration interface establishing standardized structural data boundaries across all engines.
- Runtime arbitration mode switching enabling glitch-free algorithm toggling on the fly.
- Fairness and starvation analysis tracking allocation distribution profiles under persistent load.
- Directed and randomized verification validating system state stability against extreme edge cases.
- Synthesizable Verilog RTL authored in fully vendor-agnostic, structured IEEE 1364-2001 code.
- Vivado FPGA implementation flow verified through rigorous synthesis, routing, and timing closure.

---

## Arbitration Strategies

### Fixed Priority Arbitration
Fixed Priority Arbitration applies an unchangeable, hardwired priority hierarchy where Client 0 possesses the highest structural rank and Client 7 holds the lowest. Incoming requests are evaluated through a combinatorial priority encoder tree. While this provides minimal logic levels and very low propagation delay, it presents an inherent risk of resource starvation; higher-indexed clients can completely block lower-indexed masters if they drive continuous, back-to-back request vectors.

### Round Robin Arbitration
Round Robin Arbitration implements a rotating token-passing priority scheme designed to guarantee equal access windows across all masters. The hardware maintains an internal history pointer vector that updates to the next sequential client index immediately following a completed transaction grant cycle. This strategy enforces perfect long-term distribution fairness and eliminates starvation risks, though it can introduce additional tracking logic levels compared to fixed layouts.

### Dynamic Priority (Aging-Based) Arbitration
Dynamic Priority Arbitration balances the low-latency speed of fixed encoding with long-term fairness through an automated aging layer. Every client channel is paired with a dedicated waiting-time counter. If a master client asserts a request but is bypassed by a higher-priority block, its counter increments. When this wait-state threshold is exceeded, the internal aging logic temporarily boosts the client's weight to force an immediate grant on the next available cycle, clearing the starved condition and resetting the tracker.
### Strategy Comparison Tables

**Table 1: Strategic Trade-Off Matrix**

| Strategy | Priority Mechanism | Fairness | Starvation Risk | Complexity |
|---|---|---|---|---|
| **Fixed Priority** | Static (Hardcoded Index) | Poor | High (Low-priority blocks) | Very Low (Encoder Tree) |
| **Round Robin** | Rotating Pointer (History) | Excellent | Zero | Moderate (Tracking Logic) |
| **Dynamic Aging** | Time-Dependent Weighting | High | Zero | High (Counters & Comparators) |

**Table 2: Operational Behavior Matrix**

| Condition | Expected Behaviour |
|---|---|
| **Single Active Request** | Immediate grant issued to the requesting client within one clock cycle, assuming a resource is idle. |
| **Simultaneous Static Contention** | Encoder selects the lowest client index; resource allocated instantly based on hardwired hierarchy. |
| **Saturated Continuous Requests** | Round robin pointer increments sequentially, creating a predictable, interleaved time-division multiplexed access pattern. |
| **Long-Term Starved Client** | Wait counter expires; system overwrites baseline selection vectors to force a grant on the next available cycle. |
| **Mid-Cycle Mode Transition** | The controller stalls algorithm configuration updates until active grants clear, preventing split-transaction corruption. |

---

## Design Flow

```text
RTL Design
     │
     ▼
Testbench Development
     │
     ▼
Vivado Simulation
     │
     ▼
Waveform Debugging
     │
     ▼
Synthesis
     │
     ▼
Implementation
     │
     ▼
Timing Analysis
     │
     ▼
Utilization Reports
## Resource Utilization

The following hardware utilization metrics were extracted directly from the post-synthesis reports generated by **Xilinx Vivado v.2014.1 (win64)** for a design in the `Synthesized` state, targeting the Artix-7 device family (`xc7a35t-cpg236`).

| Resource | Utilization |
|---|---|
| **LUTs** | 368 |
| **Flip-Flops** | 163 |
| **I/O** | 150 |
| **DSP** | 0 |
| **BRAM** | 0 |

---

## Timing Analysis

| Parameter | Result |
|---|---|
| Worst Negative Slack | +2.094 ns |
| Timing Violations | 0 |
| Failed Endpoints | 0 |

### Critical Path Evaluation
The critical timing path tracks structural propagation delays down through the internal control vectors to the target resource mapping registers.

### Setup Timing Verification
Achieving a positive Worst Negative Slack (WNS) of **+2.094 ns** indicates that data paths settle securely within the system's operational constraints.

### Timing Closure Achievement
The implementation completes timing closure smoothly across all analyzed path paths with zero failing endpoints, establishing single-cycle stability under continuous, simultaneous multi-client load profiles.

---

## Verification Methodology

### Directed Verification

| Test | Purpose |
|---|---|
| Single requester | Basic functionality check validating idle-to-grant latency and structural path isolation. |
| Multiple requesters | Verifies arbitration correctness and collision blocking when two or three clients conflict. |
| All 8 clients active | Tests maximum contention behavior, establishing that resource bounds are strictly held under peak load. |
| Back-to-Back requests | Confirms continuous operation and pipeline turnaround speed across successive clock cycles. |
| Mode switching | Validates dynamic configuration transitions on the fly without dropping requests or corrupting active states. |

### Random Verification
To expose complex corner cases, the verification suite incorporates a pseudo-random stimulus framework:
* **Random Request Generation:** Emulates unpredictable, real-world master traffic patterns with varying active durations and arrival frequencies.
* **Stress Testing:** Floods the request plane under maximum burst conditions while continuously varying the active scheduling mode.
* **Corner-Case Validation:** Verifies boundary conditions, such as near-simultaneous assertions precisely on the edge of clock transitions or pointer wrap-arounds.
* **Fairness Observation:** Collects functional coverage data over long-running test sequences to measure allocation distribution and verify total starvation avoidance across all strategies.

---

## Tools Used

### Hardware Description Language
Verilog HDL

### FPGA Development
Xilinx Vivado Design Suite

Used for:
- RTL simulation
- Synthesis
- Implementation
- Timing analysis
- Resource estimation

### Version Control
Git and GitHub

---

## Repository Structure

```text
Multi-Client-Arbitration-and-Resource-Allocation-Engine/
├── images/
│   └── resource_allocation_engine_block_diagram.svg
├── rtl/
├── tb/
├── synthesis/
├── sta/
├── waveforms/
│   ├── fixed_priority.png
│   ├── round_robin.png
│   ├── dynamic_priority_waveform.png
│   ├── resource_allocation_full.png
│   └── mode_switching.png
├── LICENSE
└── README.md
