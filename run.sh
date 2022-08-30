#!/bin/bash

usage() {
    echo ""
    echo "usage: $0 [-hse] [-n <nevents>] [-j <njobs>] [-y <yaml>] [-i <inputfile>] c1 [c2 ...]"
    echo "    -h             Display this usage message."
    echo "    -s             Use JVM serial garbage collector."
    echo "    -e             Use experimental options (-XX:+UseJVMCICompiler)"
    echo "    -n <nevents>   Number of events per job. Default is 10.000."
    echo "    -j <njobs>     Number of parallel jobs per version. Default is 1."
    echo "    -y <yaml>      Yaml file used for the test. Default is dc.yaml."
    echo "    -i <inputfile> Location of input file to use. Default is [...]."
    echo "    c1 [c2 ...]    Location of (one or more) CLAS12 offline software versions to use."
    echo ""
    echo "    NOTE. The total number of jobs created will be 2*n*njobs, where n is the number of"
    echo "          positional arguments. For a fair test, this shouldn't surpass the number of"
    echo "          available physical cores!"
    echo ""
    exit 1
}

# --+ HANDLE ARGS +---------------------------------------------------------------------------------
# Get args.
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

# Give optargs a default value if none is given.
if [ ! -n "$NEVENTS" ];   then NEVENTS=10000;        fi
if [ ! -n "$NJOBS" ];     then NJOBS=1;              fi
if [ ! -n "$YAML" ];      then YAML="yaml/all.yaml"; fi
if [ ! -n "$INPUTFILE" ]; then INPUTFILE="...";      fi # TODO. Add a file from /work or smth.

# Check args.
if [ "$NEVENTS" -le 0 ]; then echo "Number of events can't be 0 or negative!"; usage; fi
if [ "$NJOBS"   -le 0 ]; then echo "Number of jobs can't be 0 or negative!";   usage; fi
if [ ! -f "$YAML" ];     then echo "File $YAML not found!";                    usage; fi
if [ ! -f $INPUTFILE ];  then echo "File $INPUTFILE not found!";               usage; fi
if [ ! -n "$1" ];        then echo "missing CLAS12 software versions.";        usage; fi

# Capture positional arguments.
CLAS12VERS=( "$@" ) # Get CLAS12 software versions from positional args.

# --+ NOTE. Temporary code. +-----------------------------------------------------------------------
echo "  * NEVENTS    = $NEVENTS"
echo "  * NJOBS      = $NJOBS"
echo "  * YAML       = $YAML"
echo "  * INPUTFILE  = $INPUTFILE"
echo "  * JAVA_OPTS  = $JAVA_OPTS"
echo "  * CLAS12VERS = {"
for i in "${CLAS12VERS[@]}"; do echo "        $i"; done
echo "    }"
echo ""
# --------------------------------------------------------------------------------------------------

# --+ SETUP +---------------------------------------------------------------------------------------
INDIR="$PWD/in"
OUTDIR="$PWD/out"
CLARADIR="$PWD/clara"
JUNKDIR="$PWD/junk"
LOGDIR="$PWD/log"

# Clear out $INDIR, $OUTDIR, and $CLARADIR.
rm $INDIR/*.hipo  2> /dev/null
rm $OUTDIR/*.hipo 2> /dev/null

# Copy file to $INDIR and reduce to NEVENTS to minimize disk usage.
# TODO. Add banks needed by CVT.
TMPFILE="$INDIR/tmp.hipo"
hipo-utils -filter -b "RUN::config,DC::tdc" -n $NEVENTS -o $TMPFILE $INPUTFILE

# Copy input file and install clara.
for ((JOB=0;JOB<$NJOBS;++JOB)); do
    for CLAS12VER in "${CLAS12VERS[@]}"; do
        # Get CLAS12 recon version filename.
        IFS='/' read -ra ADDR <<< "$CLAS12VER"
        for i in "${ADDR[@]}"; do RECONNAME=$i; done # Dirty but gets the job done.

        # --+ recon-util +--------------------------------------------------------------------------
        RUNNAME="$RECONNAME.recon-util-$JOB"
        cp "$TMPFILE" "$INDIR/$RUNNAME.hipo" # Copy input file.

        # --+ clara +-------------------------------------------------------------------------------
        RUNNAME="$RECONNAME.clara-$JOB"
        cp "$TMPFILE" "$INDIR/$RUNNAME.hipo" # Copy input file.

        # Install clara from $CLAS12VER.
        # cd "$CLARADIR"
        # tar -C "$CLAS12VER" -czf "$CLARADIR/coatjava-$RUNNAME.tar.gz" "coatjava"
        # export CLARA_HOME="$CLARADIR/$RUNNAME"
        # ./install-claracre-clas.sh "$RUNNAME"
        # rm "coatjava.tar.gz"
        # cd - > /dev/null
    done
done
rm $TMPFILE

# --+ RUN +-----------------------------------------------------------------------------------------
for ((JOB=0;JOB<$NJOBS;++JOB)); do
    for CLAS12VER in "${CLAS12VERS[@]}"; do
        # --+ recon-util +--------------------------------------------------------------------------
        RUNNAME="$RECONNAME.recon-util-$JOB"
        export MALLOC_ARENA_MAX=1
        RECON="$CLAS12VER/coatjava/bin/"

        # TODO. Run.

        # --+ clara +-------------------------------------------------------------------------------
        RUNNAME="$RECONNAME.clara-$JOB.hipo"
        # ulimit -u 49152
        unset CLARA_MONITOR_FE
        export CLARA_USER_DATA="$JUNKDIR"

        # TODO. Run.

    done
done

# TODO. Write output to well-formatted file?

# CLARA13="/work/clas12/users/benkel/dc-optimization/clara-versions/upstream"
# CLARA17="/work/clas12/users/benkel/dc-optimization/clara-versions/fork"
# CLARA21="/work/clas12/users/benkel/dc-optimization/clara-versions/matrixtests"
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
