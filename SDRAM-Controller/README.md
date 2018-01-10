# SDRAM-Controller
SRAM Controller that interfaces with AHB-lite and a 128MB SDRAM chip. For a high-level overview of the design, please visit the [diagrams](https://github.com/gcwill70/Hardware-Design/tree/master/SDRAM-Controller/Diagrams) page and select the component of interest.

## Environment
The actual SDRAM chip is the [ISSI IS42S16320D](http://www.issi.com/WW/pdf/42-45R-S_86400D-16320D-32160D.pdf). Each chip is 64 MB and takes in 16 bits of data. Two chips are used in parallel for a total of 128MB with 32-bit words stored at each address.

## Features
* Interfaces with the standard [AHB-lite protocol](http://mazsola.iit.uni-miskolc.hu/~drdani/docs_arm/IHI0033A_AMBA3_AHB_Lite.pdf) and the SDRAM chip bus.
* Supports single-word and four-word transactions.
* The AHB Master can select a default burst length (one or four) by controlling the first bit in h_burst when h_sel goes high (h_burst is 3 bits wide but only one bit is needed to select the default burst length). If the first bit in h_burst is a 0 on the rising edge of h_sel, then the default burst length is 1. Otherwise, the default burst length is 4 words. 
	* Example: if the SoC master selects the SDRAM Controller while h_burst[0] is 1, the default burst length is 4. If the SoC master then requests a single-word transaction, the following events will occur:
		1. The chip will be reprogrammed to a single-word mode
		2. The transaction will be carried out as normal
		3. The chip will be programmed back to its default burst length.
		4. The chip will then be ready for another transaction.
