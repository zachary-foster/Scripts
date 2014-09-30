#Generic Imports
import os, sys, time

#Constants
port = 732
user = 'fosterz'
server = 'oomy.cgrb.oregonstate.edu'
mysql_user = 'PhytoUser'
mysql_password = '1nf3st4ns'
target_directory = '/home/local/USDA-ARS/fosterz/website_backups/grunwald_lab'
source_directory = '/data/www/grunwaldlab'
drupal_directory = 'drupal-7.16'
mysql_name = 'grunwald_Drupal'
compressed_file_name = 'drupal.tar.gz'
remote_temporary_directory = '/export/grunwald_lab_backup'
log_path = '/home/local/USDA-ARS/fosterz/website_backups/grunwald_lab/backup_log.txt'
archive_name = 'most_recent_backup'
number_of_backups_to_keep = 10

#make time stamp
date = time.strftime("%Y-%m-%d")
epoch_time = str(time.time()).replace('.','-')
time_stamp = '%s_%s' % (epoch_time, date)

#Parameters
mysqldump_result_file = '%s_dump.sql' % (os.path.join(remote_temporary_directory, mysql_name))
target_path = os.path.join(target_directory, archive_name)
mysqldump_result_file = '%s_dump.sql' % (os.path.join(remote_temporary_directory, mysql_name))
compressed_file_path = os.path.join(remote_temporary_directory, compressed_file_name)
target_path = os.path.join(target_directory, archive_name)
archive_path = os.path.join(target_directory, 'grunwald_lab_website_backup_%s.tar.gz' % time_stamp)


