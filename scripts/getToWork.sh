#!/usr/bin/env bash

my_work_page="https://spglobal.visualstudio.com/_work"

startup_apps=("DominoApp" 
#    "VisualStudioApp"
    "Timing"
    "Firefox $my_work_page"
    "BoxApp" 
    "OutlookMailApp" 
    "CalendarApp" 
    "Slack")

for app in "${startup_apps[@]}"; do
    open -a $app
done

ping -c 1 CHODSDEV01 || open -a '/Applications/Cisco/Cisco AnyConnect Secure Mobility Client.app'

kinit
