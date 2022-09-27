#!/bin/bash

# Print usage.
usage() {
    echo ""
    echo "usage: $0 [-hsercIR] [-n <nevents>] [-j <njobs>] [-y <yaml>] [-i <inputfile>] c1 [c2 ...]"
    echo "    -h             Display this usage message."
    echo "    -s             Use JVM serial garbage collector (-XX:+UseSerialGC)."
    echo "    -e             Use experimental options (-XX:+UseJVMCICompiler)."
    echo "    -r             Install and/or run only recon-util."
    echo "    -c             Install and/or run only clara."
    echo "    -I             Only install recon-util and/or clara, do not run."
    echo "    -R             Only run recon-util and/or clara from a previous installation."
    echo "    -n <nevents>   Number of events per job. Default is 10.000."
    echo "    -j <njobs>     Number of parallel jobs per version. Default is 1."
    echo "    -y <yaml>      Absolute path to yaml file used for the test. Default is "
    echo "                       $PWD/yaml/dc.yaml."
    echo "    -i <inputfile> Absolute path to input file to use. Default is [TODO]."
    echo "    c1 [c2 ...]    Absolute path to (one or more) CLAS12 offline software versions to test."
    echo ""
    echo "    NOTE. The total number of jobs created will be 2*n*njobs, where n is the number of"
    echo "          positional arguments. For a fair test, this shouldn't surpass the number of"
    echo "          available physical cores!"
    echo ""
    exit 1
}

# "Install" recon-util (just make a copy of the input file).
install_reconutil() {
    # Give names to parameters to make this readable.
    RECONNAME=$1
    JOB=$2

    # Run.
    RUNNAME="$RECONNAME.reconutil-$JOB"
    cp "$TMPFILE" "$INDIR/$RUNNAME.hipo" # Copy input file.
}

# Copy input file and install clara.
install_clara() {
    # Give names to parameters to make this readable.
    RECONNAME=$1
    JOB=$2
    CLAS12VER=$3

    # Run.
    RUNNAME="$RECONNAME.clara-$JOB"
    cp "$TMPFILE" "$INDIR/$RUNNAME.hipo" # Copy input file.
    echo "$RUNNAME.hipo" > "$INDIR/$RUNNAME.txt"

    # Install clara from $CLAS12VER.
    cd "$CLARADIR"
    tar -C "$CLAS12VER" -czf "$CLARADIR/coatjava-$RUNNAME.tar.gz" "coatjava"
    CLARA_HOME="$CLARADIR/$RUNNAME"
    ./install-claracre-clas.sh $CLARA_HOME $RUNNAME $JOB
    rm "coatjava-$RUNNAME.tar.gz"
}

# --+ HANDLE ARGS +---------------------------------------------------------------------------------
# Get args.
while getopts "hsercIRn:j:y:i:" opt; do
    case "${opt}" in
        \? ) usage;;
        h  ) usage;;
        s  ) TESTOPTS=$TESTOPTS' -XX:+UseSerialGC';;
        e  ) TESTOPTS=$TESTOPTS' -XX:+UnlockExperimentalVMOptions -XX:+EnableJVMCI -XX:+UseJVMCICompiler';;
        r  ) ONLYRECONUTIL=true;;
        c  ) ONLYCLARA=true;;
        I  ) ONLYINSTALL=true;;
        R  ) ONLYRUN=true;;
        n  ) NEVENTS=${OPTARG};;
        j  ) NJOBS=${OPTARG};;
        y  ) YAML=${OPTARG};;
        i  ) INPUTFILE=${OPTARG};;
    esac
done
shift $((OPTIND -1))

# Give optargs a default value if none is given.
if [ ! -n "$ONLYRECONUTIL" ]; then ONLYRECONUTIL=false;       fi
if [ ! -n "$ONLYCLARA" ];     then ONLYCLARA=false;           fi
if [ ! -n "$ONLYINSTALL" ];   then ONLYINSTALL=false;         fi
if [ ! -n "$ONLYRUN" ];       then ONLYRUN=false;             fi
if [ ! -n "$NEVENTS" ];       then NEVENTS=10000;             fi
if [ ! -n "$NJOBS" ];         then NJOBS=1;                   fi
if [ ! -n "$YAML" ];          then YAML="$PWD/yaml/all.yaml"; fi
if [ ! -n "$INPUTFILE" ];     then INPUTFILE="...";           fi # TODO. Add a file from /work or smth.

# Check args.
if [ "$ONLYRECONUTIL" = true ] && [ "$ONLYCLARA" = true ]; then
    echo "-r and -c are not compatible!"
    usage
fi
if [ "$ONLYINSTALL" = true ] && [ "$ONLYRUN" = true ]; then
    echo "-I and -R are not compatible!"
    usage
fi
if [ "$NEVENTS" -le 0 ]; then echo "Number of events can't be 0 or negative!"; usage; fi
if [ "$NJOBS"   -le 0 ]; then echo "Number of jobs can't be 0 or negative!";   usage; fi
if [ ! -f "$YAML" ];     then echo "File $YAML not found!";                    usage; fi
if [ ! -f $INPUTFILE ];  then echo "File $INPUTFILE not found!";               usage; fi
if [ ! -n "$1" ];        then echo "missing CLAS12 software versions.";        usage; fi

