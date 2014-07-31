#Change log
change_log = [('0.0.1',  'First version of the script'),
	('0.1.0', 'added logging')]
version = change_log[-1][0]

#Generic imports
import os, sys, time
import argparse

#Specific imports
from backup_website_constants import *
import logging

#logging settings
logging.basicConfig(filename=log_path, level=logging.INFO, format='%(asctime)s: %(message)s')

#tar the local backup and add time stamp to folder name
tar_command = 'tar -zc -f %s -C %s %s' % (archive_path, target_directory, archive_name)
logging.info('Compressing most recent backup:\n   %s' % str(tar_command))
os.system(tar_command)
logging.info('Compressing most recent backup complete.')

#remove old backups if there are too many
backups = [os.path.join(target_directory, item) for item in os.listdir(target_directory) if item.endswith('.tar.gz')]
if len(backups) > number_of_backups_to_keep:
	backups.sort(reverse=True)
	number_to_delete = len(backups) - number_of_backups_to_keep
	backups_to_delete = backups[-number_to_delete:]
	logging.info('Removing the following old backups:\n   ' + '\n   '.join(backups_to_delete))
	for backup_path in backups_to_delete:
		rm_command = 'rm -f %s' % (backup_path)
		os.system(rm_command)
	logging.info('Removal of old backups complete.')
