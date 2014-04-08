#Change log
change_log = [('0.0.1',		'First version of the script')]
version = change_log[-1][0]

#Constants 
program_description = 'Reformats the header of one or more fasta files and combines the result. ' +\
                      'The input files can be fo multiple different formats. Version %s' % (version)
taxonomy_level_characters = ['k', 'p', 'o', 'c', 'f', 'g', 's']

#Generic Imports
import os, sys, time
import argparse

#Specific Imports
sys.path += ['/usr/lib/python3.2/dist_packages/biopython-1.63/']
from Bio import SeqIO

#Parameters

#Functions
def format_record_as_rdp(record, organism=None, genbank_id=None, alternate_id=None, taxonomy=None):
	def format_taxonomy(taxonomy):
		return ';'.join(['%s__%s' % (key, value) for key, value in taxonomy])
	if organism == None:
		organism = ''
	if genbank_id == None:
		genbank_id = ''
	if alternate_id == None:
		alternate_id = ''
	if taxonomy == None:
		taxonomy = {}
	record.id = '|'.join([organism, genbank_id, alternate_id, format_taxonomy(taxonomy)])
	record.id = record.id.replace(' ', '_')
	record.description = ''
	return record
	
def write_fasta(record, handle):
	output = '>%s\n%s\n' % (record.id.strip(), record.seq)
	handle.write(output)
	

#Command Line Parsing 
command_line_parser = argparse.ArgumentParser(description=program_description, prefix_chars = "--")
command_line_parser.add_argument('--output-file', nargs='?', type=argparse.FileType('w'), default=sys.stdout)
command_line_parser.add_argument('--phyto-id', nargs='+', metavar='STRING', default = [], help='Phytophthora ID format')
command_line_parser.add_argument('--phyto-db', nargs='+', metavar='STRING', default = [], help='Phytophthora DB format')
command_line_parser.add_argument('--unite', nargs='+', metavar='STRING', default = [], help='RDP/UNITE format')
command_line_parser.add_argument('--its1', nargs='+', metavar='STRING', default = [], help='ITS1 format')
command_line_parser.add_argument('--gb2fa', nargs='+', metavar='STRING', default = [], help='genbank_to_fasta.py format')
arguments = command_line_parser.parse_args()

#Reformat Phytophthora ID files
for file_path in arguments.phyto_id:
	for record in SeqIO.parse(file_path, 'fasta'):
		genbank_id, organism = record.description.split('|')
		record = format_record_as_rdp(record, organism=organism, genbank_id=genbank_id)
		write_fasta(record, arguments.output_file)

#Reformat Phytophthora DB files
for file_path in arguments.phyto_db:
	for record in SeqIO.parse(file_path, 'fasta'):
		alternate_id = record.description.split(' ')[0]
		organism = ' '.join(record.description.split(' ')[1:])
		organism = organism.replace('(', ' ').replace(')', ' ').strip()
		record = format_record_as_rdp(record, organism=organism, alternate_id=alternate_id)
		write_fasta(record, arguments.output_file)
		
#Reformat UNITE files
for file_path in arguments.unite:
	for record in SeqIO.parse(file_path, 'fasta'):
		organism, genbank_id, alternate_id, seq_type, taxonomy = record.description.split('|')
		taxonomy = [(taxon[0], taxon[3:]) for taxon in taxonomy.strip(';').split(';')]
		record = format_record_as_rdp(record, organism=organism, genbank_id=genbank_id, alternate_id=alternate_id, taxonomy=taxonomy)
		write_fasta(record, arguments.output_file)

#Reformat ITS1 files
for file_path in arguments.its1:
	for record in SeqIO.parse(file_path, 'fasta'):
		genbank_id, organism, taxon_id, notes = record.description.split('|')
		genbank_id = genbank_id.split('_')[0]
		record = format_record_as_rdp(record, organism=organism, genbank_id=genbank_id)
		write_fasta(record, arguments.output_file)

#Reformat fasta taxonomy-formatted (made by genbank_to_fasta.py) files
for file_path in arguments.gb2fa:
	for record in SeqIO.parse(file_path, 'fasta'):
		info = record.description.split('|')
		genbank_id =  info.pop(-1)
		organism = info.pop(-1)
		taxonomy = zip(taxonomy_level_characters, info)
		record = format_record_as_rdp(record, organism=organism, genbank_id=genbank_id, taxonomy=taxonomy)
		write_fasta(record, arguments.output_file)


