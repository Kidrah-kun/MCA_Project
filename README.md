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
| Member 1 | [@Kidrah-kun](https://github.com/Kidrah-kun) | Instruction Memory & Cache Design |
| Member 2 | — | Data Memory Module |
| Member 3 | — | Cache Controller |
| Member 4 | — | Main Memory Module |
| Member 5 | — | Testbench & Integration |

> 📝 *Update this table with all 5 group members' names and GitHub usernames.*

---

## 📁 Repository Structure

```
MCA_Project/
│
├── src/                        # Verilog source files
│   ├── instruction_memory.v    # Instruction ROM
│   ├── data_memory.v           # Data RAM
│   ├── cache_controller.v      # Cache hit/miss + replacement logic
│   ├── main_memory.v           # Backing main memory
│   └── memory_hierarchy_top.v  # Top-level integration module
│
├── testbench/                  # Simulation testbenches
│   └── memory_hierarchy_tb.v   # Full system testbench
│
├── docs/                       # Documentation & report
│   ├── report/                 # IEEE report (PDF + source)
│   └── diagrams/               # Architecture block diagrams
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

> 📄 **[IEEE Project Report (PDF)](docs/report/)** ← *(will be uploaded before submission)*

---

## 📅 Submission

- **Phase I Deadline:** November 16, 2026, 11:59 PM (IST)
- **Submission Form:** [Google Form](https://docs.google.com/forms/d/e/1FAIpQLSc6Cx8OrOQLGj_X2ZMkyG5jc8mokq36mGRq2x8jGRNV1sbegA/viewform)
