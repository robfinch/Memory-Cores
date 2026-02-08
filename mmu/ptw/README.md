# Page Table Walker - PTW
## Overview
This core is basically a big state machine that drives the TLB core.
It encapsulates the TLB core including a second optional TLB for shortcut pages.
## Features
* Automatic walking of page tables and update of TLB.
* Support for shortcut pages
* Ability to flush the entire TLB
* Ability to flush TLB according to ASID
* Automatic flushing of evicted TLB entries
* Page fault generation
* Multiple levels of pages tables (currently only two supported).
## Operation
The page walker (PTW) machine sits in the idle state waiting for a TLB miss to occur.
It then process the miss, looking up translations from the page tables.
The TLB(s) is updated with needed translations.
Paging is disabled while the TLB is being updated.
