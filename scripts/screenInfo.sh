#!/bin/sh

DisplayListMac()
 {
    defaults read /Library/Preferences/com.apple.windowserver 
'DisplaySets' | awk 'BEGIN { aDepth=0; iDepth=0; aNum=0; iNum=0; dID="" 
}
    /\(/ {
            ++aDepth
            iNum=0
#            print "D:" aDepth
         }
    /\)/ {
            --aDepth
            ++aNum
#            print "D:" aDepth " N:" aNum
         }
    /\{/ {
            ++iDepth
#            print "I:" iDepth
            if (dID != "")
             {
                print dUnit ":" dX ":" dY ":" dW ":" dH
                dID=""
             }
         }
    /\}/ {
            --iDepth
            ++iNum
#            print "I:" iDepth " N:" iNum
         }
    /=/ {
#            print "K:" $1 ":" $3 ":"
            if (aNum == 0)
             {
                # Remove semicolon
                v=substr($3, 1, length($3) - 1)
                if ($1 == "Height" )
                    dH = v
                else if ($1 == "Width" )
                    dW = v
                else if ($1 == "OriginX" )
                    dX = v
                else if ($1 == "OriginY" )
                    dY = v
                else if ($1 == "DisplayID")
                    dID = v
                else if ($1 == "Active")
                    dAct = v
                else if ($1 == "Depth")
                    dDepth = v
                else if ($1 == "Unit")
                    dUnit = v
             }
        }
'
 }

for i in $(DisplayListMac); do
    u=${i%%:*}
    rest=${i#*:}
    x=${rest%%:*}
    rest=${rest#*:}
    y=${rest%%:*}
    rest=${rest#*:}
    w=${rest%%:*}
    rest=${rest#*:}
    h=${rest%%:*}

    echo "Display Unit: $u with height $h and width $w is positioned at 
($x, $y)"
done
