# math

tobase() { 
  local num="$1" base="$2" res="" sign=""
  [[ $num -lt 0 ]] && sign='-' && ((num *= -1))
  while [[ $num -gt 0 ]]; do
    res=$(( num % base ))$res
    ((num /= base))
  done
  echo "$sign$res"
}

binary() {
  tobase $1 2
}

