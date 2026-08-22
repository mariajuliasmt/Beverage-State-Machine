# Beverage-State-Machine
Final assignment on Digital Logic Design 

This repo tracks the design files and implementation of a Moore Finite State Machine controlling an automated beverage vending machine. This design was developed using Verilog HDL on Quartus II, targeting the **Altera/Intel Cyclone II EP2C35F672C6 FPGA** on the DE2 Development Board.



---

## 📌 Project Overview

The core controller is implemented as a synchronous, active-high reset **Moore FSM**. Machine control logic is decoupled from datapath calculations: the FSM processes high-level status flags to direct transaction timing, while external datapath registers manage beverage prices, credit balances, and display logic.

### State Definitions & Control Flow

| State Name | State ID | FSM Purpose | Primary Conditions & Transition Flags |
| --- | --- | --- | --- |
| **IDLE** | `S0` | Idle state; balance is zero | Waits for `beverage_selected = 1` $\rightarrow$ `SEL` |
| **SEL** | `S1` | Beverage selection registered | Automatic 1-cycle transition $\rightarrow$ `CREDIT` |
| **CREDIT** | `S2` | Accumulating coin inputs | Loops on `enough_credit = 0`; moves to `BEV` when `enough_credit = 1` |
| **BEV** | `S3` | Dispense beverage | Asserts `dispense_enable = 1`; waits for `dispense_done = 1` $\rightarrow$ `CHANGE` |
| **CHANGE** | `S4` | Return remaining balance | Asserts `change_enable = 1`; waits for `change_done = 1` $\rightarrow$ `IDLE` |

---

## 🛠 Top-Level Architecture & Outputs

Because this system is designed strictly as a **Moore Machine**, control outputs depend solely on the active state rather than transient input conditions.

```
                  +-------------------+
  Switches/Coins  |     DATAPATH      |
  --------------> | (Price/Credit/    |
                  |  Change Logic)    |
                  +---------+---------+
                            |
               enough_credit / change_done
                            |
                            v
                  +-------------------+
                  |     MOORE FSM     |
   clock/reset -> |  S0: IDLE         |
                  |  S1: SEL          |
                  |  S2: CREDIT       |
                  |  S3: BEV          | -> dispense_enable
                  |  S4: CHANGE       | -> change_enable
                  +-------------------+

```

### Moore Output Mapping

| State | `dispense_enable` | `change_enable` | Description |
| --- | --- | --- | --- |
| **IDLE / SEL / CREDIT** | `0` | `0` | Controls disabled; machine accepting inputs or transitioning. |
| **BEV** | `1` | `0` | Triggers hardware beverage release mechanism. |
| **CHANGE** | `0` | `1` | Triggers hardware change return mechanism ($Change = Credit - Price$). |

---

## 🔌 Hardware Pin Assignments (DE2 Board)

Targeted to the **Cyclone II EP2C35F672C6** FPGA layout on the Altera DE2 Board:

| Port Name | Port Type | Board Hardware Component | Location Pin |
| --- | --- | --- | --- |
| `clock` | Input | 50 MHz Clock Oscillator | `PIN_N2` |
| `reset` | Input | Active-Low Pushbutton (`KEY0` inverted) | `PIN_G26` |
| `beverage_selected` | Input | Toggle Switch (`SW0`) | `PIN_N25` |
| `enough_credit` | Input | Toggle Switch (`SW1`) | `PIN_N26` |
| `dispense_done` | Input | Toggle Switch (`SW2`) | `PIN_P25` |
| `change_done` | Input | Toggle Switch (`SW3`) | `PIN_AE14` |
| `dispense_enable` | Output | Red LED (`LEDR0`) | `PIN_AE23` |
| `change_enable` | Output | Red LED (`LEDR1`) | `PIN_AF23` |

---

## 🚀 Verification & Simulation

1. Open `STATE_MACHINE.qpf` inside **Quartus II 13.0 SP1**.
2. Run **Analysis & Synthesis** to confirm zero syntax or latch warnings.
3. Load `tb_STATE_MACHINE.v` into **ModelSim-Altera** to verify state machine sequence progression ($S0 \rightarrow S1 \rightarrow S2 \rightarrow S3 \rightarrow S4 \rightarrow S0$).
4. Assign hardware location pins via the **Pin Planner** and compile design to generate `.sof` bitstream for USB-Blaster programming.
