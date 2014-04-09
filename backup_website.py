#Change log
version = '0.0.1'
change_log = [('0.0.1',  'First version of the script')]

#Constants 
program_description = 'The program description. Version %s' % (version)

#Generic Imports
import os, sys, time
import argparse

#Specific Imports

#Parameters

#Functions

#Command Line Parsing 
command_line_parser = argparse.ArgumentParser(description=program_description, prefix_chars = "--")
command_line_parser.add_argument('input_file_path', metavar='INPUT_FILE_PATH', help='Path to a file.')
command_line_parser.add_argument('--int', metavar='INTEGER', action='store', type=int, default= , help='Default:')
command_line_parser.add_argument('--bool', action='BOOLEAN', default = , help='')
command_line_parser.add_argument('--sting', metavar='STRING', default =  , help='Default: none')
arguments = command_line_parser.parse_args()

