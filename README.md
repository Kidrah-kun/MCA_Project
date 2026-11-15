# 🏗️ Instruction and Data Memory Hierarchy
### Modern Computer Architecture — MCA Project

![Verilog](https://img.shields.io/badge/Verilog-HDL-blue)
![Status](https://img.shields.io/badge/Phase-I%20In%20Progress-orange)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 📌 Project Overview

This project implements a **complete Instruction and Data Memory Hierarchy** in Verilog HDL, simulating the multi-level memory subsystem found in modern processors. The hierarchy spans from CPU-facing instruction/data caches down to main memory, with a fully functional cache controller implementing set-associative mapping and LRU replacement.

### Key Features
- ✅ Instruction Memory (ROM-based, word-addressable)
- ✅ Data Memory (RAM-based, byte-addressable)
- ✅ Direct-Mapped Cache with hit/miss detection
- ✅ Cache Controller (Write-through policy)
- ✅ Unified Main Memory backing store
- ✅ Full testbench with waveform output

---

## 👥 Group Members

| Name | GitHub | Role |
|------|--------|------|
| Hardik Hathwal | [@Kidrah-kun](https://github.com/Kidrah-kun) | Instruction Memory & Cache Design (`l1_icache.v`) |
| Kabir Sharma | [@Kabir-glitch](https://github.com/Kabir-glitch) | Data Memory Module (`l1_dcache.v`) |
| Abhinav Chaudhary | [@AbhinavChoudhary](https://github.com/AbhinavChoudhary) | Cache Controller FSM (`cache_controller.v`) |
| Akshith Kumar | [@AkshithKumar](https://github.com/AkshithKumar) | Main Memory Module & Top-Level (`main_memory.v`, `memory_hierarchy_top.v`) |
| Ayush Tiwari | [@AyushTiwari](https://github.com/AyushTiwari) | Testbench & Integration (`memory_hierarchy_tb.v`) |

---

## 📁 Repository Structure

```
MCA_Project/
│
├── src/                        # Verilog HDL source files
│   ├── l1_icache.v             # L1 Instruction Cache (8 lines, direct-mapped, read-only)
│   ├── l1_dcache.v             # L1 Data Cache (8 lines, write-through, read/write)
│   ├── cache_controller.v      # Cache Arbiter FSM (3 states, D-cache priority)
│   ├── main_memory.v           # DRAM controller (3-cycle latency, req/ready handshake)
│   ├── memory_hierarchy_top.v  # Top-level integration module
│   ├── instruction_memory.v    # Baseline instruction ROM
│   └── data_memory.v           # Baseline data RAM
│
├── testbench/                  # Simulation testbenches
│   └── memory_hierarchy_tb.v   # Full system testbench (7 validation test cases)
│
├── docs/                       # Documentation & report
│   ├── report/                 # IEEE project report (PDF, DOCX, Markdown)
│   │   ├── IEEE_Report_MCA_Group.pdf
│   │   ├── IEEE_Report_MCA_Group.docx
│   │   └── IEEE_Report_Draft.md
│   └── diagrams/               # Architecture block diagrams & specifications
│       └── architecture.md
│
├── sim/                        # Simulation outputs
│   └── waveforms/              # GTKWave .vcd dump files
│
└── README.md
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
# Install Icarus Verilog (macOS)
brew install icarus-verilog gtkwave

# Compile
iverilog -o sim/memory_hierarchy testbench/memory_hierarchy_tb.v src/*.v

# Simulate
vvp sim/memory_hierarchy

# View waveforms
gtkwave sim/waveforms/dump.vcd
```

---

## 🎬 Demo Video

> 📹 **[Watch the Prototype Demo Video](#)** ← *(link will be updated before submission)*

---

## 📄 Report

> 📄 **[IEEE Project Report (PDF)](docs/report/IEEE_Report_MCA_Group.pdf)** | **[Word Document](docs/report/IEEE_Report_MCA_Group.docx)** | **[Markdown Source](docs/report/IEEE_Report_Draft.md)**

---

## 📅 Submission

- **Phase I Deadline:** November 16, 2026, 11:59 PM (IST)
- **Submission Form:** [Google Form](https://docs.google.com/forms/d/e/1FAIpQLSc6Cx8OrOQLGj_X2ZMkyG5jc8mokq36mGRq2x8jGRNV1sbegA/viewform)

