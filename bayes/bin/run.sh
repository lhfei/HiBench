#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
bin=`dirname "$0"`
bin=`cd "$bin"; pwd`

echo "========== running bayes bench =========="
# configure
DIR=`cd $bin/../; pwd`
. "${DIR}/../bin/hibench-config.sh"
. "${DIR}/conf/configure.sh"

MAHOUT_BIN_DIR=$HIBENCH_HOME"/common/hibench/mahout/target"

check_compress

# path check
${HADOOP_EXECUTABLE} $RMDIR_CMD ${OUTPUT_HDFS}

if [ "x"$HADOOP_VERSION == "xhadoop2" ]; then
  SIZE=`grep "BYTES_DATA_GENERATED=" ${DIR}/$TMPLOGFILE | sed 's/BYTES_DATA_GENERATED=//'`
else
  SIZE=$($HADOOP_EXECUTABLE job -history $INPUT_HDFS | grep 'HiBench.Counters.*|BYTES_DATA_GENERATED')
  SIZE=${SIZE##*|}
  SIZE=${SIZE//,/}
fi

cd $MAHOUT_BIN_DIR
if [ ! -d $MAHOUT_BIN_DIR"/mahout-0.9-cdh5.1.0" ]; then
  tar zxf mahout-distribution-0.7.tar.gz
fi

MAHOUT_HOME=$MAHOUT_BIN_DIR"/mahout-0.9-cdh5.1.0"

# pre-running
START_TIME=`timestamp`

# run bench
# Note that we borrow the numReducers parameter from the environment.  It must be set or else you will only run
# one reducer.
$MAHOUT_HOME/bin/mahout seq2sparse \
        $COMPRESS_OPT -i ${INPUT_HDFS} -o ${OUTPUT_HDFS}/vectors  -lnorm -nv  -wt tfidf -ng ${NGRAMS} --numReducers $NUM_REDS

$MAHOUT_HOME/bin/mahout trainnb \
        $COMPRESS_OPT -i ${OUTPUT_HDFS}/vectors/tfidf-vectors -el -o ${OUTPUT_HDFS}/model -li ${OUTPUT_HDFS}/labelindex  -ow --tempDir ${OUTPUT_HDFS}/temp

# post-running
END_TIME=`timestamp`
gen_report "BAYES" ${START_TIME} ${END_TIME} ${SIZE}

