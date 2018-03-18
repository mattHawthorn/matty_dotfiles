#!/usr/bin/env bash

# show all files in finder file system explorer
defaults write com.apple.finder AppleShowAllFiles YES

# set keyboard shortcuts for window services
defaults write pbs '{
    NSServicesStatus =     {
        "(null) - Open Terminal - runWorkflowAsService" =         {
            "key_equivalent" = "@~t";
        };
        "(null) - Run_iTerm - runWorkflowAsService" =         {
            "key_equivalent" = "@~y";
        };
        "(null) - WindowDown - runWorkflowAsService" =         {
            "key_equivalent" = "@~$k";
        };
        "(null) - WindowDownLeft - runWorkflowAsService" =         {
            "key_equivalent" = "@~$j";
        };
        "(null) - WindowDownRight - runWorkflowAsService" =         {
            "key_equivalent" = "@~$l";
        };
        "(null) - WindowFull - runWorkflowAsService" =         {
            "key_equivalent" = "@~$i";
        };
        "(null) - WindowLeft - runWorkflowAsService" =         {
            "key_equivalent" = "@~$u";
        };
        "(null) - WindowRight - runWorkflowAsService" =         {
            "key_equivalent" = "@~$o";
        };
        "(null) - WindowUp - runWorkflowAsService" =         {
            "key_equivalent" = "@~$8";
        };
        "(null) - WindowUpLeft - runWorkflowAsService" =         {
            "key_equivalent" = "@~$7";
        };
        "(null) - WindowUpRight - runWorkflowAsService" =         {
            "key_equivalent" = "@~$9";
        };
    };
}'
