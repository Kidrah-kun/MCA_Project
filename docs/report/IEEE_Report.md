---
title: "Instruction and Data Memory Hierarchy"
subtitle: "Modern Computer Architecture — Phase I Project Report"
author:
  - "Hardik Hathwal"
  - "Kabir Sharma"
  - "Abhinav Chaudhary"
  - "Akshith Kumar"
  - "Ayush Tiwari"
date: "November 2026"
geometry: "margin=1in"
fontsize: 11pt
linestretch: 1.15
header-includes:
  - \usepackage{booktabs}
  - \usepackage{float}
  - \usepackage{fancyhdr}
  - \usepackage{listings}
  - \usepackage{xcolor}
  - \pagestyle{fancy}
  - \fancyhf{}
  - \fancyhead[L]{Instruction and Data Memory Hierarchy}
  - \fancyhead[R]{Modern Computer Architecture}
  - \fancyfoot[C]{\thepage}
  - \lstset{basicstyle=\ttfamily\footnotesize, breaklines=true, frame=single, backgroundcolor=\color{gray!10}}
---

\begin{center}
\Large\textbf{Instruction and Data Memory Hierarchy}\\[0.4em]
\large Modern Computer Architecture — Phase I Project Report\\[0.8em]
\normalsize
\begin{tabular}{lll}
\textbf{Name} & \textbf{Role} \\
\hline
Hardik Hathwal   & Instruction Memory \& Cache Design (L1 I-Cache), Interactive Dashboard \\
Kabir Sharma     & Data Memory Module (L1 D-Cache) \\
Abhinav Chaudhary & Cache Controller (FSM Arbiter) \\
Akshith Kumar    & Main Memory Module \& Top-Level Integration \\
Ayush Tiwari     & Testbench \& Integration \\
\end{tabular}\\[0.6em]
\normalsize GitHub: \texttt{https://github.com/Kidrah-kun/MCA\_Project}\\
\normalsize November 2026
\end{center}

---

## Abstract

This paper presents the design and Verilog HDL implementation of a two-level instruction and data memory hierarchy for a modern RISC-style processor. The proposed architecture employs the Harvard memory organization principle, featuring separate L1 instruction and data caches connected through a priority-based finite state machine (FSM) arbiter to a main memory controller with realistic DRAM access latency simulation. The L1 caches are implemented as 8-line direct-mapped caches with a write-through policy to maintain data consistency. The cache arbiter grants priority to data cache (D-Cache) miss requests over instruction cache (I-Cache) requests, minimizing pipeline stalls during simultaneous misses. The main memory controller simulates a 3-cycle DRAM access latency using a request/ready handshake protocol. The design is validated through a comprehensive seven-scenario testbench implemented in Icarus Verilog, with waveform analysis performed in GTKWave. Simulation results confirm correct hit/miss detection, write-through cache coherence, CPU stall signal generation, and proper priority-based arbitration. The implementation demonstrates fundamental principles of modern computer memory organization and serves as a synthesizable RTL model for educational purposes.

**Keywords:** Memory Hierarchy, Cache Memory, Direct-Mapped Cache, Write-Through, Verilog HDL, Harvard Architecture, Cache Arbiter, FSM, DRAM Latency

---

## 1. Introduction

Modern processors face a fundamental performance bottleneck known as the **memory wall** — the growing disparity between CPU execution speed and main memory access latency. Contemporary processors execute instructions in nanoseconds while main DRAM memory requires tens to hundreds of nanoseconds per access. Without mitigation, this gap would leave the processor stalled waiting for data the vast majority of the time.

The universally adopted solution is the **memory hierarchy**: a multi-level system of progressively larger but slower memory units, with small, fast caches positioned between the CPU and main memory [1]. The hierarchy exploits two key principles of program behavior — **temporal locality** (recently accessed data is likely to be accessed again soon) and **spatial locality** (data near recently accessed addresses is likely to be accessed soon) — to keep frequently needed data in fast, low-latency cache storage.

This project designs and implements in Verilog HDL a functional model of such a hierarchy. Specifically, the design models a split L1 cache (separate instruction and data caches), a unified cache arbiter, and a DRAM-modeled main memory, mirroring the structure found in real-world processors such as the ARM Cortex-A series and RISC-V implementations. The design is modular, parameterizable, and fully simulatable with waveform output.

---

## 2. Literature Review

### 2.1 Cache Memory Fundamentals

The formal introduction of cache memory is attributed to Wilkes (1965), who described a "slave memory" to bridge the speed gap between the CPU and main memory [2]. Smith (1982) provided the seminal comprehensive survey of cache memory systems, analyzing the effect of cache size, block size, and replacement policy on hit rate across diverse workloads [3]. This foundational work established that even small direct-mapped caches dramatically reduce average memory access time through exploitation of program locality.

### 2.2 Direct-Mapped vs. Set-Associative Caches

Hill and Smith (1989) evaluated the tradeoffs between direct-mapped and set-associative cache organizations [4]. Their analysis demonstrated that while higher associativity reduces conflict misses (misses caused by two addresses mapping to the same cache line), direct-mapped caches achieve lower access latency due to simpler hardware — no comparator array is needed beyond a single tag comparison. For L1 caches where access latency directly contributes to the processor's critical path, direct-mapped organization is frequently preferred. Our design adopts direct-mapped caches for the L1 level.

### 2.3 Write Policies: Write-Through vs. Write-Back

Smith (1982) and Jouppi (1990) analyzed the two primary write policies in detail [3][5]. Under **write-through**, every CPU write updates both the cache and main memory simultaneously, ensuring consistency at the cost of higher memory bus traffic. Under **write-back**, the cache line is marked "dirty" on write, and main memory is updated only when the dirty line is evicted. Write-back reduces bus traffic but requires dirty bit tracking and eviction logic. Our prototype implements **write-through** for its simplicity and correctness guarantees without dirty bit management.

### 2.4 Split vs. Unified L1 Caches

The Harvard architecture (separate instruction and data memory paths) was shown by Patterson and Hennessy [1] to eliminate structural hazards in pipelined processors. A CPU with a unified L1 cache cannot simultaneously fetch an instruction and perform a data load/store in the same cycle — a critical limitation for pipelined execution. Modern processors universally implement split L1 I-Cache and D-Cache for this reason. Our design follows this approach with dedicated `l1_icache` and `l1_dcache` modules sharing a common main memory via the cache controller.

### 2.5 Cache Arbitration

When separate instruction and data caches share a common backing memory bus, an arbiter is needed to manage simultaneous miss requests. Standard practice, documented by Patterson and Hennessy [1], grants priority to data cache requests over instruction fetch requests. This is because a data hazard in the execution pipeline is immediately stalling — the processor cannot proceed until the data is available — while an instruction fetch miss may be partially hidden by out-of-order execution or branch prediction buffers.

---

## 3. Proposed Solution

### 3.1 System Architecture

The proposed memory hierarchy consists of four hardware modules connected as shown in Figure 1. The CPU interfaces with two separate caches: a read-only instruction cache (I-Cache) for instruction fetch and a read/write data cache (D-Cache) for load/store operations. Both caches connect through a shared cache controller to a single main memory module.

```
CPU (Instruction Fetch)      CPU (Data Access)
         |                          |
  [L1 I-Cache]              [L1 D-Cache]
  8-line, Read-Only         8-line, R/W, Write-Through
         |  miss                    |  miss (PRIORITY)
         └──────────┬───────────────┘
                    |
           [Cache Controller]
           FSM Arbiter — 3 States
                    |
            [Main Memory]
           256×32-bit, 3-cycle DRAM latency
```
*Figure 1: Memory Hierarchy System Architecture*

### 3.2 L1 Instruction Cache — `l1_icache.v` (Hardik Hathwal)

The instruction cache is a **read-only, 8-line direct-mapped cache** with 32-bit word width. The 8-bit CPU address is partitioned as:

| Bits   | Field  | Width  | Purpose                              |
|--------|--------|--------|--------------------------------------|
| [7:5]  | Tag    | 3 bits | Identifies which memory block is cached |
| [4:2]  | Index  | 3 bits | Selects one of 8 cache lines         |
| [1:0]  | Offset | 2 bits | Byte offset (word-aligned, unused)   |

On a **hit** (valid bit set and tag matches the address tag), the cached instruction is returned in 1 clock cycle. On a **miss**, the CPU stall signal is asserted, a memory request is issued to the cache controller, and the cache line is updated when main memory responds via the `mem_ready` signal. The module includes parameterizable `CACHE_LINES`, `ADDR_WIDTH`, and `DATA_WIDTH` for scalability, plus internal hit/miss performance counters for simulation monitoring.

### 3.3 L1 Data Cache — `l1_dcache.v` (Kabir Sharma)

The data cache extends the instruction cache architecture with full read/write support. It uses the same 8-line direct-mapped organization with identical address partitioning. The **write-through policy** is implemented: on every CPU write, the cache line is simultaneously updated and a write request is issued to main memory via the cache controller. This eliminates dirty bit tracking while guaranteeing that main memory always holds the most recent data value. On a read miss, the CPU is stalled and the missing word is fetched from main memory into the cache.

### 3.4 Cache Controller / Arbiter — `cache_controller.v` (Abhinav Chaudhary)

A 3-state Mealy FSM arbitrates memory bus access between the two L1 caches:

| State     | Description                                                     |
|-----------|-----------------------------------------------------------------|
| `IDLE`    | No pending miss requests. Accepts new requests from either cache. D-Cache takes priority. |
| `SERVE_D` | Serving a D-Cache read miss — waiting for main memory `ready` pulse. |
| `SERVE_I` | Serving an I-Cache read miss — waiting for main memory `ready` pulse. |

When both caches simultaneously assert miss requests in the `IDLE` state, the controller transitions to `SERVE_D` (D-Cache priority). The I-Cache request is deferred until the next `IDLE` state. D-Cache write requests are handled inline in `IDLE` without a state transition since write-through writes do not require a main memory read response. A `busy` output is provided for external stall logic.

### 3.5 Main Memory Controller — `main_memory.v` (Akshith Kumar)

The main memory module models a 256-word × 32-bit DRAM with a parameterizable access latency (default: 3 clock cycles). A **request/ready handshake** protocol is used: the cache controller asserts `req` with the target address; the memory controller latches the request, counts down 3 cycles, then asserts `ready` and presents valid `rd_data`. Write requests are handled immediately on the same handshake path. The module includes an `access_count` register that tracks the total number of memory accesses during simulation.

### 3.6 Top-Level Integration — `memory_hierarchy_top.v` (Akshith Kumar)

The top-level module instantiates all four sub-modules and connects them via internal wires, presenting a clean CPU-facing interface with separate instruction fetch ports (`if_addr`, `if_instr`, `if_stall`) and data access ports (`d_addr`, `d_we`, `d_wr_data`, `d_rd_data`, `d_stall`).

---

## 4. Individual Contributions

| Member              | File(s) Owned                                      | Contribution Summary                                                                                           |
|---------------------|----------------------------------------------------|----------------------------------------------------------------------------------------------------------------|
| **Hardik Hathwal**  | `src/l1_icache.v`, `dashboard.html`, `docs/`       | Designed and implemented the L1 Instruction Cache — direct-mapped, parameterizable, with hit/miss detection, stall generation, and performance counters. Built the interactive simulation dashboard (`dashboard.html`) and authored the IEEE report and architecture diagrams. |
| **Kabir Sharma**    | `src/l1_dcache.v`                                 | Designed and implemented the L1 Data Cache — read/write support, write-through policy, hit/miss logic, and simulation debug display. |
| **Abhinav Chaudhary** | `src/cache_controller.v`                        | Designed and implemented the Cache Arbiter FSM — 3-state priority-based arbitration between I-Cache and D-Cache miss requests, busy signal, and request counters. |
| **Akshith Kumar**   | `src/main_memory.v`, `src/memory_hierarchy_top.v` | Designed the DRAM latency model with req/ready handshake and access counters; assembled all modules in the top-level integration with clean port wiring. |
| **Ayush Tiwari**    | `testbench/memory_hierarchy_tb.v`                 | Developed the full 7-scenario testbench — DUT instantiation, clock generation, I-Cache and D-Cache test cases (T1–T7), automated pass/fail checker, VCD waveform dump, and simulation statistics. |

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
