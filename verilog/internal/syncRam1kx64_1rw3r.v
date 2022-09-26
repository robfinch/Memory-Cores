// ============================================================================
// (C) 2012 Robert Finch
// All Rights Reserved.
// robfinch@<remove>@sympatico.ca
//
//	syncRam1kx64_1rw3r.v
//
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Lesser General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or     
// (at your option) any later version.                                      
//                                                                          
// This source file is distributed in the hope that it will be useful,      
// but WITHOUT ANY WARRANTY; without even the implied warranty of           
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            
// GNU General Public License for more details.                             
//                                                                          
// You should have received a copy of the GNU General Public License        
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    
//                                                                          
// ============================================================================
//
module syncRam1kx64_1rw3r(
	input wrst,
	input wclk,
	input wce,
	input we,
	input [9:0] wadr,
	input [63:0] i,
	output [63:0] wo,

	input rrsta,
	input rclka,
	input rcea,
	input [9:0] radra,
	output [63:0] roa,

	input rrstb,
	input rclkb,
	input rceb,
	input [9:0] radrb,
	output [63:0] rob,

	input rrstc,
	input rclkc,
	input rcec,
	input [9:0] radrc,
	output [63:0] roc
);

syncRam1kx64_1rw1r u1
(
	.wrst(wrst),
	.wclk(wclk),
	.wce(wce),
	.we(we),
	.wadr(wadr),
	.i(i[63:0]),
	.wo(wo[63:0]),
	.rrst(rrsta),
	.rclk(rclka),
	.rce(rcea),
	.radr(radra),
	.ro(roa[63:0])
);

syncRam1kx64_1rw1r u2
(
	.wrst(wrst),
	.wclk(wclk),
	.wce(wce),
	.we(we),
	.wadr(wadr),
	.i(i[63:0]),
	.wo(),
	.rrst(rrstb),
	.rclk(rclkb),
	.rce(rceb),
	.radr(radrb),
	.ro(rob[63:0])
);

syncRam1kx64_1rw1r u3
(
	.wrst(wrst),
	.wclk(wclk),
	.wce(wce),
	.we(we),
	.wadr(wadr),
	.i(i[63:0]),
	.wo(),
	.rrst(rrstc),
	.rclk(rclkc),
	.rce(rcec),
	.radr(radrc),
	.ro(roc[63:0])
);

endmodule
