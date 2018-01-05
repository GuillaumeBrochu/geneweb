@echo off
title GeneWeb 6-08-GB
echo Geneweb ...
cd bases
start /b "gwd - GeneWeb" /min ..\gw\gwd -hd ..\gw
start /b "gwsetup - GeneWeb setup" /min ..\gw\gwsetup -lang en -gd ..\gw
start ..\START.htm
