#!/bin/bash
source base_conf.sh

#$1 current op name
check_and_clear()
{
  op_name=$1
  if [[ "${CHECK_OP_ARR[@]}" =~ $op_name ]] 
  then
    info_cmd="$REDIS_CLI -h $HOST -p $PORT -a $AUTH -i 1 info"
    echo $info_cmd
    echo "`$info_cmd`" &> tmp
    used_memory=`cat tmp | awk -F: '/^used_memory_human/ {print substr($NF, 0, length($NF) - 4)}'`
    echo $used_memory
    if [ $used_memory -gt $MAX_MEM ]
    then
      clear_cmd="$REDIS_CLI -h $HOST -p $PORT -a $AUTH flushall"
      echo $clear_cmd
      echo "`$clear_cmd`" >> clear_file
    fi
  fi
}

calc_runnums()
{
  per_size=$1
  rnums=`echo $MAX_QUOTA $per_size $MAX_RUN_NUMS | awk '{if($1/$2<$3) {printf"%d",$1/$2} else {printf"%d",$3}}'`
  echo $rnums
}

rm $RET_FILE -f
rm tmp -f
rm clear_file -f

for dsize in ${DATA_SIZE_ARR[*]}
do
  if [ $dsize -eq 104857600 ]
  then
    conn=1
    run_nums=10
    item_nums=10
    for op_name in ${OP_ARR[*]}
    do
      check_and_clear $op_name
      cmd="$REDIS_BENCHMARK -h $HOST -p $PORT -a $AUTH -t $op_name -c $conn -d $dsize -n $run_nums -r $item_nums"
      echo $cmd
      echo "`$cmd`" >> $RET_FILE
    done
  else
    for conn in ${CONN_ARR[*]}
    do
      if [ $dsize -eq 10485760 ] && [ $conn -eq 100 ]
      then
        echo "skip"
      else
        for op_name in ${OP_ARR[*]}
        do
          check_and_clear $op_name
          run_nums=`calc_runnums $dsize`
          if [[ "$op_name" =~ "range" ]] || [[ "$op_name" =~ "getall" ]]
          then
            run_nums=`echo $run_nums 1000 3  | awk '{if($1/$2>$3) {printf"%d",$1/$2} else {printf"%d",$3}}'`
          fi
          item_nums=`echo $run_nums $DIFF_TIMES | awk '{printf"%d", $1*$2}'`
          cmd="$REDIS_BENCHMARK -h $HOST -p $PORT -a $AUTH -t $op_name -c $conn -d $dsize -n $run_nums -r $item_nums"
          echo $cmd
          echo "`$cmd`" >> $RET_FILE
        done
      fi
    done
  fi
done
