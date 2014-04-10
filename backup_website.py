#Change log
version = '0.0.1'
change_log = [('0.0.1',  'First version of the script')]

#Generic Imports
import os, sys, time
from subprocess import call

#Constants
port = 732
user = 'fosterz'
server = 'oomy.cgrb.oregonstate.edu'
mysql_user = 'PhytoUser'
mysql_password = '1nf3st4ns'
target_directory = '/home/local/USDA-ARS/fosterz/website_backups/grunwald_lab'
source_directory = '/data/www/grunwaldlab/drupal'
mysql_name = 'grunwald_Drupal'
remote_temporary_directory = '/tmp'

#Parameters
date = time.strftime("%Y-%m-%d")
epoch_time = str(time.time()).replace('.','-')
archive_name = 'grunwald_lab_website_backup'
mysqldump_result_file = '%s_dump.sql' % (os.path.join(remote_temporary_directory, mysql_name) 
target_path = os.path.join(target_directory, archive_name) + '/'

#Dump MySQL database
mysqldump_command = "ssh -p %d %s@%s 'mysqldump --user=%s --password=%s --result-file=%s %s'" %\
					 (port, user, server, mysql_user, mysql_password, mysqldump_result_file, mysql_name)
print(mysqldump_command)
mysqldump_return_code = os.system(mysqldump_command)
					 
#Copy the dumped database to the local computer
rsync_dump_command = "rsync -aczL --rsh='ssh -p %s' %s@%s:%s %s" % (port, user, server, mysqldump_result_file, target_path)
print(rsync_dump_command)
rsync_dump_return_code = os.system(rsync_dump_command)

#Copy the drupal directory to the local computer
rsync_drupal_command = "rsync -aczL --rsh='ssh -p %s' %s@%s:%s %s" % (port, user, server, source_directory, target_path)
print(rsync_drupal_command)
rsync_drupal_return_code = os.system(rsync_drupal_command)

