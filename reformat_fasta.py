#Change log
version = '0.0.1'
change_log = {'0.0.1'   :   'First version of the script'}

#Constants 
program_description = 'Reformats the header of one or more fasta files and combines the result. ' +\
                      'The input files can be fo multiple different formats. Version %s' % (version)

#Generic Imports
import os, sys, time
import argparse

#Specific Imports

#Parameters

#Functions

#Command Line Parsing 
command_line_parser = argparse.ArgumentParser(description=program_description, prefix_chars = "--")
ommand_line_parser.add_argument('--phyto-id', metavar='STRING', default =  None, help='Default: none')
ommand_line_parser.add_argument('--phyto-db', metavar='STRING', default =  None, help='Default: none')
ommand_line_parser.add_argument('--rdp', metavar='STRING', default =  None, help='Default: none')
ommand_line_parser.add_argument('--its1', metavar='STRING', default =  None, help='Default: none')
arguments = command_line_parser.parse_args()

