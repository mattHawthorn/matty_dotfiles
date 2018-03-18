#!/bin/bash
lines=$(dig +short $1);
read -r -a ip <<< "$lines";

#echo $lines
len=${#ip[@]}
len=$((len - 1))
#echo $len

if [ len=0 ]
 then
  ip=($lines)
  len=${#ip[@]}
  len=$((len - 1))
  #echo $len
fi

ip=${ip[$len]};
#echo $ip

lines=$(whois $ip | grep -iE ^country:)
read -r -a country <<< "$lines";
echo ${country[1]}
