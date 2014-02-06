#!/bin/bash

# Calculates the hash from a password
# $1 = Password

from='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/='
to='!{#$%&}()*+,-./0123456789:;<=>?@ypltavkrezgmshubxncdijfqow[|]^_`~'
 
echo -n $1 | sha384sum | awk '{print $1}' | base64 -w 512 | tr $from $to | cut -c1-32

