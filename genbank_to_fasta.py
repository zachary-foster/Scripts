<<<<<<< HEAD
#This script takes a genbank file(*.gb) and converts it to a fasta file with the taxonomy, organism name, and genbank id in the header. 
#	Argument 1: path to input gb file
#	Argument 1: path to output file


import sys, os 
from Bio import SeqIO

arguments = sys.argv[1:]
if len(arguments) != 2:
	raise Exception('Incorrect number of arguments')
input_file_path, output_file_path = arguments

#input_file_path = "C:\\Users\\Zachary Foster\\Repositories\\Analysis\\stamenopile_database\\full_refernece_data.txt"
#output_file_path = "C:\\Users\\Zachary Foster\\Repositories\\Analysis\\stamenopile_database\\stramenopile_blast_reference_database.fasta"


input_handle = SeqIO.parse(input_file_path, "genbank")


with open(output_file_path, 'w') as output_handle:
=======
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
>>>>>>> da6866d6a5d644de3a1600266393828be7196781
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
