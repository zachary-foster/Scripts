#Change log
version = '0.0.1'
change_log = [('0.0.1',  'First version of the script')]

#Generic imports
import os, sys, time
import argparse

#Specific imports
from backup_website_constants import *

#make time stamp
date = time.strftime("%Y-%m-%d")
epoch_time = str(time.time()).replace('.','-')
time_stamp = '%s_%s' % (epoch_time, date)

#tar the local backup and add time stamp to folder name
archive_path = '%s_%s.tar.gz' % (target_path, time_stamp)
tar_command = 'tar -zcf %s %s' % (archive_path, target_path)
os.system(tar_command)

#remove old backups if there are too many
backups = [os.path.join(target_directory, item) for item in os.listdir(target_directory) if item.endswith('.tar.gz')]
if len(backups) > number_of_backups_to_keep:
	backups.sort(reverse=True)
	number_to_delete = len(backups) - number_of_backups_to_keep
	backups_to_delete = backups[-number_to_delete:]
	for backup_path in backups_to_delete:
		rm_command = 'rm -f %s' % (backup_path)
		os.system(rm_command)
