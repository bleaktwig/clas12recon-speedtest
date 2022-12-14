#!/bin/sh
cd "$CLAS12VER/coatjava/bin"

. `dirname $0`/env.sh
export MALLOC_ARENA_MAX=1

java $JAVA_OPTS -cp "$CLAS12DIR/lib/clas/*:$CLAS12DIR/lib/services/*:$CLAS12DIR/lib/utils/*" \
        org.jlab.clas.reco.EngineProcessor $* > "$LOGDIR/$RUNNAME.txt" &

cd - > /dev/null
