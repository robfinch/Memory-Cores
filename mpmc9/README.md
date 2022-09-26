# MPMC9 - Multiport Memory Controller
## Overview
The multi-port memory controller provides eight access ports with either small streaming read caches or a 16kB shared read cache to the ddr3 ram. The multi-port memory controller interfaces between the SoC and a MIG controller.
Ports may be customized with parameter settings. Port #5 is setup to handle sprites and is read-only.
# Read Cache / Streaming Cache
The read cache is a 16kB direct mapped cache which may be shared between ports. The cache line size is 16 bytes. Note the cache only caches read operations. Writes cause the corresponding cache line to be invalidated to maintain cache coherency. Writes bypass the cache and write directly to memory.
The streaming caches are much smaller read caches. They are useful when the data is generally read and used only once, as for a frame buffer for instance. The streaming caches are an alternative to making the read cache multi-way associative, and effectively add ways to the cache reads.

## Suggested Port Usage

|Port|Use                             |Port Bits|Common  Cache|Stream Buffer|
|----|--------------------------------|---------|-------------|-------------|
| 0  |Frame Buffer / Bitmap Controller|   128   |             |      *      |
| 1  |CPU #1                          |   128   |      *      |             |
| 2  |Ethernet Controller             |    32   |      *      |             |
| 3  |Audio Controller                |    16   |             |      *      |
| 4  |Graphics Accelerator            |   128   |      *      |             |
| 5  |Sprite Controller               |    64   |             |      *      |
| 6  |SD (disk) Controller            |    32   |      *      |             |
| 7  |CPU #2                          |   128   |      *      |             |

## Port Priorities
Port #0 has the highest priority, down to port #7 which has the lowest. Periodically, for a single clock cycle only, the port priorities are inverted. This helps ensure that low prioriy ports are not permanently starved of access.

## Clocks
Each port may have it own clock. Clock domain crossing logic is present for incoming and outgoing signals. The controller's clock typically runs at 1/4 the PHY clock or 100MHz. The port clocks may be a different frequency.

## Memory Access
Memory is accessed in strips of 16 bytes which is the size that MIG interface uses. Specifying multiple strips for reading will use a burst of strips which is a much faster way to access memory.

## Address Reservations
The controller supports address reservations on memory for imnplementation of semaphores. The CPU must output address reservation set and clear signals to support this.

## Parameters
STREAMn - cause port number 'n' to use a streaming cache instead of the main cache
STRIPSn - sets the number of memory strips (16 byte accesses) minus 1 for port 'n' to load consecutively (should be 0 (for 1), 1, 3, 7 (for 8), 63)
CnW     - sets the data width for the port (Note port #7 C7R must also be set)
NAR     - sets the number of outstanding address reservation that are present, this should be a small number (eg. 2)
