#Change log
change_log = [('0.0.1',		'First version of the script')]
version = change_log[-1][0]

#Constants 

program_description = 'Calculates taxon-specific statistics from a FASTA file with taxonomy information in the header. Version %s' % (version)

#Generic Imports
import os, sys, time
import argparse

#Specific Imports
sys.path += ['/usr/lib/python3.2/dist_packages/biopython-1.63/']
from Bio import SeqIO

#Parameters

#Functions	

#Command Line Parsing 
command_line_parser = argparse.ArgumentParser(description=program_description, prefix_chars = "--")
command_line_parser.add_argument('input', type=argparse.FileType('r'), default=sys.stdin)
command_line_parser.add_argument('--taxa_out', type=argparse.FileType('w'))
arguments = command_line_parser.parse_args()

#Calculate statistics
taxa_data = {'taxon':[], 'count':[]}

for record in SeqIO.parse(arguments.input, 'fasta'):
	header = record.description
	sequence = record.seq
	alternate_id, organism, genbank_id, taxonomy  = header.split('|')
	taxonomy = taxonomy.split(';')
	for taxon in taxonomy: 
		try:
			index = taxa_data['taxon'].index(taxon)
		except ValueError: #if not yet encountered
			taxa_data['taxon'].append(taxon)
			taxa_data['count'].append(0)
			index = len(taxa_data['taxon']) - 1
		taxa_data['count'][index] += 1
		
#Write output file
arguments.taxa_out.write('\t'.join(['level','taxon','count']) + '\n')
for index in range(0, len(taxa_data['taxon'])):
	arguments.taxa_out.write('\t'.join(taxa_data['taxon'][index].split('__') + [str(taxa_data['count'][index])]) + '\n')
	
