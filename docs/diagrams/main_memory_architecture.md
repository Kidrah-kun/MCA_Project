# Main Memory & Top-Level Integration Architecture
**Author:** Akshith Kumar (Member 4)  
**Modules:** `src/main_memory.v` & `src/memory_hierarchy_top.v`  
**Project:** Instruction and Data Memory Hierarchy (MCA Project)

---

## 1. Main Memory Controller (`main_memory.v`) Microarchitecture

The Main Memory module acts as the realistic DRAM backing store for the memory hierarchy. Because physical DRAM takes multiple clock cycles to charge lines and sense data, this module models a **3-cycle latency pipeline** with a strict **request/ready handshake**.

### 1.1 Microarchitecture Image
![Main Memory Architecture](main_memory_architecture.png)

### 1.2 Detailed Block Diagram

```
                              ┌────────────────────────────────────────────────────────────┐
                              │                 main_memory Module (256x32)                │
                              │                                                            │
    clk ─────────────────────►│                                                            │
    rst ─────────────────────►│                                                            │
                              │                                                            │
    req ─────────────────────►│──┐                                                         │
    we ──────────────────────►│──┼─►┌─────────────────────────┐                            │
    addr[7:0] ───────────────►│──┼─►│   Request Latch Unit    │                            │
    wr_data[31:0] ───────────►│──┘  │  - pending              │                            │
                              │     │  - pending_we           │                            │
                              │     │  - pending_addr[7:0]    │                            │
                              │     │  - pending_wr_data[31:0]│                            │
                              │     └────────────┬────────────┘                            │
                              │                  │                                         │
                              │                  ▼                                         │
                              │     ┌─────────────────────────┐                            │
                              │     │ 3-Cycle Latency Counter │                            │
                              │     │ delay_cnt[1:0] (0 to 2) │                            │
                              │     └────────────┬────────────┘                            │
                              │                  │ (when delay_cnt == LATENCY - 1)         │
                              │                  ▼                                         │
                              │     ┌──────────────────────────────────────────────┐       │
                              │     │               DRAM Storage Core              │       │
                              │     │          256 x 32-bit Memory Array           │       │
                              │     │                                              │       │
                              │     │  Write: mem[pending_addr] <= pending_wr_data │       │
                              │     │  Read : rd_data           <= mem[pending_addr│───────┼──► rd_data[31:0]
                              │     └──────────────────────┬───────────────────────┘       │
                              │                            │                               │
                              │                            ▼                               │
                              │     ┌─────────────────────────┐                            │
                              │     │     Handshake Strobe    │                            │
                              │     │  ready <= 1 (1 cycle)   │────────────────────────────┼──► ready
                              │     └─────────────────────────┘                            │
                              │                            │                               │
                              │                            ▼                               │
                              │     ┌──────────────────────────────────────────────┐       │
                              │     │         Performance / Instrumentation        │       │
                              │     │  - access_count <= access_count + 1          │       │
                              │     │  - synthesis-guarded simulation $display     │       │
                              │     │  - final simulation summary block            │       │
                              │     └──────────────────────────────────────────────┘       │
                              └────────────────────────────────────────────────────────────┘
```

---

### 1.2 Mermaid Microarchitecture Flowchart

