# MPMC11 - Multiport Memory Controller
## Overview
The multi-port memory controller provides eight access ports with either small streaming read fifos or a 64kB shared read cache to the ddr3 ram. The multi-port memory controller interfaces between the SoC and a MIG controller.
Ports may be customized with parameter settings. Port #5 is setup to handle sprites and is read-only.
## New Features
* Version 11 of the controller supports a larger system cache and the cache now supports write operations. 
* The controller now has an input fifo on each channel to queue requests to improve performance.
* All ports are now 256-bit.
* Ports are serviced in a round-robin fashion. The last serviced port has the lowest priority.
## Experimental Features
The following has not been tested yet, but code is in place.
The controller has logic to support atomic memory updates; given the appropriate command it may for instance perform an atomic add operation. Supported atomic operations include, add, and, or, eor, swap, min, max, shift left, shift right and cas.
# Cache / Streaming Fifo
The cache is a 64kB 4-way associative cache which may be shared between ports. The cache line size is 32 bytes. The cache allows ports to read in parallel but only supports a single write port.
The streaming fifos are useful when the data is generally read and used only once, as for a frame buffer for instance. The streaming fifos are an alternative to making the read cache multi-way associative, and effectively add ways to the cache reads. Since the cache is much smaller than a video frame buffer, the cache would become polluted with video data that is used only once per frame. The streaming read fifos prevent this pollution of the cache.
Streaming fifos are typically loaded using large data bursts. They are setup for 32 beat bursts which load 1kB of data.

## Suggested Port Usage
Only the ports specified by the PORT_PRESENT parameter will be implemented. The PORT_PRESENT parameter has a bit corresponding to each port to make available. The default value is 8'hFF.

|Port|Use                             |Port Bits|Common  Cache|Stream Fifo|
|----|--------------------------------|---------|-------------|-----------|
| 0  |Frame Buffer / Bitmap Controller|   256   |             |     *     |
| 1  |CPU #1                          |   256   |      *      |           |
| 2  |Ethernet Controller             |   256   |      *      |           |
| 3  |Audio Controller                |   256   |             |     *     |
| 4  |Graphics Accelerator            |   256   |      *      |           |
| 5  |Sprite Controller               |   256   |             |     *     |
| 6  |SD (disk) Controller            |   256   |      *      |           |
| 7  |CPU #2                          |   256   |      *      |           |

## Port Priorities
Ports are serviced in a round robin fashion.

## Clocks
Each port may have it own clock. Clock domain crossing logic is present for incoming and outgoing signals. The controller's clock typically runs at 1/4 the PHY clock or 100MHz. The port clocks may be a different frequency.

## Memory Access
Memory is accessed in strips of 32 bytes which is the size that MIG interface uses when RAM is 32-bits wide. Specifying multiple strips for reading will use a burst of strips which is a much faster way to access memory.

## Address Reservations
The controller supports address reservations on memory for imnplementation of semaphores. The CPU must output address reservation set and clear signals to support this.

## Parameters
PORT_PRESENT	- specifies which ports are to be implemented, default value 8'hFF for all ports.
STREAMn - cause port number 'n' to use a streaming fifo instead of the main cache
NAR     - sets the number of outstanding address reservation that are present, this should be a small number (eg. 2)
