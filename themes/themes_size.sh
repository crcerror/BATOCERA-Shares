#!/bin/bash

function md5_per_kb () {

  local name=test-theme-$1
  local size=$1

  ( ulimit -f $size
    wget https://www.github.com/${author}/es-theme-minimal/archive/master.zip -O /dev/shm/${name} 2>/dev/null
    echo $?
    ulimit -f unlimited ) 2>/dev/null

  md5sum /dev/shm/${name}
  stat /dev/shm/${name} | grep Size

}

for author in crcerror fabricecaruso
do
  for i in 10 100 250
  do
    md5_per_kb $i
  done
done
