#! /bin/bash
#
cp test_lls.h ./include
#
gcc -c -Wall -I ./include test_lls.c
if [ $? -ne 0 ]; then
  echo "Compile error."
  exit
fi
#
mv test_lls.o ./libc/test_lls.o
#
echo "Normal end of execution."
