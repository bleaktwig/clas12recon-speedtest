#!/bin/bash

# Setup.
CLAS12_V=$1
CLARA_V=5.0.2
# GRAPES_V=2.12
GRAPES_V=2.1
JAVA_V=11

# Install clara.
if [ ! -f clara-cre-$CLARA_V.tar.gz ]; then
    wget https://userweb.jlab.org/~gurjyan/clara-cre/clara-cre-$CLARA_V.tar.gz
fi
tar xzf clara-cre-$CLARA_V.tar.gz
(
    mkdir clara-cre/jre
    cd clara-cre/jre
    OS=$(uname)
    case $OS in
        'Linux')
            MACHINE_TYPE=$(uname -m)
            if [ "$MACHINE_TYPE" == "x86_64" ]; then
                if [ ! -f ../../linux-64-$JAVA_V.tar.gz ]; then
                    wget https://userweb.jlab.org/~gurjyan/clara-cre/linux-64-$JAVA_V.tar.gz
                    mv linux-64-11.tar.gz ../..
                fi
                cp ../../linux-64-$JAVA_V.tar.gz .
                tar xzf ./linux-64-$JAVA_V.tar.gz
                rm linux-64-$JAVA_V.tar.gz
            else
                if [ ! -f ../../linux-i586-$JAVA_V.tar.gz ]; then
                    wget https://userweb.jlab.org/~gurjyan/clara-cre/linux-i586-$JAVA_V.tar.gz
                    mv linux-i586-$JAVA_V.tar.gz ../..
                fi
                cp ../../linux-i586-$JAVA_V.tar.gz .
                tar xzf ./linux-i586-$JAVA_V.tar.gz
                rm linux-i586.tar-$JAVA_V.gz
            fi
        ;;

        'Darwin')
            if [ ! -f ../../macosx-64-$JAVA_V.tar.gz ]; then
                wget https://userweb.jlab.org/~gurjyan/clara-cre/macosx-64-$JAVA_V.tar.gz
                mv macosx-64-$JAVA_V.tar.gz ../..
            fi
            cp ../../macosx-64-$JAVA_V.tar.gz .
            tar xzf ./macosx-64-$JAVA_V.tar.gz
            rm macosx-64-$JAVA_V.tar.gz
        ;;

        *) ;;
    esac
)
mv clara-cre "$CLARA_HOME"

# Install coatjava.
tar xzf coatjava-$CLAS12_V.tar.gz
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

# Install grapes.
if [ ! -f grapes-$GRAPES_V.tar.gz ]; then
    wget https://clasweb.jlab.org/clas12offline/distribution/grapes/grapes-$GRAPES_V.tar.gz
fi
tar xzf grapes-$GRAPES_V.tar.gz
(
    mv grapes-$GRAPES_V "$CLARA_HOME"/plugins/grapes
    cp -rp "$CLARA_HOME"/plugins/grapes/bin/clara-grapes "$CLARA_HOME"/bin/.
    rm -f "$CLARA_HOME"/plugins/clas12/bin/clara-rec
    rm -f "$CLARA_HOME"/plugins/clas12/README
    cp -rp "$CLARA_HOME"/plugins/clas12/etc/services/*.yaml "$CLARA_HOME"/plugins/clas12/config/.
    rm -rf "$CLARA_HOME"/plugins/clas12/etc/services
)

# Finish up.
chmod a+x "$CLARA_HOME"/bin/*
chmod -R a+rx $CLARA_HOME
