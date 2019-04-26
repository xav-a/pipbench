#!/bin/bash

ME=`basename "$0"`

if [ $# -eq 0 ]; then
    echo "Usage: $ME HANDLERS_DIR"
    exit 0
elif [ $# -ne 1 ]; 
    then echo "Illegal number of parameters"
    exit 1
fi


EXE_DIR="/tmp/""$$"
HANDLER_DIR=$1

NAMESPACE="$WSK_USER"/"$WSK_PKG"

HOST=172.17.0.1
PORT=9199

mkdir $EXE_DIR

echo Writing to $EXE_DIR
# List all generated packages
cut -d':' -f1 < packages_and_size.txt > $EXE_DIR/all-requirements.txt

echo Installing from requirements file

# Temporarily mount container:/tmp at EXE_DIR to create venv
docker run --rm -v "$EXE_DIR:/tmp" openwhisk/python2action \
    bash -c "cd tmp && virtualenv virtualenv && source virtualenv/bin/activate && \
    pip2 install -q --extra-index-url http://$HOST:$PORT/simple/ --trusted-host $HOST \
    -r all-requirements.txt"

echo -e "Done! Created virtualenv with pip2\n"

REGISTRY="./evaluation/handler_specs/handlers.txt"
echo "Creating or Truncating $REGISTRY"
truncate -s 0 $REGISTRY


HANDLER_NAMES=$(cd $HANDLER_DIR && ls -d */)

for handler in $HANDLER_NAMES; do

    # Remove trailing slash
    handler=$(echo ${handler%/})
    full_name="$EXE_DIR/""$handler" 
    
    echo $handler | tee -a $REGISTRY > /dev/null

    zip "$full_name"".zip" -j $HANDLER_DIR/$handler/* > /dev/null
    
    # Add venv/site-pacakges respective to each handler
    packages=$(cut -d: -f1 < $HANDLER_DIR/$handler/packages.txt \
                        | sed -e "s,^,virtualenv/lib/python2.7/site-packages/,")
    (cd $EXE_DIR && zip "$handler"".zip" -r virtualenv/bin/activate_this.py $packages) > /dev/null 

    #-i allows insecure
    wsk -i action create "$handler" --kind python:2 "$full_name"".zip" --web true
done

echo Removing $EXE_DIR
rm -r $EXE_DIR
echo -e "Done!!!\n"

echo "Retrieve action URL with 'wsk action get <FULL_ACTION_NAME> --url'"
echo -e "Example output would be 'https://<APIHOST>/api/v1/web/guest/default/hello'\n"
