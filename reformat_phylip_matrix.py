#Change log
change_log = [('0.0.1',		'First version of the script')]
version = change_log[-1][0]

#Constants 
program_description = 'Reformats a Phylip distance matrix by putting each row on a single line and optionally renaming rows using header information from a fasta file. Version %s' % (version)

#Generic Imports
import os, sys, time
import argparse

#Specific Imports
sys.path += ['/usr/lib/python3.2/dist_packages/biopython-1.63/']
from Bio import SeqIO
from collections import *

#Parameters

#Functions

#Command Line Parsing 
command_line_parser = argparse.ArgumentParser(description=program_description, prefix_chars = "--")
command_line_parser.add_argument('matrix', type=argparse.FileType('r'), default=sys.stdin)
command_line_parser.add_argument('output', type=argparse.FileType('w'))
command_line_parser.add_argument('--rename_with_fasta', type=argparse.FileType('r'), default=None, help='Rename rows using header information from a fasta file. Sequences must be in same order as matrix rows.')
arguments = command_line_parser.parse_args()


#Optionaly rename using fasta headers
if arguments.rename_with_fasta != None:
	fasta_parser = SeqIO.parse(arguments.rename_with_fasta, 'fasta')

arguments.matrix.readline()
arguments.matrix.readline()
arguments.matrix.readline()
row_buffer = arguments.matrix.readline().strip().split(' ')
for line in arguments.matrix.readlines():
	if line[0] != ' ': #if the start of a new row
		#Optionaly rename using fasta headers
		if arguments.rename_with_fasta != None:
			row_buffer[0] = next(fasta_parser).description
		#write row
		arguments.output.write('\t'.join(row_buffer) + '\n')
		#clear buffer
		row_buffer = []
	row_buffer += line.strip().split(' ')
#process last row
if arguments.rename_with_fasta != None:
	row_buffer[0] = next(fasta_parser).description
arguments.output.write('\t'.join(row_buffer) + '\n')		
