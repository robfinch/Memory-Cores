2022/11/30
# MPMC10 - Multiport Memory Controller
## Overview
The multi-port memory controller provides eight access ports with either small streaming read caches or a 64kB shared read cache to the ddr3 ram. The multi-port memory controller interfaces between the SoC and a MIG controller.
Ports may be customized with parameter settings. Port #5 is setup to handle sprites and is read-only.
## New Features
* Version 10 of the controller supports a larger system cache and the cache now supports write operations. 
* The controller now has an input fifo to queue requests to improve performance.
* All ports are now 128-bit.
* Ports are serviced in a round-robin fashion.
# Cache / Streaming Cache
The cache is a 64kB 4-way associative cache which may be shared between ports. The cache line size is 16 bytes. The cache allows ports to read in parallel but only supports a single write port.
The streaming caches are much smaller read caches. They are useful when the data is generally read and used only once, as for a frame buffer for instance. The streaming caches are an alternative to making the read cache multi-way associative, and effectively add ways to the cache reads.
Streaming caches are typically loaded using large data bursts. They are setup for 64 beat bursts which load 1kB of data. Given the large burst size and small cache size there are only a handful of cache tags required which helps to reduce the footprint.

## Suggested Port Usage

|Port|Use                             |Port Bits|Common  Cache|Stream Buffer|
|----|--------------------------------|---------|-------------|-------------|
| 0  |Frame Buffer / Bitmap Controller|   128   |             |      *      |
| 1  |CPU #1                          |   128   |      *      |             |
| 2  |Ethernet Controller             |   128   |      *      |             |
| 3  |Audio Controller                |   128   |             |      *      |
| 4  |Graphics Accelerator            |   128   |      *      |             |
| 5  |Sprite Controller               |   128   |             |      *      |
| 6  |SD (disk) Controller            |   128   |      *      |             |
| 7  |CPU #2                          |   128   |      *      |             |

## Port Priorities
Ports are serviced in a round robin fashion.

## Clocks
Each port may have it own clock. Clock domain crossing logic is present for incoming and outgoing signals. The controller's clock typically runs at 1/4 the PHY clock or 100MHz. The port clocks may be a different frequency.

## Memory Access
Memory is accessed in strips of 16 bytes which is the size that MIG interface uses. Specifying multiple strips for reading will use a burst of strips which is a much faster way to access memory.

## Address Reservations
The controller supports address reservations on memory for imnplementation of semaphores. The CPU must output address reservation set and clear signals to support this.

## Parameters
STREAMn - cause port number 'n' to use a streaming cache instead of the main cache
NAR     - sets the number of outstanding address reservation that are present, this should be a small number (eg. 2)

2022/10/22
A new version of the core, MPMC10, is in the works. The new version will feature better performance through the use of a input fifo. It is much the same as MPMC9. All ports are 128 bit. Testing with video circuits reveals MPMC10 still has some glitches to work out. Port priorities are now round-robin.

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
