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
