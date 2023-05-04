_anyq() { 
  local flavor="$1"; shift
  local load=load
  [ $flavor == yaml ] && load=safe_load
  python -c "import $flavor, sys, json; json.dump($flavor.$load(sys.stdin), sys.stdout)" | jq "$@"
}

# jq for yaml
yq() { _anyq yaml "$@"; }

# jq for toml
tq() { _anyq toml "$@"; }
