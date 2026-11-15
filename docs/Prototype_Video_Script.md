# 🎬 Prototype Video Demonstration Script (< 5 Minutes)
### Modern Computer Architecture — Phase I Project
**Project Title:** Instruction and Data Memory Hierarchy  
**Repository:** [https://github.com/Kidrah-kun/MCA_Project](https://github.com/Kidrah-kun/MCA_Project)

---

## ⏱️ Video Time Budget (Strict 5-Minute Limit)

| Section | Speaker | Topic | Target Time | Cumulative |
|---------|---------|-------|-------------|------------|
| 1 | Hardik Hathwal | Project Idea & Team Introductions | 0:00 – 0:45 | 0:45 |
| 2 | Hardik Hathwal | Architecture Overview & L1 I-Cache | 0:45 – 1:30 | 1:30 |
| 3 | Kabir Sharma | L1 D-Cache & Write-Through Policy | 1:30 – 2:15 | 2:15 |
| 4 | Abhinav Chaudhary | Cache Controller / Arbiter FSM | 2:15 – 3:00 | 3:00 |
| 5 | Akshith Kumar | Main Memory (DRAM Latency) & Top-Level | 3:00 – 3:45 | 3:45 |
| 6 | Ayush Tiwari | Testbench Demonstration & Simulation | 3:45 – 4:45 | 4:45 |
| 7 | Hardik Hathwal | Summary & Phase II Roadmap | 4:45 – 5:00 | 5:00 |

---

## 📝 Spoken Script & Screen Actions

### Section 1: Introduction & Team (0:00 – 0:45)
**Speaker:** Hardik Hathwal  
**Screen Display:** Title slide showing project name, team table, and GitHub repository URL.

> *"Hello everyone and respected faculty. Today our group presents our Phase I prototype demonstration for Modern Computer Architecture on the topic: **Instruction and Data Memory Hierarchy**.*
>
> *In modern computer architecture, the 'Memory Wall' represents the severe performance disparity between ultra-fast CPU cores and high-latency main memory. To resolve this bottleneck, we have designed and implemented a synthesizable Harvard-style two-level memory hierarchy in Verilog HDL.*
>
> *Our team consists of 5 members:*
> 1. *Hardik Hathwal — Lead & Instruction Cache Design*
> 2. *Kabir Sharma — Data Cache Module*
> 3. *Abhinav Chaudhary — Cache Controller & Arbiter FSM*
> 4. *Akshith Kumar — Main Memory DRAM Modeling & Top-Level Integration*
> 5. *Ayush Tiwari — Verification Testbench & Simulation Integration"*

---

### Section 2: Architecture & L1 I-Cache (0:45 – 1:30)
**Speaker:** Hardik Hathwal  
**Screen Display:** Show `docs/diagrams/architecture.md` block diagram, then switch to `src/l1_icache.v`.

> *"As shown in our architecture block diagram, we separate instruction fetch and data memory access paths to eliminate pipeline structural hazards.*
>
> *I developed `l1_icache.v`, which is an 8-line direct-mapped, read-only cache. It uses an 8-bit address split into a 3-bit tag and 3-bit index. On a cache hit, instructions are served to the CPU in a single cycle without pipeline delay. On a compulsory or conflict miss, it automatically asserts a CPU stall signal and sends a memory read request to the arbiter. I have also added parameterization and performance counters for hit/miss profiling."*

---

### Section 3: L1 Data Cache (1:30 – 2:15)
**Speaker:** Kabir Sharma  
**Screen Display:** Show `src/l1_dcache.v` focusing on read/write logic.

> *"I am Kabir Sharma, and I implemented `l1_dcache.v`. Unlike the instruction cache, data memory requires bidirectional read and write support.*
>
> *Our D-cache employs a **write-through policy**: whenever the CPU executes a store instruction, both the L1 data cache line and the backing main memory are updated concurrently. This guarantees memory consistency and simplifies cache coherence without requiring dirty bits. On read misses, the CPU stalls while the missing word is retrieved from main memory through our handshake interface."*

---

### Section 4: Cache Controller & Arbiter FSM (2:15 – 3:00)
**Speaker:** Abhinav Chaudhary  
**Screen Display:** Show `src/cache_controller.v` state definitions and FSM case block.

> *"I am Abhinav Chaudhary, and I designed `cache_controller.v`. When both instruction and data caches experience misses, they share a common memory bus. My module acts as an arbiter using a 3-state finite state machine: IDLE, SERVE_D, and SERVE_I.*
>
> *Crucially, our controller grants **priority to D-Cache requests** because resolving data hazards directly unblocks executing arithmetic and control units, whereas instruction fetch delays can often be mitigated with prefetch buffers. The controller coordinates request routing, memory enables, and data returns."*

---

### Section 5: Main Memory & Top-Level (3:00 – 3:45)
**Speaker:** Akshith Kumar  
**Screen Display:** Show `src/main_memory.v` and `src/memory_hierarchy_top.v`.

> *"I am Akshith Kumar. I developed `main_memory.v` and `memory_hierarchy_top.v`.*
>
> *To simulate realistic physical memory, `main_memory.v` models a 256-word DRAM with a parameterized 3-cycle access latency using a request-ready handshake protocol. It latches requests, counts down delay cycles, and pulses `ready` when the read data is valid.*
>
> *In `memory_hierarchy_top.v`, I integrated all 4 sub-modules into a cohesive memory subsystem presenting clean instruction fetch and data read/write ports to the processor."*

---

### Section 6: Testbench & Simulation Waveforms (3:45 – 4:45)
**Speaker:** Ayush Tiwari  
**Screen Display:** Show terminal running testbench simulation and/or GTKWave waveform window.

> *"I am Ayush Tiwari, and I developed the comprehensive verification suite in `memory_hierarchy_tb.v`.*
>
> *Our testbench executes 7 rigorous verification scenarios:*
> - *Test 1: Cold start I-Cache miss at address 0x00 with CPU stall*
> - *Test 2: Subsequent I-Cache hit returning in 1 cycle*
> - *Test 3: D-Cache read miss at address 0x05 retrieving 0x0000000A*
> - *Test 4: Immediate D-Cache read hit verification*
> - *Test 5: D-Cache write-through operation storing 0xBEEFCAFE*
> - *Test 6: Readback verification confirming the written word hits immediately*
> - *Test 7: Conflict/new address miss handling*
>
> *All 7 test cases pass with zero errors, and full VCD waveforms are recorded for timing analysis."*

---

### Section 7: Conclusion & Wrap-Up (4:45 – 5:00)
**Speaker:** Hardik Hathwal  
**Screen Display:** GitHub repository page showing report and commit history.

> *"In conclusion, all Phase I deliverables—including the Verilog prototype, IEEE report, and collaborative repository—are completed. For Phase II, we plan to extend the hierarchy with 2-way set associativity and replacement policies. Thank you!"*

---

## 🛠️ Recording Checklist Before Submission

1. **Keep it under 5:00 minutes** (e.g. 4:30 – 4:55 is optimal).
2. **Audio Check:** Ensure every member's voice is clearly audible.
3. **Upload to YouTube (as Unlisted)** or **Google Drive (set permissions to 'Anyone with link can view')**.
4. **Paste the video URL into `README.md`** under the `## 🎬 Demo Video` section.
5. **Commit & push** the updated `README.md`.
6. Submit the Google Form: [Phase I Submission Form](https://docs.google.com/forms/d/e/1FAIpQLSc6Cx8OrOQLGj_X2ZMkyG5jc8mokq36mGRq2x8jGRNV1sbegA/viewform).
