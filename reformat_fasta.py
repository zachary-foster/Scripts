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

class parse_phyto_id(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None):
        
        setattr(namespace, self.dest, values)

#Command Line Parsing 
command_line_parser = argparse.ArgumentParser(description=program_description, prefix_chars = "--")
ommand_line_parser.add_argument('--phyto-id', action=parse_phyto_id, help='Phytophthora ID format')
ommand_line_parser.add_argument('--phyto-db', metavar='STRING', default =  None, help='Phytophthora DB format')
ommand_line_parser.add_argument('--unite', metavar='STRING', default =  None, help='RDP/UNITE format')
ommand_line_parser.add_argument('--its1', metavar='STRING', default =  None, help='ITS1 format')
arguments = command_line_parser.parse_args()