# Capture positional arguments.
CLAS12VERS=( "$@" ) # Get CLAS12 software versions from positional args.

# --+ SETUP +---------------------------------------------------------------------------------------
export INDIR="$PWD/in"
export OUTDIR="$PWD/out"
export CLARADIR="$PWD/clara"
export JUNKDIR="$PWD/junk"
export LOGDIR="$PWD/log"

# --+ INSTALL +-------------------------------------------------------------------------------------
if [ $ONLYRUN = false ]; then
    # Clear out $INDIR.
    rm $INDIR/*.hipo 2> /dev/null
    rm $INDIR/*.txt  2> /dev/null

    # Copy file to $INDIR and reduce to NEVENTS to minimize disk usage.
    echo ""
    echo "Copying input file to $INDIR."
    # TODO. Add banks needed by CVT.
    export TMPFILE="$INDIR/tmp.hipo"
    hipo-utils -filter -b "RUN::config,DC::tdc" -n $NEVENTS -o $TMPFILE $INPUTFILE > /dev/null

    # Clear out $CLARADIR.
    rm -rf $CLARADIR/*/ 2> /dev/null

    # Copy input file and install clara.
    echo "Setting up running environment (this can take a while)."
    for ((JOB=0;JOB<$NJOBS;++JOB)); do
        for CLAS12VER in "${CLAS12VERS[@]}"; do
            # Get CLAS12 recon version filename.
            IFS='/' read -ra ADDR <<< "$CLAS12VER"
            for i in "${ADDR[@]}"; do RECONNAME=$i; done # Dirty but gets the job done.
            if [ $ONLYCLARA = false ]; then
                install_reconutil $RECONNAME $JOB &
            fi
            if [ $ONLYRECONUTIL = false ]; then
                install_clara $RECONNAME $JOB $CLAS12VER &
            fi
        done
    done

    # Wait for the installations to finish.
    wait
    rm $TMPFILE
fi

# --+ RUN +-----------------------------------------------------------------------------------------
if [ $ONLYINSTALL = false ]; then
    # Clear out $OUTDIR and $LOGDIR.
    rm $OUTDIR/*.hipo   2> /dev/null
    rm $LOGDIR/*.txt    2> /dev/null

    for ((JOB=0;JOB<$NJOBS;++JOB)); do
        for CLAS12VER in "${CLAS12VERS[@]}"; do
            # Get CLAS12 recon version filename.
            IFS='/' read -ra ADDR <<< "$CLAS12VER"
            for i in "${ADDR[@]}"; do RECONNAME=$i; done # Dirty but gets the job done.
            # --+ recon-util +--------------------------------------------------------------------------
            if [ $ONLYCLARA = false ]; then
                RUNNAME="$RECONNAME.reconutil-$JOB"

                export LOGDIR=$LOGDIR
                export RUNNAME=$RUNNAME
                export CLAS12VER="$CLAS12VER"
                export JAVA_OPTS="$TESTOPTS -Xmx1536m -Xms1024m"

                # Run.
                ./call-recon-util.sh \
                        -i "$INDIR/$RUNNAME.hipo" -o "$OUTDIR/$RUNNAME.hipo" -y $YAML -n $NEVENTS
            fi

            # --+ clara +-------------------------------------------------------------------------------
            if [ $ONLYRECONUTIL = false ]; then
                RUNNAME="$RECONNAME.clara-$JOB"
                # ulimit -u 49152
                export CLARA_HOME="$CLARADIR/$RUNNAME"
                export CLARA_USER_DATA="$JUNKDIR"
                export CLAS12DIR="$CLARA_HOME/plugins/clas12"
                export PATH=${PATH}:$CLAS12DIR/bin
                unset CLARA_MONITOR_FE

                if [ -z $CCDB_CONNECTION ] || ! [[ $CCDB_CONNECTION = sqlite* ]]; then
                    export CCDB_CONNECTION=mysql://clas12reader@clasdb-farm.jlab.org/clas12
                fi
                export RCDB_CONNECTION=mysql://rcdb@clasdb-farm.jlab.org/rcdb

                v=`$CLARA_HOME/lib/clara/run-java -version 2>&1 | head -1 | awk '{print$3}' | sed 's/"//g' | awk -F\. '{print$1}'`
                if [ $v -ge 11 ]; then JAVA_OPTS="$JAVA_OPTS $TESTOPTS"; fi
                JAVA_OPTS="$JAVA_OPTS -Djava.util.logging.config.file=$CLAS12DIR/etc/logging/debug.properties"

                # Run.
                $CLARA_HOME/lib/clara/run-clara \
                        -i $INDIR -o $OUTDIR -z "out_" -x $JUNKDIR -t 1 -e $NEVENTS -s $RUNNAME \
                        $YAML "$INDIR/$RUNNAME.txt" > "$LOGDIR/$RUNNAME.txt" &
                sleep 5
            fi
        done
    done
fi

# TODO. Write output to well-formatted file?
