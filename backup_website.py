#Change log
change_log = [('0.0.1',  'First version of the script'),
	('0.1.0', 'Added logging; now using scp and tar instead of rsync')]
version = change_log[-1][0]

#Generic Imports
import os, sys, time

#Specific imports
import subprocess
import logging
from backup_website_constants import *

#Parameters
ssh_command_prefix = ['ssh', '-p', str(port), '%s@%s' % (user, server)]

#logging settings
logging.basicConfig(filename=log_path, level=logging.INFO, format='%(asctime)s: %(message)s')

#Dump MySQL database
mysqldump_command = "'mysqldump --user=%s --password=%s --result-file=%s %s'" % \
	(mysql_user, mysql_password, mysqldump_result_file, mysql_name)
mysqldump_command = ' '.join(ssh_command_prefix + [mysqldump_command])
logging.info("Dumping mysql database:\n   %s" % str(mysqldump_command))
mysqldump_command_output = os.system(mysqldump_command)
logging.info("Dumping mysql database complete.")

#Make compressed copy of drupal site
compress_command = "'tar -cpz -f %s -C %s %s'" % (compressed_file_path, source_directory, drupal_directory)
compress_command = ' '.join(ssh_command_prefix + [compress_command])
logging.info('Compressing drupal site directory:\n   %s' % str(compress_command))
compress_command_output = os.system(compress_command)
logging.info("Compressing drupal site directory complete.")

#Make local target directory if it does not exist
#if os.path.exists(target_path) is False:
#	os.mkdir(target_path)

#delete local most recent backup
#shutil.rmtree(target_path)
#
def diehard_rsync(command, max_attempts=10, delay=30):
	"""Retry an rsync command until it completes successfully.

	Arguments:
	command -- the rsync command to try as a list
	max_attempts -- the maximum number of times the command will be attempted before giving up. (default: 10)
	delay -- the time to pause between attempts in seconds. (default: 30)
	"""
	attempts = 0
	logging.info("Attempting the following Rsync command at most %s times:\n   %s" % (max_attempts, ' '.join(command)))
	first_return_code = subprocess.call(command)
	attempts += 1
	if first_return_code != 0:
		if "--partial" not in command:
			command.append("--partial")
		while attempts < max_attempts:
			time.sleep(delay)
			logging.debug("Trying again...")
			return_code = subprocess.call(command)
			attempts += 1
			if return_code == 0:
				logging.debug("Attempt %s succeded." % attempts)
				return return_code
			else:
				logging.debug("Attempt %s failed with return code %d." % (attempts, return_code))
		else: #if too many attempts
			error_message = "The following Rsync command failed after %d attempts with return code %d:\n   %s" %\
				(attempts, return_code,' '.join(command))
			logging.error(error_message)
			raise RuntimeError(error_message)
	else:
		return first_return_code

#Copy the dumped database to the local computer
download_dump_command = ['rsync', '--rsh', "'ssh -p %d'" % port, '%s@%s:%s' % (user, server, mysqldump_result_file), target_path + '/']
#download_dump_command = ['scp', "-P", str(port), '%s@%s:%s' % (user, server, mysqldump_result_file), target_path + '/']
download_dump_command = ' '.join(download_dump_command)
download_dump_output = os.system(download_dump_command)
logging.info("Downloading mysql dump complete.")

#Copy the compressed drupal directory to the local computer
download_drupal_command = ['rsync', '--rsh', "'ssh -p %d'" % port, '%s@%s:%s' % (user, server, compressed_file_path), target_path + '/']
#download_drupal_command = ['scp', "-P", str(port), '%s@%s:%s' % (user, server, compressed_file_path), target_path + '/']
download_drupal_command = ' '.join(download_drupal_command)
logging.info("Downloading compressed drupal site:\n   %s" % str(download_drupal_command))
download_drupal_output = os.system(download_drupal_command)
logging.info("Downloading compressed drupal site complete.")


