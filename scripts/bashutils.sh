# bash introspection utils

fn_exists() {
    type $1 | grep -q "is a function"
}

assignfunc() {
    local oldname=$1
    local newname=$2
    # check if this is a thing we can call
    if type -p $oldname; then
        local def=$newname'() { '$oldname' $@; }'
        eval $def
    else
        echo "$oldname isn't callable"
    fi
}

