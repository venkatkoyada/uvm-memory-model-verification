# UVM Testbench for a Memory Model with CSRs

UVM 1.2 testbench in SystemVerilog for a small synchronous memory (16 x 32-bit) with
control and status registers. Simulated with Synopsys VCS.

```
rtl/        memory_rtl.sv - design under test
UVM_TB/     UVM testbench, assertions, Makefile, regression script
doc/        results of the last passing regression (logs, coverage reports)
```

## Design under test

`rtl/memory_rtl.sv` - 16 word memory, 8-bit address, 32-bit data, synchronous read and write,
asynchronous reset. Read data comes out one clock after the read.

| Address | Register        | Access | Description                                         |
|---------|-----------------|--------|-----------------------------------------------------|
| 0x00-0x0F | memory        | RW     | 16 words of 32 bits                                 |
| 0x18    | csr1_wr_count   | RO     | [15:0] number of writes, [31:16] number of reads     |
| 0x20    | csr2_CHIP_EN    | RW     | bit 0 = 1 turns the memory on (8-bit register)      |
| 0x24    | csr3            | RW     | spare register                                      |
| 0x26    | csr4_dropped    | RO     | number of dropped writes                            |

- When chip enable bit 0 is 0, writes to memory are dropped and `rdata` is high-Z.
- Writes to an unmapped address or to a read only register are dropped.
- `response` is 1 for one cycle after a good memory write.

## Testbench

```
            +------------------- environment -------------------+
            |                                                   |
 sequences ->  master_agent                                     |
            |   sequencer -> driver ----> DUT ----> oMonitor     |
            |                 iMonitor      |      (slave_agent)|
            |                    |          |           |       |
            |                    v          |           v       |
            |   coverage <--  scoreboard (reference model)      |
            +---------------------------------------------------+
                        mem_sva bound to the DUT
```

- **driver** - every item takes whole clock cycles, so reads and writes can go back to back.
  Supports READ, WRITE, CSR_READ (returns the data to the sequence), RESET and
  STIMULUS (write + read to the same address).
- **iMonitor** - samples the DUT inputs every clock and sends reset, read and write packets.
- **oMonitor** - samples `rdata` and `response` one clock after each read/write.
- **scoreboard** - reference model of the memory, all CSRs and the counters. Predicts
  every read value (including high-Z when the chip is off) and every write response.
- **coverage** - address map, read/write, chip on/off, CSR access, back to back
  combinations (WR->WR, WR->RD, RD->WR, RD->RD) and data corners.
- **mem_sva** - assertions bound to the DUT: rdata is Z when idle or chip off, rdata
  known after a read, response only after a good write, reset values, no wr+rd together.

## Tests

| Test                | What it does                                                            |
|---------------------|-------------------------------------------------------------------------|
| new_test            | write then read to random addresses                                     |
| csr_test            | all CSRs: reset values, RW patterns, RO writes, counters, chip on/off  |
| chip_disable_test   | memory access with chip disabled, then enabled again                   |
| b2b_test            | 1000 random back to back reads/writes + same address write->read       |
| illegal_addr_test   | unmapped and read only addresses mixed with normal traffic             |
| reset_test          | reset in the middle of traffic, checks everything goes back to 0       |

Every test also runs reset, configure (chip enable) and shutdown (read status registers)
phases.

## Bugs found in the original RTL

