#!/bin/bash

# Print usage.
usage() {
    echo ""
    echo "usage: $0 [-hserc] [-n <nevents>] [-j <njobs>] [-y <yaml>] [-i <inputfile>] c1 [c2 ...]"
    echo "    -h             Display this usage message."
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

# --+ HANDLE ARGS +---------------------------------------------------------------------------------
# Get args.
while getopts "hn:j:y:i:" opt; do
    case "${opt}" in
        \? ) usage;;
        h  ) usage;;
        n  ) NEVENTS=${OPTARG};;
        j  ) NJOBS=${OPTARG};;
        y  ) YAML=${OPTARG};;
        i  ) INPUTFILE=${OPTARG};;
    esac
done
shift $((OPTIND -1))

# Give optargs a default value if none is given.
if [ ! -n "$NEVENTS" ];       then NEVENTS=10000;             fi
if [ ! -n "$NJOBS" ];         then NJOBS=1;                   fi
if [ ! -n "$YAML" ];          then YAML="$PWD/yaml/all.yaml"; fi
if [ ! -n "$INPUTFILE" ];     then INPUTFILE="INVALID";       fi

# Check args.
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
export LOGDIR="$PWD/log"

# --+ INSTALL +-------------------------------------------------------------------------------------
# Clear out $INDIR.
rm $INDIR/*.hipo 2> /dev/null
rm $INDIR/*.txt  2> /dev/null

# Copy file to $INDIR and reduce to NEVENTS to minimize disk usage.
echo ""
echo "Copying input file to $INDIR."
export TMPFILE="$INDIR/tmp.hipo"
BANKS="BAND::adc,BAND::tdc,BMT::adc,BST::adc,CND::adc,CND::tdc,CTOF::adc,CTOF::tdc,DC::tdc,ECAL::adc,ECAL::tdc,FTCAL::adc,FTHODO::adc,FTOF::adc,FTOF::tdc,FTTRK::adc,HEL::adc,HEL::online,HTCC::adc,LTCC::adc,LTCC::tdc,RAW::tdc,RAW::vtp,RF::adc,RF::tdc,RICH::tdc,RUN::config,RUN::trigger"
hipo-utils -filter -b $BANKS -n $NEVENTS -o $TMPFILE $INPUTFILE > /dev/null

# Copy input file and install clara.
echo "Setting up running environment (this can take a while)."
for ((JOB=0;JOB<$NJOBS;++JOB)); do
    for CLAS12VER in "${CLAS12VERS[@]}"; do
        # Get CLAS12 recon version filename.
        IFS='/' read -ra ADDR <<< "$CLAS12VER"
        for i in "${ADDR[@]}"; do RECONNAME=$i; done # Dirty but gets the job done.
        install_reconutil $RECONNAME $JOB &
    done
done

# Wait for all installations to finish.
wait
rm $TMPFILE

# --+ RUN +-----------------------------------------------------------------------------------------
# Clear out $OUTDIR and $LOGDIR.
rm $OUTDIR/*.hipo   2> /dev/null
rm $LOGDIR/*.txt    2> /dev/null

for ((JOB=0;JOB<$NJOBS;++JOB)); do
    for CLAS12VER in "${CLAS12VERS[@]}"; do
        # Get CLAS12 recon version filename.
        IFS='/' read -ra ADDR <<< "$CLAS12VER"
        for i in "${ADDR[@]}"; do RECONNAME=$i; done # Dirty but gets the job done.

        RUNNAME="$RECONNAME.reconutil-$JOB"

        # Call recon-util.
        cd "$CLAS12VER/coatjava/bin"
        . recon-util \
                -c 2 -n 10000 -y $YAML -n $NEVENTS \
                -i $INDIR/$RUNNAME.hipo -o $OUTDIR/$RUNNAME.hipo \
                > $LOGDIR/$RUNNAME.txt &
        cd - > /dev/null
    done
done

# Wait for all runs to finish.
# TODO. This is not actually waiting for the runs to finish...
wait

# Print to stdout total runtime of each version.
for file in $LOGDIR/*; do
    # Extract filename.
    filename="$(basename $file .txt)"

    # Extract and print time.
    time=$(grep -F ">>>>>" $file | tail -c 13)
    echo "$filename : $time"
done
