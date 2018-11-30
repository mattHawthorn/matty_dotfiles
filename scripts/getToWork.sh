#!/usr/bin/env bash

my_work_page="https://spglobal.visualstudio.com/Products/_sprints/taskboard/Data\\ Science\\ B/"

startup_apps=(
    "Timing"
    "Firefox $my_work_page"
#    "DominoApp" 
#    "VisualStudioApp"
#    "BoxApp" 
#    "OutlookMailApp" 
#    "CalendarApp" 
    "Microsoft\\ Teams"
    "Microsoft\\ Outlook"
    "Slack")

for app in "${startup_apps[@]}"; do
    open -a $app
done

ping -c 1 CHODSDEV01 || open -a '/Applications/Cisco/Cisco AnyConnect Secure Mobility Client.app'

kinit
