while getopts a: flag
do
    case "${flag}" in
        a) obj=${OPTARG};;
    esac
done
riscv64-linux-gnu-gcc -c $obj.s -o $obj
riscv64-linux-gnu-objcopy -O binary $obj $obj.bin
rm $obj
