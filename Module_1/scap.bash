#!/bin/bash

com="$@"
for file in `ls ./`; do
    $com ./$file
done

exit 0