#!/bin/bash

source base_conf.sh

if [ $# -ne 1 ]
then
  echo "$0 filename"
  exit
fi

file=$1
info_file=$file".out"
path="tmpdir"
if [ ! -d "$path"]
then  
  mkdir "$path"  
else
  rm $path"/*" -f
fi  
new_file=$path"/"$file
cp $file $new_file 


for dsize in ${DATA_SIZE_ARR[*]}
do
  # 1. get seg info
  seg_file=$new_file"-payload-"$dsize
  seg_start_pos=`egrep -n -B2 " "$dsize" bytes payload" $new_file| head -1 | awk '{print substr($1, 1, length($1) -1)}'`
  seg_start_pos=$(($seg_start_pos-1))
  echo $seg_start_pos
  seg_lastop_pos=`egrep -n -B2 " "$dsize" bytes payload" $new_file| tail -1 | awk '{print substr($1, 1, length($1) -1)}'`
  echo $seg_lastop_pos
  diff_pos=`sed -n ''$seg_lastop_pos', $p' $new_file | egrep -n "requests per second" | head -1 | awk -F: '{print $1}'`
  echo $diff_pos
  seg_end_pos=`echo $seg_lastop_pos $diff_pos | awk '{printf"%d", $1 + $2}'`
  seg_end_pos=$(($seg_end_pos-1))
  echo $seg_end_pos
  sed -n ''$seg_start_pos', '$seg_end_pos'p' $new_file > $seg_file

  for conn in ${CONN_ARR[*]}
  do
    # 2. classified by parallel 
    conn_file=$seg_file"-"$conn
    conn_start_pos=`egrep -n -B1 " "$conn" parallel clients" $seg_file| head -1 | awk '{print substr($1, 1, length($1) -1)}'`
    conn_start_pos=$(($conn_start_pos - 1))
    echo $conn_start_pos
    conn_lastop_pos=`egrep -n -B1 " "$conn" parallel clients" $seg_file | tail -1 | awk '{print substr($1, 1, length($1) -1)}'`
    echo $conn_lastop_pos
    conn_diff_pos=`sed -n ''$conn_lastop_pos', $p' $seg_file | egrep -n "requests per second" | head -1 | awk -F: '{print $1}'`
    echo $conn_diff_pos
    conn_end_pos=`echo $conn_lastop_pos $conn_diff_pos | awk '{printf"%d", $1 + $2}'`
    conn_end_pos=$(($conn_end_pos - 1))
    echo $conn_end_pos
    sed -n ''$conn_start_pos', '$conn_end_pos'p' $seg_file > $conn_file

    for op_name in ${OP_ARR[*]}
    do
      # 3. get result by opname
      op_file=$conn_file"-"$op_name
      op_start_pos=`egrep -i -n "$op_name" $conn_file | head -1 |  awk -F: '{print $1}'`
      #op_start_pos=$(($op_start_pos - 1))
      if [ -n "$op_start_pos" ]
      then
        op_diff_pos=`sed -n ''$op_start_pos', $p' $conn_file | egrep -n "requests per second" | head -1 | awk -F: '{print $1}'`
        op_end_pos=`echo $op_start_pos $op_diff_pos | awk '{printf"%d", $1 + $2}'`
        op_end_pos=$(($op_end_pos - 1))
        sed -n ''$op_start_pos', '$op_end_pos'p' $conn_file > $op_file

        # 4. cacl
        rt=`grep " requests completed" $op_file | awk '{printf"%.3f", $(NF-1)*1000 / $1}'`
        qps=`grep " requests per second" $op_file | awk '{printf"%d", $1}'`
        print_info=$dsize"\t"$conn"\t"$op_name"\t"$rt"\t"$qps
        per_arr=(99.95 99.99 100)
        for percent in ${per_arr[*]}
        do
          per_rt=`grep "milliseconds" $op_file | awk -F% '{if($1 >= '$percent') {print $2}}' | head -1 | awk '{print $2}'`
          print_info=$print_info"\t"$per_rt
        done
        echo -e $print_info >> $info_file 
      fi
    done
  done
done
