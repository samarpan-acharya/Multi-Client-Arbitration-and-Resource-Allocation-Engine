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
## Project Overview

---

In advanced System-on-Chip (SoC) architectures and high-throughput networking pipelines, functional sub-blocks frequently compete for a limited pool of shared hardware resources, such as communication buses, memory controllers, or hardware accelerators. If multiple master entities attempt to lock these blocks simultaneously without an organized scheduling layer, the system encounters structural data path conflicts, bus stall lockups, or significant latency penalties.

This project implements a parameterizable hardware engine to solve this multi-master resource contention problem. By completely decoupling the scheduling policy layer from the structural physical allocation matrix, it accurately models a flexible real-world SoC interconnect manager. The engine balances high-speed, single-cycle selection with highly configurable fairness algorithms, preventing low-priority master blocks from experiencing infinite starvation during high-load execution intervals.

### Target Applications

* **Multi-Master Shared System Buses:** AMBA AXI4/AHB crossbars, Wishbone interconnect fabrics.
* **High-Bandwidth SoC Network-on-Chip (NoC):** Routers and virtual-channel schedulers.
* **Memory Interface Schedulers:** Multi-port DDR/LPDDR memory controller front-ends scheduling CPU, GPU, and DMA access.
* **Accelerator Pools:** Coordinated resource management for shared cryptographic, DSP, or Embedded-AI hardware primitives.

---

## Key Highlights

---

* **Configurable Multi-Client Architecture:** Decouples structural layout mapping from upstream scheduling logic.
* **Supports 8 Request Sources:** Ingests and routes a parallel 8-bit independent client interface bus array.
* **Supports 2 Shared Resources:** Concurrently multiplexes physical execution target ports based on live structural availability indicators.
* **Three Arbitration Policies:** Integrates Fixed Priority, Round Robin, and Dynamic Aging selection architectures within a single IP core.
* **Unified Arbitration Interface:** Establishes standardized structural data boundaries across all execution pipelines for seamless expandability.
* **Runtime Arbitration Mode Switching:** Safely shifts scheduling algorithms on the fly via register modification without corrupting active transactions.
* **Fairness and Starvation Analysis:** Detailed runtime tracking of transaction distribution profiles under heavy, continuous traffic loads.
* **Directed and Randomized Verification:** Rigorous verification suite utilizing both targeted boundary testcases and pseudo-random simulation sweeps.
* **Synthesizable Verilog RTL:** Structured entirely in fully vendor-agnostic, clean, structured IEEE 1364-2001 code.
* **Vivado FPGA Implementation Flow:** Verified and analyzed using professional Electronic Design Automation (EDA) tool compilation flows.

---

## Arbitration Strategies

---

### Fixed Priority Arbitration

Fixed Priority Arbitration applies an unchangeable, hardwired priority hierarchy where Client 0 possesses the highest structural rank and Client 7 holds the lowest. Incoming requests are evaluated through a combinatorial priority encoder tree. While this provides minimal logic levels and very low propagation delay, it presents an inherent risk of resource starvation; higher-indexed clients can completely block lower-indexed masters if they drive continuous, back-to-back request vectors.

### Round Robin Arbitration

Round Robin Arbitration implements a rotating token-passing priority scheme designed to guarantee equal access windows across all masters. The hardware maintains an internal history pointer vector that updates to the next sequential client index immediately following a completed transaction grant cycle. This strategy enforces perfect long-term distribution fairness and eliminates starvation risks, though it can introduce additional tracking logic levels compared to fixed layouts.

### Dynamic Priority (Aging-Based) Arbitration

Dynamic Priority Arbitration balances the low-latency speed of fixed encoding with long-term fairness through an automated aging layer. Every client channel is paired with a dedicated waiting-time counter. If a master client asserts a request but is bypassed by a higher-priority block, its counter increments. When this wait-state threshold is exceeded, the internal aging logic temporarily boosts the client's weight to force an immediate grant on the next available cycle, clearing the starved condition and resetting the tracker.

---
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

---

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
### Persistent Contention Scenario

![Resource Allocation](waveforms/resource_allocation_full.png)

Simulating a worst-case validation condition where all 8 clients assert request pins simultaneously tests the engine under peak structural load. The functional waveform demonstrates the allocation matrix safely dividing the 2 available physical resource paths across the requesting masters according to the active policy, cleanly blocking invalid double-grants and proving structural interface isolation.

---

### Runtime Arbitration Mode Switching

![Mode Switching](waveforms/mode_switching.png)

Modifying the 2-bit configuration bus (`mode[1:0]`) on the fly showcases seamless transitions between scheduling algorithms during active workloads. The simulation capture confirms that in-flight resource locks complete safely under the legacy policy, while newly incoming cycles adapt instantly to the newly enabled engine layout without inducing output glitches, dropping transactions, or generating meta-stable state steps.

---

## Resource Utilization

---

The following hardware utilization metrics were extracted directly from the post-synthesis reports generated by **Xilinx Vivado v.2014.1 (win64)** for the design in a `Synthesized` state, targeting the Artix-7 device family (`xc7a35t-cpg236`).

| Resource | Utilization |
|---|---|
| **LUTs** | 368 used out of 20,800 (1.76%) |
| **Flip-Flops** | 163 used out of 41,600 (0.39%) |
| **I/O** | 150 used out of 106 (141.50%) |
| **DSP** | 0 used out of 90 (0.00%) |
| **BRAM** | 0 used out of 50 (0.00%) |

