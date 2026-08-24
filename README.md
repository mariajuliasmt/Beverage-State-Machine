# Beverage-State-Machine
Final assignment on Digital Logic Design 

This repo tracks the design files and implementation of a Moore Finite State Machine controlling an automated beverage vending machine. This design was developed using Verilog HDL on Quartus II, targeting the **Altera/Intel Cyclone II EP2C35F672C6 FPGA** on the DE2 Development Board.

---

### Project Overview

The core controller is implemented as a synchronous state machine featuring an asynchronous active-high reset. Machine control logic is decoupled from datapath calculations: the FSM processes high-level status flags to direct transaction timing, while external datapath registers manage beverage prices, credit balances, and display logic.

### State Definitions & Control Flow

| State Name | State ID | FSM Purpose | Primary Conditions & Transition Flags |
| --- | --- | --- | --- |
| **IDLE** | `S0` | Idle state; balance is zero | Waits for `beverage_selected = 1` $\rightarrow$ `SEL` |
| **SEL** | `S1` | Beverage selection registered | Automatic 1-cycle transition $\rightarrow$ `CREDIT` |
| **CREDIT** | `S2` | Accumulating coin inputs | Loops on `enough_credit = 0`; moves to `BEV` when `enough_credit = 1` |
| **BEV** | `S3` | Dispense beverage | Asserts `dispense_enable = 1`; waits for `dispense_done = 1` $\rightarrow$ `CHANGE` |
| **CHANGE** | `S4` | Return remaining balance | Asserts `change_enable = 1`; waits for `change_done = 1` $\rightarrow$ `IDLE` |


---


### State Transitions

The FSM evaluates conditions on every clock cycle to either transition between states or maintain its current state:

```
                    beverage_selected = 1
             ┌─────────────────────────────────┐
             │                                 ▼
          ┌──────┐                         ┌──────┐
          │ IDLE │ ──────────────────────> │ SEL  │
          │  S0  │  beverage_selected = 0  │  S1  │
          └──▲───┘                         └──┬───┘
             │                                │
             │                                │ unconditional (1 cycle)
             │                                ▼
             │                            ┌────────┐
             │                            │ CREDIT │ ◄───┐
             │                            │   S2   │ ────┘
             │                            └───┬────┘  enough_credit = 0
             │                                │
             │                                │ enough_credit = 1
             │                                ▼
             │                            ┌────────┐
             │                            │  BEV   │ ◄───┐
             │                            │   S3   │ ────┘
             │                            └───┬────┘  dispense_done = 0
             │                                │
             │                                │ dispense_done = 1
             │                                ▼
             │                            ┌────────┐
             │                            │ CHANGE │ ◄───┐
             └─────────────────────────── │   S4   │ ────┘
                   change_done = 1        └────────┘  change_done = 0

```
Given this design uses D Flip-Flops, its Excitation Table is based off of DFF Excitation Table where $Q_2^+ Q_1^+ Q_0^+$  = $D_2 D_1 D_0$. I enconded `fstate` as $Q_2 Q_1 Q_0$ and $I_0$, $I_1$, $I_2$ and $I_3$ as `beverage_selected`, `enough_credit`, `dispense_done` and `change_done`, respectivelly.

#### D Flip Flop Excitation Table 

| Current State $Q(t)$ | Next State $Q(t+1)$ | Required Input $D$ |
| :---: | :---: | :---: |
| `0` | `0` | `0` |
| `0` | `1` | `1` |
| `1` | `0` | `0` |
| `1` | `1` | `1` |

#### Beverage FSM Excitation Table
| Current State ($Q_2 Q_1 Q_0$) | Condition / Flag | Next State ($Q_2^+ Q_1^+ Q_0^+$) | Required D Flip-Flop Inputs ($D_2 D_1 D_0$) |
| :---: | :--- | :---: | :---: |
| **S0** (`000`) | `beverage_selected == 0` | `000` | `000` |
| **S0** (`000`) | `beverage_selected == 1` | `001` | `001` |
| **S1** (`001`) | *Unconditional* | `010` | `010` |
| **S2** (`010`) | `enough_credit == 0` | `010` | `010` |
| **S2** (`010`) | `enough_credit == 1` | `011` | `011` |
| **S3** (`011`) | `dispense_done == 0` | `011` | `011` |
| **S3** (`011`) | `dispense_done == 1` | `100` | `100` |
| **S4** (`100`) | `change_done == 0` | `100` | `100` |
| **S4** (`100`) | `change_done == 1` | `000` | `000` |

---

#### Detailed Transition Table

| Source State | Destination State | Condition (Verilog Expression) | Description |
| --- | --- | --- | --- |
| **IDLE (`S0`)** | **IDLE (`S0`)** | `beverage_selected == 1'b0` | System stays in standby until a beverage is chosen. |
| **IDLE (`S0`)** | **SEL (`S1`)** | `beverage_selected == 1'b1` | User selects a drink, advancing the machine to register selection. |
| **SEL (`S1`)** | **CREDIT (`S2`)** | *Unconditional* (`OTHERS`) | Advances automatically after 1 clock cycle to collect money. |
| **CREDIT (`S2`)** | **CREDIT (`S2`)** | `enough_credit == 1'b0` | Remains in payment loop while total balance is under drink price. |
| **CREDIT (`S2`)** | **BEV (`S3`)** | `enough_credit == 1'b1` | Payment met ($Credit \ge Price$); advances to dispense drink. |
| **BEV (`S3`)** | **BEV (`S3`)** | `dispense_done == 1'b0` | Holds dispense signal high while beverage hardware is active. |
| **BEV (`S3`)** | **CHANGE (`S4`)** | `dispense_done == 1'b1` | Beverage released; advances to handle remaining change. |
| **CHANGE (`S4`)** | **CHANGE (`S4`)** | `change_done == 1'b0` | Holds change release enable while return mechanism is active. |
| **CHANGE (`S4`)** | **IDLE (`S0`)** | `change_done == 1'b1` | Transaction finished; resets state machine back to start. |
| **ANY STATE** | **IDLE (`S0`)** | `reset == 1'b1` *(Async)* | Immediate return to standby state on asynchronous reset edge. |

