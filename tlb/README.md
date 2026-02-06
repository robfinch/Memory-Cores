# rfTLB

## Overview
This is a core that attempts to be a generic TLB for a 64-bit virtual address space that may be plugged into any project.

## Features
* 64-bit bus interface to WISHBONE bus.
* 64-bit virtual address space
* 52-bit physical address space
* 8kB / 8MB pages
* parameterized number of entries in TLB
* hardware or software managed
* LRU or random replacement policy
* Low resource usage

## Design
1024 entries fit into an 8kB page, therefore 10 address bits from the virtual address are absorbed for each page table level.
Translations are disabled while the TLB is updated. This allows the use of single ported memory to access the TLB.
The core has a WISHBONE bus interface to access the TLB programmatically.
Since a TLB entry is 128-bits and the bus size is only 64-bits, the TLB entries are accessible in an indirect fashion so that the entire TLB entry may be updated or read in the TLB as a single unit. The TLB entry is set up in a holding register, the entry number and way to update are specified in another register. If bit 31 is set while writing to the entry number register the TLB entry in the holding register is transferred to the TLB.
To read a TLB entry specify the entry number in register 28h with bit 30 set then read the value from the TLBE registers.
Note that for LRU operation the highest way should be used to update an entry in the TLB. LRU operates by shifting data from next higher way into the current way. Data in the lowest way is lost. The second highest way may be used if it is desired to keep the translations in the highest way.

## Registers
|--------|---------|-------------------------------------|
| Number | Name    | Description                         |
|--------|---------|-------------------------------------|
|  00h   | TLBEL   | Low order 64-bits of TLBE (the PTE) |
|  08h   | TLBEH   | High order 64-bits of TLBE          |
|  10h   |         | reserved                            |
|  18h   |         | reserved                            |
|  20h   | ENTRYNO | TLB entry number to read or update  |

* Bits 0 to 15 of the ENTRYNO register specify the entry number
* Bits 16 to 23 specify the way to update
* Bit 30 indicates to read the TLB
* Bit 31 indicates to update the TLB