*Note: The physical package pin allocation stands at 141.50% because all wide internal client ports, multi-resource tracking vectors, and internal verification signals are routed directly to external top-level package pins for deep debug visibility. In a production-level System-on-Chip (SoC) integration, these wires interface completely internally over a shared master interconnect fabric, reducing physical chip I/O requirements well within hardware bounds.*

---

## Timing Analysis

---

Static Timing Analysis (STA) was performed across all operational process corners on the core clock network using a baseline clock period configuration of **20.000 ns (50.000 MHz)**.

| Parameter | Result |
|---|---|
| **Worst Negative Slack (WNS)** | +0.260 ns |
| **Worst Hold Slack (WHS)** | +0.257 ns |
| **Worst Pulse Width Slack (WPWS)** | +9.460 ns |
| **Total Failing Endpoints** | 0 |

### Critical Path Evaluation

The critical setup timing path originates from the internal dynamic priority tracking registers (`u_dyn/age_reg[1][0]/C`) and terminates at the register clock enable input pins (`u_dyn/age_reg[3][0]/CE`). The path consists of 16 distinct combinatorial logic levels, where cell propagation delay accounts for `4.037 ns` (20.71%) and routing delay accounts for `15.459 ns` (79.29%).

### Setup & Hold Timing Verification

Achieving a positive Worst Negative Slack (WNS) of **+0.260 ns** and a Worst Hold Slack (WHS) of **+0.257 ns** demonstrates that signal transitions settle reliably before the active clock edge, ensuring robust data path stability across all hardware conditions.

### Timing Closure Achievement

The system achieves complete timing closure with zero timing violations and zero failed endpoints. Positive margins across all paths guarantee single-cycle execution capability, even during simultaneous full-load client contention scenarios.

---
## Verification Methodology

---

A dual-tier validation strategy was applied to verify the structural completeness of the RTL microarchitecture against protocol violations or edge-case state hazards.

### Directed Verification

| Test | Purpose |
|---|---|
| **Single requester** | Basic functionality check validating idle-to-grant latency and structural path isolation. |
| **Multiple requesters** | Verifies arbitration correctness and collision blocking when two or three clients conflict. |
| **All 8 clients active** | Tests maximum contention behavior, establishing that resource bounds are strictly held under peak load. |
| **Back-to-Back requests** | Confirms continuous operation and pipeline turnaround speed across successive clock cycles. |
| **Mode switching** | Validates dynamic configuration transitions on the fly without dropping requests or corrupting active states. |

### Random Verification

To expose complex corner cases that evade static verification passes:
* **Random Operand Generation:** Emulates unpredictable, real-world master traffic patterns with varying active pulse durations and arrival frequencies.
* **Stress Testing:** Floods the request plane under maximum burst conditions while continuously cycling the active scheduling mode configurations randomly.
* **Corner-Case Validation:** Verifies boundary conditions, such as near-simultaneous assertions precisely on the edge of clock transitions or pointer tracking register wrap-arounds.
* **Fairness Observation:** Collects functional coverage data over long-running test sequences to measure allocation distribution and verify total starvation avoidance across all strategies.

---

## Tools Used

---

### Hardware Description Language
* **Verilog HDL:** Core language used to construct the synthesizable register-transfer-level (RTL) engine and structural module hierarchies.

### FPGA Development
* **Xilinx Vivado Design Suite (v.2014.1):** Used for complete hardware design automation:
  * **RTL Simulation:** Behavior validation and waveform debugging via Vivado Simulator.
  * **Synthesis:** Translating high-level behavioral code into targeted gate-level technology mappings.
  * **Implementation:** Handling routing paths and structural placement logic.
  * **Timing Analysis:** Verifying clock constraint compliance and path slack numbers via the Static Timing Analyzer (STA).
  * **Resource Estimation:** Compiling hardware utilization budgets (LUT, FF, and I/O counts).

### Version Control
* **Git and GitHub:** Employed for repository structuring, revision tracking, and codebase documentation hosting.

---

## Repository Structure

---

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
---

## Project Outcomes

---

* **Understanding of Arbitration Architectures:** Developed deep functional expertise in modeling multi-master conflict resolution, parameterizable multiplexing schemes, and dynamic prioritization sub-systems.
* **Hardware Fairness vs Complexity Trade-Offs:** Gained practical exposure balancing structural efficiency (e.g., Fixed Priority logic loops) against enhanced algorithmic fairness (e.g., Dynamic Aging tracking structures), optimizing for both gate count and path delay.
* **RTL Design Experience:** Mastered writing robust, synthesizable, synchronous Verilog architectures adhering to rigorous clean-coding design styles.
* **Verification Methodology:** Established a balanced verification framework combining directed boundary testing and pseudo-random simulation to achieve wide functional validation coverage.
* **FPGA Implementation Exposure:** Acquired hands-on proficiency analyzing real synthesis metrics, resource utilization reports, and timing budgets to successfully close timing constraints.
* **Relevance to RTL Design and Verification Roles:** Proves solid foundational competency across front-end design, RTL microarchitecture, validation, and standard industrial FPGA compilation flows.

---

## Author

---

**Samarpan Acharya** B.Tech, Electronics and Communication Engineering  
National Institute of Technology Rourkela  

---

## License

---

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.
