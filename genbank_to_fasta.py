#Generic Imports
import os, sys, time
import argparse

#Specific Imports
from Bio import SeqIO

#Constants 
program_description = 'Takes a genbank file(*.gb) and converts it to a fasta file with the taxonomy, organism name, and genbank id in the header.'

#Parameter Defaults

#Command Line Parsing 
command_line_parser = argparse.ArgumentParser(description=program_description)
command_line_parser.add_argument('input_file_path', metavar='INPUT', help='Path to input genbank (*.gb) file.')
command_line_parser.add_argument('output_file_path', metavar='OUTPUT', help='Path to output file')
arguments = command_line_parser.parse_args()

#Process
input_handle = SeqIO.parse(arguments.input_file_path, "genbank")
with open(arguments.output_file_path, 'w') as output_handle:
	for record in input_handle:
		sequence = str(record.seq)
		id = record.name
		gi = record.annotations['gi']
		binomal_name = record.annotations['organism']
		taxonomy = record.annotations['taxonomy']
		if 'Stramenopiles' in taxonomy:
			fasta_header = '>' + '|'.join(taxonomy + [binomal_name, gi])
			fasta_header = fasta_header.replace(' ', '_')
			chars_written = output_handle.write(fasta_header + '\n')
			chars_written = output_handle.write(sequence + '\n')
