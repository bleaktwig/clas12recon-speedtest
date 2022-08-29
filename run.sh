#!/bin/bash

usage() {
    echo "usage: $0 [-hse] [-n <nevents>] [-j <njobs>] [-y <yaml>] [-i <inputfile>] c1 [c2 ...]"
    echo "    -h             Display this usage message."
    echo "    -s             Use JVM serial garbage collector."
    echo "    -e             Use experimental options (-XX:+UseJVMCICompiler)"
    echo "    -n <nevents>   Number of events per job. Default is 10.000."
    echo "    -j <njobs>     Number of parallel jobs. Default is 1."
    echo "    -y <yaml>      Yaml file used for the test. Default is dc.yaml."
    echo "    -i <inputfile> Location of input file to use. Default is [...]"
    echo "    <cn>           Location of (one or more) CLAS12 offline software versions to use."
    exit 1
}

while getopts "hsen:j:y:i:" opt; do
    case "${opt}" in
        \? ) usage;;
        h  ) usage;;
        s  ) JAVA_OPTS=$JAVA_OPTS' -XX:+UseSerialGC';;
        e  ) JAVA_OPTS=$JAVA_OPTS' -XX:+UnlockExperimentalVMOptions -XX:+EnableJVMCI -XX:+UseJVMCICompiler';;
        n  ) NEVENTS=${OPTARG};;
        j  ) NJOBS=${OPTARG};;
        y  ) YAML=${OPTARG};;
        i  ) INPUTFILE=${OPTARG};;
    esac
done
shift $((OPTIND -1))

if [ ! -n "$NEVENTS" ];   then NEVENTS=10000;   fi
if [ ! -n "$NJOBS" ];     then NJOBS=1;         fi
if [ ! -n "$YAML" ];      then YAML="dc.yaml";  fi
if [ ! -n "$INPUTFILE" ]; then INPUTFILE="..."; fi
if [ ! -n "$1" ];         then echo "missing CLAS12 versions."; usage; fi
CLAS12VERS=( "$@" ) # Get CLAS12 software versions from positional args.

echo "  * NEVENTS    = $NEVENTS"
echo "  * NJOBS      = $NJOBS"
echo "  * YAML       = $YAML"
echo "  * INPUTFILE  = $INPUTFILE"
echo "  * JAVA_OPTS  = $JAVA_OPTS"
echo "  * CLAS12VERS = {"
for i in "${CLAS12VERS[@]}"; do echo "        $i"; done
echo "    }"

# TODO. Make sure that this runs over graalvm.

# TODO. INSTALL CLARA WITH SAID CLAS12 VERSIONS.
# TODO. SETUP RUN CONDITIONS.
# TODO. RUN!
# TODO. Write output to well-formatted file.

# JAVA_OPTS_SERIALGC='-XX:+UseSerialGC'
# JAVA_OPTS_JVMCI='-XX:+UnlockExperimentalVMOptions -XX:+EnableJVMCI -XX:+UseJVMCICompiler'


