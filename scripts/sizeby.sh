
usage() {
echo "Show disk usage (or apparent size) of all files under a directory
Usage: sizeby [-e | -t | -s | -f [TYPEFUNC]] [-r] [-opt ...] [DIR]
Example:
    sizeby -aer -B 1 ~  # show apparent size of all files in the home dir recursively, grouped by extension, in units of bytes (-B 1 is an arg to du).
Options:
    
    -e          group files by extension
    -t          group files by file type (as output by the 'file' command)
    -s          group files by system file type (e.g. regular file, symlink, pipe, etc)
    -f TYPEFUNC group files by the output of the function TYPEFUNC
    
    --   
    
"



$LISTFUNC | {
    while read line; do
        
}
