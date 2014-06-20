#Change log
change_log = [('0.0.1',		'First version of the script')]
version = change_log[-1][0]

#Constants 
program_description = "Renames multiple files with a fixed prefix and numbers. Ignores directories. "

#Generic Imports
import os, sys, time
import argparse

#Specific Imports

#Parameters

#Functions
def add_file_suffix(path, suffix):
	split_path = os.path.splitext(path) 
	return split_path[0] + suffix + split_path[1] 

def add_file_prefix(path, prefix):
	split_path = os.path.split(path) 
	return os.join(split_path[0],  prefix + split_path[1])


#Command Line Parsing 
command_line_parser = argparse.ArgumentParser(description=program_description, prefix_chars = "--")
command_line_parser.add_argument('input', nargs='+', help="Enter one or more file names or wildcard expression.")
command_line_parser.add_argument('--prefix', nargs='?', default='', help="Enter a prefix to use to rename files.")
command_line_parser.add_argument('--start', type=int, nargs=1, default=1, help="Count to start at. Default: 1")
command_line_parser.add_argument('--preview', action='store_true', default = False, help='Dont do anything, but print what files would be renamed')

arguments = command_line_parser.parse_args()



#implementaion
count = arguments.start
for file_name in arguments.input:
	if os.path.isfile(file_name):
		path, name = os.path.split(file_name) 
		name, ext =  os.path.splitext(name) 
		new_name = os.path.join(path, arguments.prefix + str(count) + ext)
		if arguments.preview:
			print '%s --> %s' % (file_name, new_name)
		else:
			os.rename(file_name, new_name)
		count += 1
