#Change log
version = '0.0.1'
change_log = [('0.0.1',  'First version of the script')]

#Constants 
program_description = 'Runs all of the shell commands, one per line, in a text file in parallel using a SGE array job. Version %s' % (version)

#Generic Imports
import os, sys, time
import argparse

#Specific Imports
from subprocess import Popen, PIPE, STDOUT

#Parameters
default_free_memory = '10G'
default_output_suffix = '_sge_parallel_output'
default_error_suffix = '_sge_parallel_output'

#Functions

#Command Line Parsing 
command_line_parser = argparse.ArgumentParser(description=program_description, prefix_chars = "--")
command_line_parser.add_argument('input_file_path', metavar='INPUT_FILE_PATH', help='Path to a file containing commands to run.')
command_line_parser.add_argument('--output', metavar='DIRECTORY_PATH',  default= None, help='A directory to store the standard output of the jobs. Default: Save in a new folder with a name derived from the input file plus "%s"' % default_output_suffix)
command_line_parser.add_argument('--error', metavar='DIRECTORY_PATH', default = None, help='A directory to store the standard error of the jobs.Default: Save in a new folder with a name derived from the input file plus "%s"' % default_error_suffix)
command_line_parser.add_argument('--mem_free', metavar='STRING', default =  default_free_memory, help='See qsub documentation ("man qsub"). Default: %s' % default_free_memory)
arguments = command_line_parser.parse_args()
if arguments.error == None:
	arguments.error = arguments.input_file_path + default_error_suffix
if arguments.output == None:
	arguments.output = arguments.input_file_path + default_output_suffix

#Count input lines 
with open(arguments.input_file_path, 'r') as handle:
	commands = handle.readlines()
input_length = len(commands)
	

#Make bash submission script
qsub_input = r"""#!/bin/bash
#$ -cwd
#$ -S /bin/bash
#$ -N bt2pe
#$ -o """ + arguments.output + r""" 
#$ -e """ + arguments.error + r""" 
#$ -l mem_free=""" + arguments.mem_free + r"""
#$ -V
#$ -t 1-""" + str(input_length) + r""":1
COMMAND=`head -n $SGE_TASK_ID """ + arguments.input_file_path + r""" | tail -1 `
$COMMAND
"""

#Submit Jobs 
p = Popen(['qsub'], stdout=PIPE, stdin=PIPE, stderr=PIPE)
stdout_data = p.communicate(input=qsub_input)[0]
print stdout_data

