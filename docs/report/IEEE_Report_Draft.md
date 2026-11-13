# Instruction and Data Memory Hierarchy
## IEEE Project Report — Draft

**Course:** Modern Computer Architecture  
**Institution:** [Your University Name]  
**Date:** November 2026

---

## Abstract

This paper presents the design and implementation of a two-level instruction and data memory hierarchy for a modern RISC-style processor using Verilog HDL. The proposed architecture features separate L1 instruction and data caches — following the Harvard memory architecture principle — connected through a priority-based finite state machine (FSM) cache controller to a main memory module with realistic DRAM access latency simulation. The L1 caches are implemented as 8-line direct-mapped caches with a write-through policy to ensure data consistency. The cache arbiter grants priority to data cache (D-Cache) miss requests over instruction cache (I-Cache) requests, minimizing pipeline stalls during simultaneous misses. The main memory controller simulates a 3-cycle DRAM access latency using a request/ready handshake protocol. The design is validated through a comprehensive seven-scenario testbench implemented in Icarus Verilog, with waveform analysis performed using GTKWave. Simulation results confirm correct hit/miss detection, write-through cache coherence, CPU stall signal generation, and proper arbitration under concurrent miss scenarios. The implementation demonstrates fundamental principles of computer memory organization and serves as a synthesizable RTL model for educational and research purposes.

**Keywords:** Memory Hierarchy, Cache Memory, Direct-Mapped Cache, Write-Through, Verilog HDL, RISC Architecture, Cache Controller, FSM, DRAM Latency

---

## 1. Introduction

Modern processors face a significant performance bottleneck known as the **memory wall** — the growing gap between CPU processing speed and main memory access speed. The solution, universally adopted in contemporary processor design, is the **memory hierarchy**: a multi-level system of progressively larger but slower memory units, with small fast caches sitting between the CPU and main memory [1].

This project implements a functional Verilog HDL model of such a hierarchy, specifically focusing on the instruction and data memory subsystem. The design models a split L1 cache (separate instruction and data caches), a unified cache controller, and a DRAM-like main memory, mirroring the structure found in real processors such as the ARM Cortex-A series and RISC-V implementations.

---

## 2. Literature Review

### 2.1 Cache Memory Fundamentals

The concept of cache memory was formally introduced in the late 1960s. Wilkes (1965) first described the concept of a "slave memory" to bridge the speed gap between the CPU and main store [2]. Smith (1982) provided a comprehensive survey of cache memory systems, analyzing the effect of cache size, block size, and replacement policies on hit rate [3]. This foundational work established that even small direct-mapped caches dramatically reduce average memory access time.

### 2.2 Direct-Mapped vs. Associative Caches

Hill and Smith (1989) evaluated the tradeoffs between direct-mapped and set-associative cache organizations [4]. Their study demonstrated that while higher associativity reduces conflict misses, direct-mapped caches achieve lower access latency and are simpler to implement in hardware — making them well-suited for L1 cache implementations where speed is paramount. Our design employs direct-mapped caches for this reason.

### 2.3 Write Policies

The two primary cache write policies — write-through and write-back — were analyzed extensively by Smith (1982) and later by Jouppi (1990) [3][5]. Write-through updates both the cache and main memory on every write, ensuring consistency at the cost of higher memory bus traffic. Write-back only updates main memory when a dirty cache line is evicted, reducing bus traffic but adding complexity through dirty bits and eviction logic. Our design adopts **write-through** for simplicity and correctness in the prototype stage.

### 2.4 Split vs. Unified L1 Caches

The Harvard architecture (split instruction and data memory) was shown by Patterson and Hennessy [1] to eliminate structural hazards in pipelined processors — a CPU cannot simultaneously fetch an instruction and load data from a unified cache. Modern processors universally implement split L1 I-Cache and D-Cache for this reason. Our design follows this approach with separate `l1_icache` and `l1_dcache` modules.

### 2.5 Cache Arbitration

When separate instruction and data caches share a common backing memory, an arbiter is needed to manage simultaneous miss requests. Standard approaches grant priority to data cache requests [1], since data hazards in the execution pipeline are more immediately critical than instruction fetch delays (which the branch predictor and prefetch buffer can partially hide).

---

## 3. Proposed Solution

### 3.1 System Architecture

The proposed memory hierarchy consists of four hardware modules connected as shown in Figure 1:

```
CPU (Instruction Fetch)      CPU (Data Access)
         |                          |
   [L1 I-Cache]              [L1 D-Cache]
   (8-line, R/O)          (8-line, R/W, Write-Through)
         |    miss                  |    miss (PRIORITY)
         └──────────┬───────────────┘
                    |
           [Cache Controller]
           (Arbiter FSM — 3 states)
                    |
            [Main Memory]
           (256×32-bit, 3-cycle latency)
```
*Figure 1: Memory Hierarchy Block Diagram*

### 3.2 L1 Instruction Cache (`l1_icache.v`)

