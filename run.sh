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
rm $INDIR/*.hipo    2> /dev/null
rm $INDIR/*.txt     2> /dev/null
rm $OUTDIR/*.hipo   2> /dev/null
rm -rf $CLARADIR/*/ 2> /dev/null

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
        echo "$RUNNAME.hipo" > "$INDIR/$RUNNAME.txt"

        # Install clara from $CLAS12VER.
        cd "$CLARADIR"
        tar -C "$CLAS12VER" -czf "$CLARADIR/coatjava-$RUNNAME.tar.gz" "coatjava"
        export CLARA_HOME="$CLARADIR/$RUNNAME"
        ./install-claracre-clas.sh "$RUNNAME"
        rm "coatjava-$RUNNAME.tar.gz"
        cd - > /dev/null
    done
done
rm $TMPFILE

# --+ RUN +-----------------------------------------------------------------------------------------
# for ((JOB=0;JOB<$NJOBS;++JOB)); do
#     for CLAS12VER in "${CLAS12VERS[@]}"; do
#         # --+ recon-util +--------------------------------------------------------------------------
#         RUNNAME="$RECONNAME.recon-util-$JOB"
#         export MALLOC_ARENA_MAX=1
#         RECON="$CLAS12VER/coatjava/bin/recon-util"
#
#         # Run.
#         $RECON -i "$INDIR/$RUNNAME.hipo" -o "$OUTDIR/$RUNNAME.hipo" -y $YAML -n $NEVENTS > "$LOGDIR/$RUNNAME.txt" &
#
#
#         # --+ clara +-------------------------------------------------------------------------------
#         RUNNAME="$RECONNAME.clara-$JOB"
#         # ulimit -u 49152
#         unset CLARA_MONITOR_FE
#         export CLARA_USER_DATA="$JUNKDIR"
#         export CLARA_HOME="$CLARADIR/$RUNNAME"
#         export CLAS12DIR="$CLARA_HOME/plugins/clas12"
#         export JAVA_OPTS="$JAVA_OPTS -Djava.util.logging.config.file=$CLAS12DIR/etc/logging/debug.properties"
#
#         # Run.
#         CLARA_HOME/lib/clara/run-clara -i $INDIR -o $OUTDIR -z "out_" -x . -t 1 -e $NEVENTS -s $RUNNAME $YAML "$INDIR/$RUNNAME.txt" > "$LOGDIR/$RUNNAME.txt" &
#         sleep 5
#     done
# done

# TODO. Write output to well-formatted file?
