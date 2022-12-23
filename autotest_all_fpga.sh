
#!/bin/sh
set -e
prefix='/opt/riscv'
rpath=$prefix/bin/
testcase=./testcase/fpga

# clearing test dir
rm -rf ./test
mkdir ./test
# compiling rom
${rpath}riscv32-unknown-elf-as -o ./sys/rom.o -march=rv32i ./sys/rom.s

for i in ${testcase}/*.c; do
  [ -f "$i" ] || break
  # echo ${i}
  filename="${i##*/}"
  filename="${filename%.*}"
  # check if this testcase already exists in test_result
  if grep -Fq "${filename}" test_result
  then
    echo "${filename} skipped"
    continue
  else
    echo "${filename}"
  fi

  echo -n "${filename} " >>test_result

  # compiling testcase
  cp "${i}" ./test/test.c
  if [ -f ${testcase}/${filename}.in ]; then cp ${testcase}/${filename}.in ./test/test.in; fi
  if [ -f ${testcase}/${filename}.ans ]; then cp ${testcase}/${filename}.ans ./test/test.ans; fi
  ${rpath}riscv32-unknown-elf-gcc -o ./test/test.o -I ./sys -c ./test/test.c -O2 -march=rv32i -mabi=ilp32 -Wall
  # linking
  ${rpath}riscv32-unknown-elf-ld -T ./sys/memory.ld ./sys/rom.o ./test/test.o -L $prefix/riscv32-unknown-elf/lib/ -L $prefix/lib/gcc/riscv32-unknown-elf/10.1.0/ -lc -lgcc -lm -lnosys -o ./test/test.om
  # converting to verilog format
  ${rpath}riscv32-unknown-elf-objcopy -O verilog ./test/test.om ./test/test.data
  # converting to binary format(for ram uploading)
  ${rpath}riscv32-unknown-elf-objcopy -O binary ./test/test.om ./test/test.bin
  # decompile (for debugging)
  # ${rpath}riscv32-unknown-elf-objdump -D ./test/test.om > ./test/test.dump

  # run (disable stdout buffering)
  stdbuf -o0 ./fpga/run.sh ./test/test.bin ./test/test.in /dev/ttyUSB1 -T >./test/test.out 2>>test_result
  if [ -f ${testcase}/${filename}.ans ]; then diff ./test/test.out ./test/test.ans; fi
done