The instruction cache is a read-only, 8-line direct-mapped cache with a 32-bit word size. The 8-bit CPU address is partitioned as:
- **Tag [7:5]** — 3 bits identifying the memory block
- **Index [4:2]** — 3 bits selecting the cache line
- **Offset [1:0]** — 2 bits (word-aligned, unused in this implementation)

On a **hit** (valid bit set and tag matches), the cached instruction is returned in 1 clock cycle. On a **miss**, the CPU stall signal is asserted, a memory request is issued to the cache controller, and the cache is updated when main memory responds.

### 3.3 L1 Data Cache (`l1_dcache.v`)

The data cache extends the instruction cache with full read/write support. It uses the same direct-mapped organization with identical address partitioning. The **write-through policy** is implemented: on every CPU write, the cache line is updated AND a simultaneous write is issued to main memory via the cache controller. This eliminates the need for dirty bits and simplifies cache coherence.

### 3.4 Cache Controller / Arbiter (`cache_controller.v`)

A 3-state FSM arbitrates memory bus access:

| State | Description |
|-------|-------------|
| `IDLE` | No pending requests. Accepts new requests from either cache. |
| `SERVE_D` | Serving a D-Cache read miss (waiting for main memory). |
| `SERVE_I` | Serving an I-Cache read miss (waiting for main memory). |

D-Cache requests always pre-empt I-Cache requests in the IDLE state. The controller asserts `icache_ready` or `dcache_ready` when main memory returns valid data.

### 3.5 Main Memory Controller (`main_memory.v`)

The main memory module models a 256-word × 32-bit DRAM with parameterizable access latency (default: 3 clock cycles). A request/ready handshake protocol is used:
1. The cache controller asserts `req` with the target `addr`
2. The memory controller counts down 3 cycles
3. After 3 cycles, `ready` is pulsed high and `rd_data` is valid

### 3.6 Top-Level Integration (`memory_hierarchy_top.v`)

The top-level module instantiates all four sub-modules and connects their ports through internal wires, presenting a clean CPU-facing interface with separate instruction fetch and data access ports.

---

## 4. Individual Contributions

| Member | Module(s) | Contribution |
|--------|-----------|--------------|
| Member 1 (Kidrah-kun) | `l1_icache.v` | Designed and implemented the L1 Instruction Cache — direct-mapped read-only cache with hit/miss detection, stall generation, and performance counters |
| Member 2 | `l1_dcache.v` | Designed and implemented the L1 Data Cache — read/write support, write-through policy, and cache miss handling with CPU stall |
| Member 3 | `cache_controller.v` | Designed and implemented the Cache Arbiter FSM — 3-state priority arbitration between I-Cache and D-Cache miss requests |
| Member 4 | `main_memory.v`, `memory_hierarchy_top.v` | Designed the DRAM latency model with req/ready handshake and assembled all modules in the top-level integration module |
| Member 5 | `testbench/memory_hierarchy_tb.v`, `docs/diagrams/` | Developed the full 7-scenario testbench, waveform dump, automated pass/fail checking, and architecture documentation |

---

## 5. References

[1] D. A. Patterson and J. L. Hennessy, *Computer Organization and Design: The Hardware/Software Interface*, 5th ed. Waltham, MA: Morgan Kaufmann, 2014.

[2] M. V. Wilkes, "Slave Memories and Dynamic Storage Allocation," *IEEE Trans. Electron. Comput.*, vol. EC-14, no. 2, pp. 270–271, Apr. 1965.

[3] A. J. Smith, "Cache Memories," *ACM Comput. Surv.*, vol. 14, no. 3, pp. 473–530, Sep. 1982.

[4] M. D. Hill and A. J. Smith, "Evaluating Associativity in CPU Caches," *IEEE Trans. Comput.*, vol. 38, no. 12, pp. 1612–1630, Dec. 1989.

[5] N. P. Jouppi, "Improving Direct-Mapped Cache Performance by the Addition of a Small Fully-Associative Cache and Prefetch Buffers," in *Proc. 17th Int. Symp. Comput. Archit. (ISCA)*, Seattle, WA, May 1990, pp. 364–373.

[6] P. J. Denning, "The Working Set Model for Program Behavior," *Commun. ACM*, vol. 11, no. 5, pp. 323–333, May 1968.

[7] V. C. Hamacher, Z. G. Vranesic, and S. G. Zaky, *Computer Organization*, 5th ed. New York: McGraw-Hill, 2002.

[8] C. Zhang, F. Vahid, and W. Najjar, "A Highly Configurable Cache Architecture for Embedded Systems," in *Proc. 30th Int. Symp. Comput. Archit. (ISCA)*, San Diego, CA, Jun. 2003, pp. 136–146.

---

> **Note:** This is a Phase I draft. For Phase II, add:
> - Section 4: Results and Discussion (simulation waveforms, hit rate analysis, performance comparison)
> - Section 5: Conclusion
> - Update Individual Contributions with specific Phase II work