---

### State Memory & Flip-Flop Overview

The FSM utilizes physical D Flip-Flops (DFFs) inside the FPGA logic elements to store the current state (`fstate`). This design uses a 3-bit register (`reg [2:0] fstate`), allocating **3 D Flip-Flops** to hold state bits.
Each state is assigned a unique numerical value using `parameter` definitions:

* `IDLE` = `3'b000` (`0`)
* `SEL` = `3'b001` (`1`)
* `CREDIT` = `3'b010` (`2`)
* `BEV` = `3'b011` (`3`)
* `CHANGE` = `3'b100` (`4`)

The asynchronous clear (`clr`) pin on each DFF connects directly to the global `reset` line, instantly forcing all flip-flops to zero (`IDLE`) on a reset event without waiting for a clock edge.

---

### How the FSM Code Blocks Work

The Verilog implementation strictly divides the Moore machine into two distinct processing blocks:

#### 1. Sequential Logic Block (State Register)

This block represents the physical hardware memory, DFFs, given it updates the stored state on the rising edge of the system clock or responds immediately to an asynchronous reset. It holds the system's current state (`fstate`) using non-blocking assignments (`<=`) to ensure clean, synchronous state updates every 20 ns (50 MHz).


```verilog
always @(posedge clock or posedge reset) begin
    if (reset) begin
        fstate <= IDLE;        // Immediate hardware reset
    end else begin
        fstate <= reg_fstate;  // Load next state on clock edge
    end
end

```

#### 2. Combinational Logic Block (Next-State & Output Logic)

This block acts as the decision engine as it evaluates the current state (`fstate`) alongside input flags to calculate both the next state (`reg_fstate`) and control outputs (`dispense_enable`, `change_enable`). It reacts instantly to any change in `fstate` or input signals. To ensure latch prevention, it assigns default values at the top of the block in order to explicitly define all output/next-state paths. Due to its Moore nature, control signals (`dispense_enable`, `change_enable`) are driven only by the active `fstate` branch, guaranteeing cleaner control outputs to hardware components.


```verilog
always @(fstate or beverage_selected or enough_credit or dispense_done or change_done) begin
    // Default output assignments (prevents latches)
    dispense_enable <= 1'b0;
    change_enable   <= 1'b0;
    
    case (fstate)
        IDLE: begin
            if (beverage_selected) reg_fstate <= SEL;
            else reg_fstate <= IDLE;
        end
        // Additional state evaluations...
    endcase
end

```

---

## Architecture & Outputs

As this system is designed strictly as a **Moore Machine**, control outputs depend solely on the active state rather than transient input conditions.

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
   clock -------->|  S0: IDLE         |
   async reset -->|  S1: SEL          |
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

### Hardware Pin Assignments (DE2 Board)

Targeted to the **Cyclone II EP2C35F672C6** FPGA layout on the Altera DE2 Board:

| Port Name | Port Type | Board Hardware Component | Location Pin | Notes |
| --- | --- | --- | --- | --- |
| `clock` | Input | 50 MHz Clock Oscillator | `PIN_N2` | Master system clock |
| `reset` | Input | Active-Low Pushbutton (`KEY0`) | `PIN_G26` | Inverted in top-level for async active-high reset |
| `beverage_selected` | Input | Toggle Switch (`SW0`) | `PIN_N25` | User beverage selection flag |
| `enough_credit` | Input | Toggle Switch (`SW1`) | `PIN_N26` | Credit condition check ($Credit \ge Price$) |
| `dispense_done` | Input | Toggle Switch (`SW2`) | `PIN_P25` | Beverage mechanism completion signal |
| `change_done` | Input | Toggle Switch (`SW3`) | `PIN_AE14` | Change release completion signal |
| `dispense_enable` | Output | Red LED (`LEDR0`) | `PIN_AE23` | High during `BEV` (`S3`) state |
| `change_enable` | Output | Red LED (`LEDR1`) | `PIN_AF23` | High during `CHANGE` (`S4`) state |

---

##  Verification & Simulation

1. Open `STATE_MACHINE.qpf` inside **Quartus II 13.0 SP1**.
2. Run **Analysis & Synthesis** to confirm zero syntax or latch warnings.
3. Load `tb_STATE_MACHINE.v` into **ModelSim-Altera** to verify state machine sequence progression ($S0 \rightarrow S1 \rightarrow S2 \rightarrow S3 \rightarrow S4 \rightarrow S0$) and test asynchronous reset behavior at arbitrary clock times.
4. Assign hardware location pins via the **Pin Planner** and compile design to generate `.sof` bitstream for USB-Blaster programming.
5. Run simulation on University Program VWF file to verify this program without hardware
