#Generic Imports
import os, sys, time
import argparse

#Specific Imports
from bioinformatic_functions import *
from Bio.Blast import NCBIXML

#Constants 
program_description = 'Converts the XML output of BLAST to the m8 format: query, subject, %id, alignment length, mismatches, gap openings, query start, query end, subject start, subject end, E value, bit score.'

#Parameter Defaults

#Command Line Parsing 
command_line_parser = argparse.ArgumentParser(description=program_description)
command_line_parser.add_argument('input_file_path', metavar='XML_FILE', help='Path to BLAST output file in XML format to be converted to the m8 format.')
command_line_parser.add_argument('output_file_path', metavar='OUTPUT', help='Path to output file.')
arguments = command_line_parser.parse_args()

#Convert file format
print(arguments)
with open(arguments.input_file_path, 'r') as input_handle:
	with open(arguments.output_file_path, 'w') as output_handle:
		for line in blast_xml_to_m8(input_handle):
			output_handle.write(line)