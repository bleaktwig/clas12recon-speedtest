#!/bin/bash

# --+ SETUP +---------------------------------------------------------------------------------------
PLUGIN=$1
FV=5.0.2
GRAPES=2.12
JRE=11

# --+ INSTALL CLARA +-------------------------------------------------------------------------------
tar xzf clara-cre-$FV.tar.gz
(
    mkdir clara-cre/jre
    cd clara-cre/jre
    OS=$(uname)
    case $OS in
        'Linux')
            MACHINE_TYPE=$(uname -m)
            if [ "$MACHINE_TYPE" == "x86_64" ]; then
                cp ../../linux-64-$JRE.tar.gz .
                tar xzf ./linux-64-$JRE.tar.gz
                rm linux-64-$JRE.tar.gz
            else
                cp ../../linux-i586-$JRE.tar.gz .
                tar xzf ./linux-i586-$JRE.tar.gz
                rm linux-i586.tar-$JRE.gz
            fi
        ;;

        'Darwin')
            cp ../../macosx-64-$JRE.tar.gz .
            tar xzf ./macosx-64-$JRE.tar.gz
            rm macosx-64-$JRE.tar.gz
        ;;

        *) ;;
    esac
)
mv clara-cre "$CLARA_HOME"

# --+ INSTALL COATJAVA +----------------------------------------------------------------------------
tar xzf coatjava-$PLUGIN.tar.gz
(
    mkdir -p $CLARA_HOME/plugins/clas12/lib/clas
    mkdir -p $CLARA_HOME/plugins/clas12/lib/services
    mkdir -p $CLARA_HOME/plugins/clas12/config

    cd coatjava
    cp -rp etc "$CLARA_HOME"/plugins/clas12/.
    cp -rp bin "$CLARA_HOME"/plugins/clas12/.
    cp -rp lib/utils "$CLARA_HOME"/plugins/clas12/lib/.
    cp -rp lib/clas/* "$CLARA_HOME"/plugins/clas12/lib/clas/.
    cp -rp lib/services/* "$CLARA_HOME"/plugins/clas12/lib/services/.
)
rm -rf coatjava

# --+ INSTALL GRAPES +------------------------------------------------------------------------------
tar xzf grapes-$GRAPES.tar.gz
(
    mv grapes-$GRAPES "$CLARA_HOME"/plugins/grapes
    cp -rp "$CLARA_HOME"/plugins/grapes/bin/clara-grapes "$CLARA_HOME"/bin/.
    rm -f "$CLARA_HOME"/plugins/clas12/bin/clara-rec
    rm -f "$CLARA_HOME"/plugins/clas12/README
    cp -rp "$CLARA_HOME"/plugins/clas12/etc/services/*.yaml "$CLARA_HOME"/plugins/clas12/config/.
    rm -rf "$CLARA_HOME"/plugins/clas12/etc/services
)

chmod a+x "$CLARA_HOME"/bin/*
chmod -R a+rx $CLARA_HOME