```mermaid
flowchart TD
    subgraph INPUTS["External Bus from Cache Controller"]
        IN_REQ["req (Request Strobe)"]
        IN_WE["we (Write Enable)"]
        IN_ADDR["addr[7:0] (Address)"]
        IN_WDATA["wr_data[31:0] (Write Data)"]
    end

    subgraph LATCH["Request Latching Stage"]
        COND{"req == 1 &&\npending == 0 ?"}
        REG_PEND["pending <= 1\ndelay_cnt <= 0"]
        REG_ADDR["pending_addr <= addr"]
        REG_WE["pending_we <= we"]
        REG_DATA["pending_wr_data <= wr_data"]
    end

    subgraph TIMER["3-Cycle Latency Engine"]
        CHECK_PEND{"pending == 1 ?"}
        COUNT_CHECK{"delay_cnt == LATENCY - 1\n(delay_cnt == 2) ?"}
        INC["delay_cnt <= delay_cnt + 1\n(Wait next clock cycle)"]
    end

    subgraph CORE["DRAM Storage Access"]
        ACC_INC["access_count <= access_count + 1\npending <= 0"]
        WE_CHECK{"pending_we == 1 ?"}
        DO_WRITE["mem[pending_addr] <= pending_wr_data\n(Synchronous Write)"]
        DO_READ["rd_data <= mem[pending_addr]\nready <= 1\n(Data Valid Strobe)"]
    end

    subgraph OUTPUTS["Outputs to Controller"]
        OUT_RDATA["rd_data[31:0]"]
        OUT_READY["ready (Valid Strobe)"]
    end

    IN_REQ --> COND
    IN_WE --> COND
    IN_ADDR --> COND
    IN_WDATA --> COND

    COND -- Yes --> REG_PEND
    COND -- Yes --> REG_ADDR
    COND -- Yes --> REG_WE
    COND -- Yes --> REG_DATA
    COND -- No (Idle) --> CHECK_PEND

    REG_PEND --> CHECK_PEND
    CHECK_PEND -- Yes --> COUNT_CHECK
    CHECK_PEND -- No --> COND

    COUNT_CHECK -- No --> INC
    COUNT_CHECK -- Yes --> ACC_INC

    ACC_INC --> WE_CHECK
    WE_CHECK -- Yes (Write) --> DO_WRITE
    WE_CHECK -- No (Read) --> DO_READ

    DO_READ --> OUT_RDATA
    DO_READ --> OUT_READY
```

---

### 1.3 Latency & Handshake Timing Waveform

#### Read Operation Timing (3-Cycle Latency):
```text
Clock Cycle:      C0        C1        C2        C3        C4
                 ___       ___       ___       ___       ___
clk          ___/   \_____/   \_____/   \_____/   \_____/   \___

req          ___/¯¯¯\___________________________________________  (Pulses high for 1 cycle)
addr         ===< 0x05 >========================================
we           ___________________________________________________  (0 for Read)

pending      _______/¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯\_________________  (Asserted for 3 cycles)
delay_cnt    ===< 0x0 >====< 0x1 >====< 0x2 >====< 0x0 >========  (Counts: 0 -> 1 -> 2)

rd_data      =================================< 0x0A >==========  (Data ready at C3)
ready        _________________________________/¯¯¯¯¯\___________  (Pulses high for 1 cycle)
```

#### Write-Through Operation Timing:
```text
Clock Cycle:      C0        C1        C2        C3        C4
                 ___       ___       ___       ___       ___
clk          ___/   \_____/   \_____/   \_____/   \_____/   \___

req          ___/¯¯¯\___________________________________________
addr         ===< 0x02 >========================================
we           ___/¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯\_________________  (1 for Write)
wr_data      ===< 0xBEEFCAFE >==================================

pending      _______/¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯\_________________
delay_cnt    ===< 0x0 >====< 0x1 >====< 0x2 >====< 0x0 >========

mem[0x02]    ===< old >=======================< 0xBEEFCAFE >====  (Written at C3)
ready        ___________________________________________________  (Writes acknowledge to cache)
```

---

## 2. Top-Level Integration (`memory_hierarchy_top.v`) Architecture

The Top-Level module connects the entire memory subsystem together and interfaces directly to the CPU.

### 2.1 System Architecture Image
![System Hierarchy Architecture](system_hierarchy_architecture.png)

### 2.2 System Interconnect Diagram

