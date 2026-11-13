# Memory Hierarchy Architecture

## System Block Diagram

```
         ┌──────────────────────────────────────────────┐
         │                    CPU                        │
         │   Instruction Fetch ────────── Data Access   │
         └────────────┬────────────────────────┬─────────┘
                      │ if_addr (8-bit)         │ d_addr / d_we / d_wr_data
                      ▼                          ▼
           ┌─────────────────┐       ┌───────────────────────┐
           │  L1 I-Cache     │       │      L1 D-Cache        │
           │                 │       │                        │
           │  Lines:   8     │       │  Lines:   8            │
           │  Width:  32-bit │       │  Width:  32-bit        │
           │  Type: Direct-  │       │  Type: Direct-Mapped   │
           │        Mapped   │       │  Write: Write-Through  │
           │  Access: R/O    │       │  Access: R/W           │
           │                 │       │                        │
           │ HIT  → 1 cycle  │       │ HIT  → 1 cycle         │
           │ MISS → stall    │       │ MISS → stall (D-prio.) │
           └────────┬────────┘       └────────────┬───────────┘
                    │ icache_req                   │ dcache_req
                    │ (on read miss)               │ (on miss — HIGH PRIORITY)
                    └──────────────┬───────────────┘
                                   ▼
                    ┌──────────────────────────────┐
                    │      Cache Controller         │
                    │       (Arbiter FSM)           │
                    │                              │
                    │  States:                     │
                    │  ┌────────────────────────┐  │
                    │  │ IDLE                   │  │
                    │  │  ├─ dcache_req? →SERVE_D│ │
                    │  │  └─ icache_req? →SERVE_I│ │
                    │  │ SERVE_D (D-cache prio.) │  │
                    │  │ SERVE_I (I-cache)       │  │
                    │  └────────────────────────┘  │
                    │                              │
                    │  D-Cache always gets priority │
                    └──────────────┬───────────────┘
                                   │ mem_addr / mem_we / mem_req
                                   ▼
                    ┌──────────────────────────────┐
                    │         Main Memory           │
                    │                              │
                    │  Size:    256 × 32-bit words  │
                    │  Latency: 3 clock cycles      │
                    │  Protocol: req/ready handshake│
                    │  Interface: Synchronous R/W   │
                    └──────────────────────────────┘
```

---

## Address Partitioning (8-bit address, 8-line caches)

```
 7   6   5   4   3   2   1   0
┌───┬───┬───┬───┬───┬───┬───┬───┐
│       TAG     │    INDEX  │ OF│
│    [7:5]      │   [4:2]   │SET│
│   (3 bits)    │  (3 bits) │[1:0]│
└───┴───┴───┴───┴───┴───┴───┴───┘
       ↓               ↓
  Identifies       Selects which
  which memory     of the 8 cache
  block is cached  lines to check
```

| Bits | Field | Width | Purpose |
|------|-------|-------|---------|
| [7:5] | Tag | 3 bits | Identifies the memory block stored in a line |
| [4:2] | Index | 3 bits | Selects one of the 8 cache lines |
| [1:0] | Offset | 2 bits | Byte within the word (unused — word-aligned) |

---

## Cache Hit/Miss Flow

```
CPU issues address
       │
       ▼
  Compute index = addr[4:2]
       │
       ▼
  Check cache_valid[index] AND cache_tag[index] == addr[7:5]
       │
   ┌───┴───┐
  YES     NO
  (HIT)  (MISS)
   │       │
   │       ▼
   │   Assert cpu_stall = 1
   │   Send mem_req to Cache Controller
   │   Wait for mem_ready
   │   Update cache_data, cache_tag, cache_valid
   │   De-assert cpu_stall
   │       │
   └───────┘
       ▼
  Return data to CPU
```

---

## Cache Specifications Summary

| Parameter | L1 I-Cache | L1 D-Cache | Main Memory |
|-----------|------------|------------|-------------|
| Size | 8 × 32-bit | 8 × 32-bit | 256 × 32-bit |
| Organization | Direct-Mapped | Direct-Mapped | — |
| Access | Read-Only | Read + Write | Read + Write |
| Write Policy | N/A | Write-Through | — |
| Hit Latency | 1 cycle | 1 cycle | — |
| Miss Penalty | 3+ cycles | 3+ cycles | 3 cycles |
| Replacement | Overwrite on miss | Overwrite on miss | — |

---

## Module Dependency Diagram

```
memory_hierarchy_top.v
├── l1_icache.v          (Member 1)
├── l1_dcache.v          (Member 2)
├── cache_controller.v   (Member 3)
└── main_memory.v        (Member 4)

memory_hierarchy_tb.v    (Member 5)
└── instantiates memory_hierarchy_top.v
```

