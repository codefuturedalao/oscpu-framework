// --xuezhen--
//rvcpu-test.cpp
#include <verilated.h>          
#include <verilated_vcd_c.h>    
#include <iostream>
#include <fstream>
#include "Vrvcpu.h"

using namespace std;

static Vrvcpu* top;
static VerilatedVcdC* tfp;
static vluint64_t main_time = 0;
static const vluint64_t sim_time = 8000;

// inst.bin
// inst 0: 1 + zero = reg1 1+0=1
// inst 1: 2 + zero = reg1 2+0=2
// inst 2: 1 + reg1 = reg1 1+2=3
long long int inst_rom[65536];

void read_inst( char* filename)
{
  FILE *fp = fopen(filename, "rb");
  if( fp == NULL ) {
		printf( "Can not open this file!\n" );
		exit(1);
  }
  
  fseek(fp, 0, SEEK_END);
  size_t size = ftell(fp);
  fseek(fp, 0, SEEK_SET);
  size = fread(inst_rom, size, 1, fp);
  fclose(fp);
}

int main(int argc, char **argv)
{
	char filename[100];
	printf("Please enter your filename~\n");
	cin >> filename;
	read_inst(filename);

  // initialization
  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(true);

	top = new Vrvcpu;
  	tfp = new VerilatedVcdC;

  	top->trace(tfp, 99);
  	tfp->open("top.vcd");
	
	while( !Verilated::gotFinish() && main_time < sim_time )
	{
	  if( main_time % 10 == 0 ) top->clk = 0;
	  if( main_time % 10 == 5 ) top->clk = 1;
		  
	  if( main_time < 10 )
	  {
		top->rst = 1;
	  }
	  else
	  {
	    top->rst = 0;
		top->inst_rdata = (top->inst_ena == 1) ? inst_rom[top->inst_addr] : 0;
	 	top->mem_rdata = (top->mem_rena == 1) ? inst_rom[top->mem_raddr] : 0;
		if( main_time % 10 == 5 ) {
			long long int mask = 0xff;
			long long int sum = 0;
			for(int i = 0; i < 8; i++) {
				if((top->mem_wmask & mask) == mask) {
					sum += top->mem_wdata & mask;
				}
				mask = mask << 8;
			}
			if(top->mem_wena == 1) {
				inst_rom[top->mem_waddr] = sum;
			}
		}
	  }
	  top->eval();
	  tfp->dump(main_time);
	  main_time++;
	}
		
  // clean
  tfp->close();
  delete top;
  delete tfp;
  exit(0);
  return 0;
}
