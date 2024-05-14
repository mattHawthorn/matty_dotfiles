# math

tobase() { 
  local num="$1" base="$2" res="" sign=""
  [[ $num -lt 0 ]] && sign='-' && ((num *= -1))
  while [[ $num -gt 0 ]]; do
    res=$(( num % base ))$res
    ((num /= base))
  done
  echo "$sign${res:-0}"
}

binary() {
  tobase $1 2
}

gini-impurity() {
  awk '{sum += $1; sumsq += $1**2} END {print 1.0 - sumsq / sum**2}'
}

sum() {
  awk '{sum += $1} END {print sum}'
}
