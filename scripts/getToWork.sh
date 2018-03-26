#!/usr/bin/env bash

my_work_page="https://spgmi.visualstudio.com/_work"

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
