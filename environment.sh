#/bin/bash

function environment_main ()
{
    local path=$(dirname $(readlink -f $BASH_SOURCE));

    export BOARD="Digilent-Basys1";

    export ASYLUM_HOME="${path}";
    export ASYLUM_RTL_HOME="${ASYLUM_HOME}/rtl";
    export ASYLUM_INFRA_HOME="${ASYLUM_HOME}/infra";

    echo "BOARD              : ${BOARD}";
    echo "ASYLUM_HOME        : ${ASYLUM_HOME}";
    echo "ASYLUM_RTL_HOME    : ${ASYLUM_RTL_HOME}";
    echo "ASYLUM_INFRA_HOME  : ${ASYLUM_INFRA_HOME}";
}

environment_main $*;
