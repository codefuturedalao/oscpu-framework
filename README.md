# oscpu-framework
A Verilator-based framework.

Author : jacksonsang

School : Wuhan university

Project : ysyx (one chip one life)[https://oscpu.github.io/ysyx/wiki/index.html]

goal : “一生一芯” 是一个面向初学者的CPU设计训练项目。

ISA: RV64I

micro-Architecture : five stages pipeline for now

environment : vim + verilator + difftest + nemu + gtkwave

## Timeline:
2021.7.27 : start project

2021.7.31 : single cycle CPU that implement RV64I without csr is done

2021.8.4  : 5 stage pipeline cpu that implement RV64I without csr is done

2021.8.6  : add csr instruction(csrrw[i] csrrs[i] csrrc[i]) and mcycle, not sure whether it is implemented well

2021.8.7  : pass cpu-test except hello-str(lack implementation of sprintf..) and riscv-test

2021.8.10 : use assign instead of always in combinational circuit (in the id and exe module)

2021.8.11 : use booth2 algorithm to implement mul[h/w/su/u] and pass the test

2021.8.12 : implement divide op during multicycle and pass the test

## DOING:
* implement Axi Bus for accessing memory
* optimize cpu by reading *CPU Design can Practive* (author: WenXiang Wang), some instructions' implement needs to be rethinked, e.g. shift
	* memory mask signal generate method				[done]
	* regular the stall request signal and priority 
* add instructions like MUL and DIV using efficient method ( * and / are not what i want lol) use wallace tree to implement multiple op and reuse the adder in exe stage
## TODO:
* add csr instruction and relevant register
* add exception and interrupt handler module (ecall ebreak)
* implement icache and dcache ( didn't make it in NSCSCC, a very challenging work)
* improve cpu's perfomance by switching to other micor-architecture like superscalar, out-of-order, more stages pipeline
* debug with RT-thread
	

