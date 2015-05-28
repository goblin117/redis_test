#/bin/bash
#base path
REDIS_BIN=/root/redis-2.8.19/src
REDIS_BENCHMARK="${REDIS_BIN}/redis-benchmark"
REDIS_CLI="${REDIS_BIN}/redis-cli"
RET_FILE="ret_file"
#params
HOST="xx.xxx.xxx.xxx"
PORT="6379"
AUTH="password"
TOTAL_QUOTA=1073741824 # 1G
MAX_QUOTA=`echo 0.9 $TOTAL_QUOTA | awk '{printf"%d", $1*$2}'`
MAX_RUN_NUMS=1000000
DIFF_TIMES=5
MAX_MEM=900


DATA_SIZE_ARR=(4 32 128 512 1024 10240 102400 1048576 10485760 104857600)
OP_ARR=(set get lpush lrange lpop)
CHECK_OP_ARR=(set lpush)
CONN_ARR=(10 50 100 200)

#DATA_SIZE_ARR=(4 32)
#OP_ARR=(set get lpush)
#CHECK_OP_ARR=(set lpush)
#CONN_ARR=(10)
