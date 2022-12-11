prefix = $(shell pwd)
# Folder Path
src = $(prefix)/src
testspace = $(prefix)/testspace

sim_testcase = $(prefix)/testcase/sim
fpga_testcase = $(prefix)/testcase/fpga

sim = $(prefix)/sim
riscv_toolchain = /home/qweryy/toolchain/riscv
riscv_bin = $(riscv_toolchain)/bin
sys = $(prefix)/sys

name = sample

# _no_testcase_name_check:
# 	@$(if $(strip $(name)),, echo 'Missing Testcase Name')
# 	@$(if $(strip $(name)),, exit 1)

# All build result are put at testspace

test_sim: build_sim build_sim_test run_sim

build_sim:
	@cd $(src) && iverilog -o $(testspace)/test $(sim)/testbench.v $(src)/common/block_ram/*.v $(src)/common/fifo/*.v $(src)/common/uart/*.v $(src)/*.v

build_sim_test: # _no_testcase_name_check
	@echo "Build Testcase: $(name)"
	@$(riscv_bin)/riscv32-unknown-elf-as -o $(sys)/rom.o -march=rv32i $(sys)/rom.s
	@echo "Build Testcase: $(name)"
	@cp $(sim_testcase)/*$(name)*.c $(testspace)/test.c
	@echo "Build Testcase: $(name)"
	@$(riscv_bin)/riscv32-unknown-elf-gcc -o $(testspace)/test.o -I $(sys) -c $(testspace)/test.c -O2 -march=rv32i -mabi=ilp32 -Wall
	@$(riscv_bin)/riscv32-unknown-elf-ld -T $(sys)/memory.ld $(sys)/rom.o $(testspace)/test.o -L $(riscv_toolchain)/riscv32-unknown-elf/lib/ -L $(riscv_toolchain)/lib/gcc/riscv32-unknown-elf/10.1.0/ -lc -lgcc -lm -lnosys -o $(testspace)/test.om
	@$(riscv_bin)/riscv32-unknown-elf-objcopy -O verilog $(testspace)/test.om $(testspace)/test.data
	@$(riscv_bin)/riscv32-unknown-elf-objdump -D $(testspace)/test.om > $(testspace)/test.dump

run_sim:
	@cd $(testspace) && ./test

clear:
	@rm $(sys)/rom.o $(testspace)/test*

.PHONY: _no_testcase_name_check build_sim build_sim_test run_sim clear test_sim