# # --+ recon-util +--------------------------------------
# export MALLOC_ARENA_MAX=1
#
# RECON01="/work/clas12/users/benkel/dc-optimization/clas12-versions/upstream/coatjava/bin/speedtest-nochanges"
# RECON02="/work/clas12/users/benkel/dc-optimization/clas12-versions/upstream/coatjava/bin/speedtest-noserialgc"
# RECON03="/work/clas12/users/benkel/dc-optimization/clas12-versions/upstream/coatjava/bin/speedtest-experimentaloptions"
# RECON04="/work/clas12/users/benkel/dc-optimization/clas12-versions/upstream/coatjava/bin/speedtest-both"
#
# RECON05="/work/clas12/users/benkel/dc-optimization/clas12-versions/fork/coatjava/bin/speedtest-nochanges"
# RECON06="/work/clas12/users/benkel/dc-optimization/clas12-versions/fork/coatjava/bin/speedtest-noserialgc"
# RECON07="/work/clas12/users/benkel/dc-optimization/clas12-versions/fork/coatjava/bin/speedtest-experimentaloptions"
# RECON08="/work/clas12/users/benkel/dc-optimization/clas12-versions/fork/coatjava/bin/speedtest-both"
#
# RECON09="/work/clas12/users/benkel/dc-optimization/clas12-versions/matrixtests/coatjava/bin/speedtest-nochanges"
# RECON10="/work/clas12/users/benkel/dc-optimization/clas12-versions/matrixtests/coatjava/bin/speedtest-noserialgc"
# RECON11="/work/clas12/users/benkel/dc-optimization/clas12-versions/matrixtests/coatjava/bin/speedtest-experimentaloptions"
# RECON12="/work/clas12/users/benkel/dc-optimization/clas12-versions/matrixtests/coatjava/bin/speedtest-both"
#
# # --+ clara +-------------------------------------------
# ulimit -u 49152
# unset CLARA_MONITOR_FE
# export CLARA_USER_DATA="/volatile/clas12/benkel/junk"
#
# CLARA13="/work/clas12/users/benkel/dc-optimization/clara-versions/upstream"
# CLARA17="/work/clas12/users/benkel/dc-optimization/clara-versions/fork"
# CLARA21="/work/clas12/users/benkel/dc-optimization/clara-versions/matrixtests"
#
# JAVA_OPTS_NOCHANGES='-XX:+UseSerialGC'
# JAVA_OPTS_NOSERIALGC=''
# JAVA_OPTS_EXPERIMENTALOPTS='-XX:+UnlockExperimentalVMOptions -XX:+EnableJVMCI -XX:+UseJVMCICompiler'
# JAVA_OPTS_BOTH='-XX:+UseSerialGC -XX:+UnlockExperimentalVMOptions -XX:+EnableJVMCI -XX:+UseJVMCICompiler'
#
# # --+ Files +-------------------------------------------
# INDIR="/volatile/clas12/benkel/in-6377"
# OUTDIR="/volatile/clas12/benkel/out"
# YAML="/volatile/clas12/benkel/data.yaml"
#
# # --+ Number of events +--------------------------------
# NEVENTS="10000"
#
# # --+ Run! +--------------------------------------------
# $RECON01 -i $INDIR/01.hipo -o $OUTDIR/01.hipo -y $YAML -n $NEVENTS > reconutil_upstream_nochanges.txt &
# $RECON02 -i $INDIR/02.hipo -o $OUTDIR/02.hipo -y $YAML -n $NEVENTS > reconutil_upstream_noserialgc.txt &
# $RECON03 -i $INDIR/03.hipo -o $OUTDIR/03.hipo -y $YAML -n $NEVENTS > reconutil_upstream_experimentaloptions.txt &
# $RECON04 -i $INDIR/04.hipo -o $OUTDIR/04.hipo -y $YAML -n $NEVENTS > reconutil_upstream_both.txt &
# $RECON05 -i $INDIR/05.hipo -o $OUTDIR/05.hipo -y $YAML -n $NEVENTS > reconutil_fork_nochanges.txt &
# $RECON06 -i $INDIR/06.hipo -o $OUTDIR/06.hipo -y $YAML -n $NEVENTS > reconutil_fork_noserialgc.txt &
# $RECON07 -i $INDIR/07.hipo -o $OUTDIR/07.hipo -y $YAML -n $NEVENTS > reconutil_fork_experimentaloptions.txt &
# $RECON08 -i $INDIR/08.hipo -o $OUTDIR/08.hipo -y $YAML -n $NEVENTS > reconutil_fork_both.txt &
# $RECON09 -i $INDIR/09.hipo -o $OUTDIR/09.hipo -y $YAML -n $NEVENTS > reconutil_matrixtests_nochanges.txt &
# $RECON10 -i $INDIR/10.hipo -o $OUTDIR/10.hipo -y $YAML -n $NEVENTS > reconutil_matrixtests_noserialgc.txt &
# $RECON11 -i $INDIR/11.hipo -o $OUTDIR/11.hipo -y $YAML -n $NEVENTS > reconutil_matrixtests_experimentaloptions.txt &
# $RECON12 -i $INDIR/12.hipo -o $OUTDIR/12.hipo -y $YAML -n $NEVENTS > reconutil_matrixtests_both.txt &
#
# # Clara upstream
# export CLARA_HOME="$CLARA13"
# export CLAS12DIR="$CLARA_HOME/plugins/clas12"
# export JAVA_OPTS="$JAVA_OPTS_NOCHANGES -Djava.util.logging.config.file=$CLAS12DIR/etc/logging/debug.properties"
# $CLARA13/lib/clara/run-clara -i $INDIR -o $OUTDIR -z "out_" -x . -t 1 -e $NEVENTS -s "clara-13" $YAML "$INDIR/13.txt" > clara_upstream_nochanges.txt &
# sleep 5
#
# export JAVA_OPTS="$JAVA_OPTS_NOSERIALGC -Djava.util.logging.config.file=$CLAS12DIR/etc/logging/debug.properties"
# $CLARA13/lib/clara/run-clara -i $INDIR -o $OUTDIR -z "out_" -x . -t 1 -e $NEVENTS -s "clara-14" $YAML "$INDIR/14.txt" > clara_upstream_noserialgc.txt &
# sleep 5
#
# export JAVA_OPTS="$JAVA_OPTS_EXPERIMENTALOPTS -Djava.util.logging.config.file=$CLAS12DIR/etc/logging/debug.properties"
# $CLARA13/lib/clara/run-clara -i $INDIR -o $OUTDIR -z "out_" -x . -t 1 -e $NEVENTS -s "clara-15" $YAML "$INDIR/15.txt" > clara_upstream_experimentaloptions.txt &
# sleep 5
#
# export JAVA_OPTS="$JAVA_OPTS_BOTH -Djava.util.logging.config.file=$CLAS12DIR/etc/logging/debug.properties"
# $CLARA13/lib/clara/run-clara -i $INDIR -o $OUTDIR -z "out_" -x . -t 1 -e $NEVENTS -s "clara-16" $YAML "$INDIR/16.txt" > clara_upstream_both.txt &
# sleep 5
#
# # Clara fork
# export CLARA_HOME="$CLARA17"
# export CLAS12DIR="$CLARA_HOME/plugins/clas12"
# export JAVA_OPTS="$JAVA_OPTS_NOCHANGES -Djava.util.logging.config.file=$CLAS12DIR/etc/logging/debug.properties"
# $CLARA17/lib/clara/run-clara -i $INDIR -o $OUTDIR -z "out_" -x . -t 1 -e $NEVENTS -s "clara-17" $YAML "$INDIR/17.txt" > clara_fork_nochanges.txt &
# sleep 5
#
# export JAVA_OPTS="$JAVA_OPTS_NOSERIALGC -Djava.util.logging.config.file=$CLAS12DIR/etc/logging/debug.properties"
# $CLARA17/lib/clara/run-clara -i $INDIR -o $OUTDIR -z "out_" -x . -t 1 -e $NEVENTS -s "clara-18" $YAML "$INDIR/18.txt" > clara_fork_noserialgc.txt &
# sleep 5
#
# export JAVA_OPTS="$JAVA_OPTS_EXPERIMENTALOPTS -Djava.util.logging.config.file=$CLAS12DIR/etc/logging/debug.properties"
# $CLARA17/lib/clara/run-clara -i $INDIR -o $OUTDIR -z "out_" -x . -t 1 -e $NEVENTS -s "clara-19" $YAML "$INDIR/19.txt" > clara_fork_experimentaloptions.txt &
# sleep 5
#
# export JAVA_OPTS="$JAVA_OPTS_BOTH -Djava.util.logging.config.file=$CLAS12DIR/etc/logging/debug.properties"
# $CLARA17/lib/clara/run-clara -i $INDIR -o $OUTDIR -z "out_" -x . -t 1 -e $NEVENTS -s "clara-20" $YAML "$INDIR/20.txt" > clara_fork_both.txt &
# sleep 5
#
# # Clara matrixtests
# export CLARA_HOME="$CLARA21"
# export CLAS12DIR="$CLARA_HOME/plugins/clas12"
# export JAVA_OPTS="$JAVA_OPTS_NOCHANGES -Djava.util.logging.config.file=$CLAS12DIR/etc/logging/debug.properties"
# $CLARA21/lib/clara/run-clara -i $INDIR -o $OUTDIR -z "out_" -x . -t 1 -e $NEVENTS -s "clara-21" $YAML "$INDIR/21.txt" > clara_matrixtests_nochanges.txt &
# sleep 5
#
# export JAVA_OPTS="$JAVA_OPTS_NOSERIALGC -Djava.util.logging.config.file=$CLAS12DIR/etc/logging/debug.properties"
# $CLARA21/lib/clara/run-clara -i $INDIR -o $OUTDIR -z "out_" -x . -t 1 -e $NEVENTS -s "clara-22" $YAML "$INDIR/22.txt" > clara_matrixtests_noserialgc.txt &
# sleep 5
#
# export JAVA_OPTS="$JAVA_OPTS_EXPERIMENTALOPTS -Djava.util.logging.config.file=$CLAS12DIR/etc/logging/debug.properties"
# $CLARA21/lib/clara/run-clara -i $INDIR -o $OUTDIR -z "out_" -x . -t 1 -e $NEVENTS -s "clara-23" $YAML "$INDIR/23.txt" > clara_matrixtests_experimentaloptions.txt &
# sleep 5
#
# export JAVA_OPTS="$JAVA_OPTS_BOTH -Djava.util.logging.config.file=$CLAS12DIR/etc/logging/debug.properties"
# $CLARA21/lib/clara/run-clara -i $INDIR -o $OUTDIR -z "out_" -x . -t 1 -e $NEVENTS -s "clara-24" $YAML "$INDIR/24.txt" > clara_matrixtests_both.txt &
