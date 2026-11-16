# 🏗️ Instruction and Data Memory Hierarchy
### Modern Computer Architecture — MCA Project

![Verilog](https://img.shields.io/badge/Verilog-HDL-blue)
![Status](https://img.shields.io/badge/Phase-I%20In%20Progress-orange)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 📌 Project Overview

This project implements a **complete Instruction and Data Memory Hierarchy** in Verilog HDL, simulating the multi-level memory subsystem found in modern processors. The hierarchy spans from CPU-facing instruction/data caches down to main memory, with a fully functional cache controller implementing set-associative mapping and LRU replacement.

### Key Features
- ✅ **Harvard Memory Architecture:** Dedicated, concurrent L1 Instruction Cache (`l1_icache.v`) and L1 Data Cache (`l1_dcache.v`)
- ✅ **Direct-Mapped Organization:** 8-line caches with 3-bit tag, 3-bit index, and single-cycle hit latency
- ✅ **Write-Through Coherence:** Immediate write propagation to main memory, guaranteeing consistency without dirty bits
- ✅ **Priority-Based Cache Arbiter:** 3-state FSM controller granting D-Cache priority over I-Cache during simultaneous misses
- ✅ **Realistic DRAM Modeling:** Parameterizable 3-cycle memory latency with asynchronous/synchronous request-ready handshake
- ✅ **Automated Verification:** 7-scenario self-checking testbench (`memory_hierarchy_tb.v`) with GTKWave `.vcd` waveform dumping

---

## 👥 Group Members

| Name | GitHub | Role & Primary Module |
|------|--------|-----------------------|
| Hardik Hathwal | [@Kidrah-kun](https://github.com/Kidrah-kun) | Lead, L1 Instruction Cache (`l1_icache.v`), IEEE Report |
| Kabir Sharma | [@Kabir-glitch](https://github.com/Kabir-glitch) | L1 Data Cache (`l1_dcache.v`) & Write-Through Policy |
| Abhinav Chaudhary | [@AbhinavChoudhary](https://github.com/AbhinavChoudhary) | Cache Controller & Priority Arbiter FSM (`cache_controller.v`) |
| Akshith Kumar | [@AkshithKumar](https://github.com/AkshithKumar) | DRAM Controller (`main_memory.v`) & Top-Level (`memory_hierarchy_top.v`) |
| Ayush Tiwari | [@AyushTiwari](https://github.com/AyushTiwari) | Verification Testbench & Simulation (`memory_hierarchy_tb.v`) |

---

## 📁 Repository Structure

```
MCA_Project/
│
├── src/                        # Synthesizable Verilog HDL modules
│   ├── l1_icache.v             # L1 Instruction Cache (8 lines, direct-mapped, read-only)
│   ├── l1_dcache.v             # L1 Data Cache (8 lines, write-through, read/write)
│   ├── cache_controller.v      # Cache Arbiter FSM (3 states, D-cache priority)
│   ├── main_memory.v           # DRAM controller (3-cycle latency, req/ready handshake)
│   └── memory_hierarchy_top.v  # Top-level integration module
│
├── testbench/                  # Simulation testbenches
│   └── memory_hierarchy_tb.v   # Full system testbench (7 validation test cases)
│
├── docs/                       # Documentation, architecture specs, and reports
│   ├── Prototype_Video_Script.md # 5-minute prototype demo video recording script
│   ├── diagrams/
│   │   └── architecture.md     # System block diagrams, address split & FSM tables
│   └── report/
│       ├── IEEE_Report_MCA_Group.pdf   # Official Phase I IEEE Project Report (PDF)
│       ├── IEEE_Report_MCA_Group.docx  # Word Document version
│       └── IEEE_Report.md              # Markdown source document
│
├── sim/                        # Simulation outputs
│   └── waveforms/              # GTKWave .vcd dump files (dump.vcd)
│
├── .gitignore                  # Git exclusions for build and waveform artifacts
└── README.md                   # Project documentation
```

---

## 🧠 Architecture

```
┌─────────────┐
│     CPU     │
└──────┬──────┘
       │
  ┌────▼────┐    ┌─────────────────────┐
  │ I-Cache │    │      D-Cache        │
  │ (Instr) │    │ (Data / Read-Write) │
  └────┬────┘    └──────────┬──────────┘
       │                    │
  ┌────▼────────────────────▼────┐
  │        Cache Controller      │
  │   (Hit/Miss, LRU, Write-     │
  │    through / Write-back)     │
  └────────────────┬─────────────┘
                   │
         ┌─────────▼──────────┐
         │    Main Memory     │
         │   (256 x 32-bit)   │
         └────────────────────┘
```

---

## ⚙️ Tools & Environment

| Tool | Purpose |
|------|---------|
| [Icarus Verilog](http://iverilog.icarus.com/) | Verilog compilation & simulation |
| [GTKWave](http://gtkwave.sourceforge.net/) | Waveform visualization |
| [VS Code + Verilog ext.](https://code.visualstudio.com/) | Development environment |

### Running the Simulation

```bash
# Install Icarus Verilog and GTKWave (macOS)
brew install icarus-verilog gtkwave

# Compile all Verilog modules with testbench
iverilog -o sim/memory_hierarchy testbench/memory_hierarchy_tb.v src/*.v

# Execute simulation
vvp sim/memory_hierarchy

# Output confirms 7/7 test cases passing:
# === Done: 7 PASS, 0 FAIL ===

# View interactive waveforms in GTKWave
gtkwave sim/waveforms/dump.vcd
```

---

## 🎬 Demo Video

> 📹 **[Watch the Prototype Demo Video](#)** ← *(link will be updated before submission)*

---

## 📄 Report

> 📄 **[IEEE Project Report (PDF)](docs/report/IEEE_Report_MCA_Group.pdf)** | **[Word Document](docs/report/IEEE_Report_MCA_Group.docx)** | **[Markdown Source](docs/report/IEEE_Report.md)**

---

## 📅 Submission

- **Phase I Deadline:** November 16, 2026, 11:59 PM (IST)
- **Submission Form:** [Google Form](https://docs.google.com/forms/d/e/1FAIpQLSc6Cx8OrOQLGj_X2ZMkyG5jc8mokq36mGRq2x8jGRNV1sbegA/viewform)

