#Generic Imports
import os, sys, time

#Constants
port = 732
user = 'fosterz'
server = 'oomy.cgrb.oregonstate.edu'
mysql_user = 'PhytoUser'
mysql_password = '1nf3st4ns'
target_directory = '/home/local/USDA-ARS/fosterz/website_backups/grunwald_lab'
source_directory = '/data/www/grunwaldlab/drupal'
mysql_name = 'grunwald_Drupal'
remote_temporary_directory = '/export/mysql_dump'
number_of_backups_to_keep = 10

#Parameters
archive_name = 'grunwald_lab_website_backup'
mysqldump_result_file = '%s_dump.sql' % (os.path.join(remote_temporary_directory, mysql_name))
target_path = os.path.join(target_directory, archive_name)

