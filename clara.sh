#!/bin/bash

# ulimit -u 49152

# Set CLARA_HOME to the version of clara we're testing.
export CLARA_HOME="/home/twig/code/jlab/clas12recon-speedtest/clara/offline-software.clara-0"

# Output location.
export CLARA_USER_DATA="home/twig/code/jlab/clas12recon-speedtest/junk"

# Don't touch anything beyond this point!
export CLAS12DIR=${CLARA_HOME}/plugins/clas12
export PATH=${PATH}:$CLAS12DIR/bin
unset CLARA_MONITOR_FE

if [ -z $CCDB_CONNECTION ] || ! [[ $CCDB_CONNECTION = sqlite* ]]; then
  export CCDB_CONNECTION=mysql://clas12reader@clasdb-farm.jlab.org/clas12
fi
export RCDB_CONNECTION=mysql://rcdb@clasdb-farm.jlab.org/rcdb

expopts='-XX:+UnlockExperimentalVMOptions -XX:+EnableJVMCI -XX:+UseJVMCICompiler'
v=`$CLARA_HOME/lib/clara/run-java -version 2>&1 | head -1 | awk '{print$3}' | sed 's/"//g' | awk -F\. '{print$1}'`
if [ $v -ge 11 ]
then
    JAVA_OPTS="$JAVA_OPTS $expopts"
fi
JAVA_OPTS="$JAVA_OPTS -Djava.util.logging.config.file=$CLAS12DIR/etc/logging/debug.properties"

outprefix=rec_
logdir=.
threads=32
yaml=clara.yaml
while getopts "p:l:t:n:y:" OPTION; do
    case $OPTION in
        p)  outprefix=$OPTARG ;;
        l)  logdir=$OPTARG ;;
        t)  threads=$OPTARG ;;
        n)  nevents="-e $OPTARG" ;;
        y)  yaml=$OPTARG ;;
        ?)  exit 1 ;;
    esac
done

shift $((OPTIND-1))
if [[ $# -ne 1 ]]; then
    echo "usage: clara.sh [ OPTIONS ] jobname"
    exit 1
fi
jobname=$1

# check existence, size, and hipo-utils -test:
hipocheck() {
    ( [ -e $1 ] && [ $(stat -L -c%s $1) -gt 100 ] && hipo-utils -test $1 ) \
        || \
    ( echo "clara.sh: ERROR: Corrupt File: $1" 2>&1 && false )
}

# run-clara uses some of these to store info during job:
mkdir -p $logdir
mkdir -p $CLARA_USER_DATA/log
mkdir -p $CLARA_USER_DATA/config
mkdir -p $CLARA_USER_DATA/data/output

# setup filelist:
find . -maxdepth 1 -xtype f -name '*.hipo' | sed 's;^\./;;' > filelist.txt

# run clara:
time $CLARA_HOME/lib/clara/run-clara \
        -i . \
        -o . \
        -z $outprefix \
        -x $logdir \
        -t $threads \
        $nevents \
        -s $jobname \
        $yaml \
        ./filelist.txt
claraexit=$?

# if all else is well, use exit code from run-clara:
exit $claraexit
