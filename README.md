# oscpu-framework
A Verilator-based framework.
Author : jacksonsang
School : Wuhan university
Project : ysyx(one chip one life)[https://oscpu.github.io/ysyx/wiki/index.html]
goal : “一生一芯” 是一个面向初学者的CPU设计训练项目。
ISA: RV64I
micro-Architecture : five stages pipeline for now
deploy environment : vim + verilator + difftest + nemu + gtkwave

Timeline:
2021.7.27 : start project
2021.7.31 : single cycle CPU that implement RV64I without csr is done
2021.8.4  : 5 stage pipeline cpu that implement RV64I without csr is done
2021.8.6  : add csr instruction(csrrw[i] csrrs[i] csrrc[i]) and mcycle, not sure whether it is implemented well

DOING:
	* add self-defined instruction to fit abstract-machine and run some software
	* implement Axi Bus for accessing memory
TODO:
	* add csr instruction and relevant register
	* add exception and interrupt handler module (ecall ebreak)
	* implement icache and dcache ( didn't make it in NSCSCC, a very challenging work)
	* optimize cpu by reading *CPU Design can Practive* (author: WenXiang Wang), some instructions' implement needs to be rethinked, e.g. shift
	* add instructions like MUL and DIV using efficient method ( * and / are not what i want lol)
	* improve cpu's perfomance by switching to other micor-architecture like superscalar, out-of-order, more stages pipeline
	* debug with RT-thread
	

