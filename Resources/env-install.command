#!/bin/bash

#  env-install.sh
#  table_generator_tool
#
#  Created by bjunjo on 2021/08/24.
#  

WORKSPACE=$1
GIT_ID=$2

echo $@

if [ -z ${WORKSPACE} ]; then
    echo -n "project workspace : "
    read WORKSPACE
fi

WORKSPACE=${WORKSPACE//"~"//${HOME}}

if [ ! -d ${WORKSPACE} ]; then
    echo "workspace not found!!"
    exit 1
fi

if [ -z ${GIT_ID} ]; then
    echo -n "git id : "
    read GIT_ID
fi


cd ${WORKSPACE}

if [[ ! -d ./table_generator_core ]]; then

    echo "==================================="
    echo "======== clone vtok project ======="
    echo "==================================="

    git clone --progress https://${GIR_ID}@github.com/golbeng/table_generator.git
    
    cd "${WORKSPACE}/table_generator_core/commands"
    ./env_install.command

else

    echo "==================================="
    echo "======== sync vtok project ======="
    echo "==================================="

    cd table_generator_core
    
    git pull

fi
