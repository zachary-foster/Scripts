#Change log
version = '0.0.1'
change_log = [('0.0.1',  'First version of the script')]

#Imports
import os, sys, time
import argparse

#make time stamp
date = time.strftime("%Y-%m-%d")
epoch_time = str(time.time()).replace('.','-')
time_stamp = '%s_%s' % (date, epoch_time)

#copy the local backup and add time stamp

#compress local backup

#remove old backups if there are too many
