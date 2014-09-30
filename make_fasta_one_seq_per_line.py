#Change log
change_log = [('0.0.1',		'First version of the script')]
version = change_log[-1][0]

#Constants 
program_description = 'Reformats a fasta file such that all the sequence is on one line. Version %s' % (version)

#Generic Imports
import os, sys, time
import argparse

#Specific Imports
sys.path += ['/usr/lib/python3.2/dist_packages/biopython-1.63/']
from Bio import SeqIO

#Parameters

#Functions
def write_fasta(record, handle):
	output = '>%s\n%s\n' % (record.description.strip(), record.seq)
	handle.write(output)

#Command Line Parsing 
command_line_parser = argparse.ArgumentParser(description=program_description)
command_line_parser.add_argument('input', type=argparse.FileType('r'), default=sys.stdin, help='A FASTA file or standard input.')
command_line_parser.add_argument('output', type=argparse.FileType('w'), default=sys.stdout, help='A FASTA file or standard output.')
arguments = command_line_parser.parse_args()

#Implementation
for record in SeqIO.parse(arguments.input, 'fasta'):
	write_fasta(record, arguments.output)