```mermaid
graph TB
    subgraph CPU["CPU CORE INTERFACE"]
        IF_ADDR["if_addr[7:0] (PC Fetch)"]
        IF_INSTR["if_instr[31:0] (Instruction)"]
        IF_STALL["if_stall (Pipeline Stall)"]
        
        D_ADDR["d_addr[7:0] (Data Addr)"]
        D_WE["d_we (Store Enable)"]
        D_WDATA["d_wr_data[31:0] (Store Data)"]
        D_RDATA["d_rd_data[31:0] (Load Data)"]
        D_STALL["d_stall (Pipeline Stall)"]
    end

    subgraph L1_I["L1 Instruction Cache (l1_icache.v)"]
        IC_CORE["8 Cache Lines (Direct-Mapped)\nRead-Only\nTag: [7:5] | Index: [4:2]"]
        IC_HIT["icache_hit"]
        IC_MISS["icache_miss"]
    end

    subgraph L1_D["L1 Data Cache (l1_dcache.v)"]
        DC_CORE["8 Cache Lines (Direct-Mapped)\nWrite-Through Policy\nTag: [7:5] | Index: [4:2]"]
        DC_HIT["dcache_hit"]
        DC_MISS["dcache_miss"]
    end

    subgraph CTRL["Cache Controller / Arbiter FSM (cache_controller.v)"]
        ARB["Priority Arbiter FSM\nSERVE_D (Priority) > SERVE_I"]
        BUSY["busy"]
    end

    subgraph MM["Main Memory (main_memory.v) — Member 4"]
        DRAM["256 x 32-bit DRAM Array\n3-Cycle Latency Counter\nHandshake Controller"]
    end

    %% CPU to I-Cache
    IF_ADDR --> IC_CORE
    IC_CORE --> IF_INSTR
    IC_CORE --> IF_STALL
    IC_CORE --> IC_HIT
    IC_CORE --> IC_MISS

    %% CPU to D-Cache
    D_ADDR --> DC_CORE
    D_WE --> DC_CORE
    D_WDATA --> DC_CORE
    DC_CORE --> D_RDATA
    DC_CORE --> D_STALL
    DC_CORE --> DC_HIT
    DC_CORE --> DC_MISS

    %% I-Cache to Controller
    IC_CORE -- "icache_req, icache_mem_addr" --> ARB
    ARB -- "icache_mem_data, icache_mem_ready" --> IC_CORE

    %% D-Cache to Controller
    DC_CORE -- "dcache_req, dcache_mem_addr\ndcache_mem_we, dcache_mem_wr_data" --> ARB
    ARB -- "dcache_mem_data, dcache_mem_ready" --> DC_CORE

    %% Controller to Main Memory (Wired by Akshith)
    ARB -- "mem_addr[7:0], mem_we, mem_wr_data[31:0]" --> DRAM
    ARB -. "busy" .-> BUSY
    
    %% Memory Request Logic (Akshith's continuous assignment)
    IC_CORE -. "icache_req" .-> MREQ_OR["assign mem_req =\nmem_we | (icache_req | dcache_req)"]
    DC_CORE -. "dcache_req" .-> MREQ_OR
    ARB -. "mem_we" .-> MREQ_OR
    MREQ_OR ==> DRAM

    %% Main Memory Response
    DRAM -- "mem_rd_data[31:0], mem_ready" --> ARB
```

---

## 3. Summary of Design Choices

1. **Parameterization:**  
   `DEPTH=256`, `DATA_WIDTH=32`, `ADDR_WIDTH=8`, and `LATENCY=3` are parameterized so memory depth or latency can be scaled without touching module internals.
2. **Glitch-Free Bus Latching:**  
   The `pending_*` registers prevent bus transitions on the shared memory bus from corrupting an active multi-cycle DRAM access.
3. **Simulation Observability:**  
   `access_count` and `$display` traces provide instant feedback in ModelSim/Icarus Verilog without impacting FPGA synthesis due to `// synthesis translate_off`.
4. **Coherent Memory Request Routing:**  
   The continuous assignment `assign mem_req = mem_we | (icache_req | dcache_req);` ensures the DRAM controller begins counting latency as soon as either cache misses or issues a write-through store.