The fixes are in `rtl/memory_rtl.sv` under `` `ifndef ORIGINAL_RTL ``. Compile with
`DEFINES=+define+ORIGINAL_RTL` to get the original design back and see the failures.

1. **Stale read data on unmapped address** - reading an address that is not memory or a
   CSR left the old `data_out` on `rdata` (the last read value, or X if nothing was read yet).
   Found by `illegal_addr_test` (scoreboard mismatch, and the `RDATA_KNOWN` assertion
   when the old value is X).
   Fix: return 0 for unmapped addresses.
2. **Wrong write response on back to back writes** - `response` was only set to 0 in
   cycles without a write. A dropped write or CSR write right after a good write still
   showed `response=1`. Found by `illegal_addr_test` (scoreboard and the
   `RESP_ONLY_GOOD_WRITE` assertion). Fix: clear `response` at the start of every write.
3. **Spec comment did not match the RTL** - the comment said the write/read counters
   are 8 bits each in csr1, but the RTL uses 16 bits each. Comment updated.

Testbench issues fixed from the first version:
- Driver read the CSR data one clock too early (got Z instead of the register value).
- Monitors waited for a *change* on wdata/rdata, so two writes with the same data were
  missed (that is why the old packet had `data != prev_data`). Now they sample every clock.
- `mvif.tb` (modport selected from a virtual interface handle) is not standard SystemVerilog
  (VCS accepts it, stricter tools do not); the handle is now passed directly.
- No `timescale` anywhere, now set with `-timescale=1ns/1ps`.

## How to run

All commands are run from the `UVM_TB` folder:

```
cd UVM_TB
make all                          # everything: clean, compile, all tests, coverage report, opens it
make all SEEDS="1 2 3 4 5"         # same with more seeds
make all UVM_VERBOSITY=UVM_HIGH   # also print every driver/monitor/scoreboard message
make all QUIET=1                  # only the pass/fail table, output still saved in logs/regress/
make sim                          # compile + run new_test
make sim TEST=csr_test SEED=3     # any test, any seed
make regress                      # all tests with seeds 1 2 3
make cov                          # merged coverage report in urgReport/
make regress DEFINES=+define+ORIGINAL_RTL    # original RTL, bug tests should fail
make wave TEST=csr_test           # run one test and open the waveform in Verdi
```

A test passes when it prints `TEST PASSED` and the UVM summary has no UVM_ERROR or UVM_FATAL.

## Coverage report

`make all` does all of this in one go. Step by step it is:

```
make clean
make regress          # every run is saved in simv.vdb
make cov              # merges all runs -> urgReport/ (HTML + text)
make cov_view         # opens urgReport/dashboard.html in firefox
make cov_gui          # same database in Verdi coverage view
```

Pages in `urgReport/`:

| Page             | What it shows                                                               |
|------------------|-----------------------------------------------------------------------------|
| dashboard.html   | total score and the score for each coverage type                            |
| hierarchy.html   | code coverage per instance. Click `dut_inst` to see line, condition, branch and toggle coverage with the source code, missed lines are highlighted |
| groups.html      | functional coverage. Click `cov_mem` -> each coverpoint and cross -> every bin with its hit count |
| asserts.html     | each assertion: how many times it passed / failed, and the cover properties |
| tests.html       | list of the test runs that were merged                                      |

Code coverage is collected only for `top.dut_inst` and `top.mem_if` (`cov_hier.cfg`),
so the testbench code does not change the numbers.
Toggle coverage will not reach 100% because the high bits of the counters
(`csr4_dropped`, `wr_count`, `rd_count`) never toggle in a short test.

Run `make clean` before switching between the fixed and `ORIGINAL_RTL` builds,
otherwise both sets of runs get merged in the same report.

## Results

VCS V-2023.12-SP2, `make all` (6 tests x 3 seeds = 18 runs):

| Metric                         | Result |
|--------------------------------|--------|
| Tests passing                  | 18 / 18 |
| Functional coverage (merged)   | 100%   |
| Line / condition / branch      | 100% / 100% / 100% |
| Toggle                         | 80.3% (high counter bits never toggle) |
| Assertions (mem_sva)           | 100% - 8 assertions pass, 4 cover properties hit |

The total ASSERT number in the URG dashboard is lower (86.67%) because it also counts
a few assertions inside the UVM library (`uvm_pkg` row), which normal tests never hit.
The `top` row shows 100% for the design and `mem_sva`.

With `DEFINES=+define+ORIGINAL_RTL`, `illegal_addr_test` fails on all seeds and the
other 5 tests pass.

## doc folder

`make all` copies the results here when all tests pass on the fixed RTL
(you can also run `make save` yourself):

- `doc/logs/` - compile log, one log per test and seed, `summary.txt` (pass/fail table)
- `doc/coverage_reports/` - URG text reports (`dashboard.txt`, `groups.txt`, `hierarchy.txt`, ...)
