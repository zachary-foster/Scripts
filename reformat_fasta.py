#Change log
change_log = [('0.0.1',		'First version of the script'),
			  ('0.0.2',		'Added RDP parsing; changed order of header information')]
version = change_log[-1][0]

#Constants 
program_description = 'Reformats the header of one or more fasta files to a consisntent format and combines the result. ' +\
                      'The input files can be fo multiple different formats. Version %s' % (version)
taxonomy_level_characters = ['k', 'd', 'p', 'c', 'o', 'f', 'g', 's']

#Generic Imports
import os, sys, time
import argparse

#Specific Imports
sys.path += ['/usr/lib/python3.2/dist_packages/biopython-1.63/']
from Bio import SeqIO

#Parameters

#Functions
def format_record(record, organism=None, genbank_id=None, alternate_id=None, taxonomy=None):
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
	record.id = '|'.join([alternate_id, organism, genbank_id, format_taxonomy(taxonomy)])
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
command_line_parser.add_argument('--unite', nargs='+', metavar='STRING', default = [], help='UNITE format')
command_line_parser.add_argument('--its1', nargs='+', metavar='STRING', default = [], help='ITS1 format')
command_line_parser.add_argument('--gb2fa', nargs='+', metavar='STRING', default = [], help='genbank_to_fasta.py format')
command_line_parser.add_argument('--rdp', nargs='+', metavar='STRING', default = [], help='RDP format')
command_line_parser.add_argument('--add_org_to_tax', action='store_true', default = False, help='Add the species/genus information in the header to the taxonomy if present. Note: this might not work depending on formatting.')
arguments = command_line_parser.parse_args()

#Reformat Phytophthora ID files
for file_path in arguments.phyto_id:
	for record in SeqIO.parse(file_path, 'fasta'):
		genbank_id, organism = record.description.split('|')
		record = format_record(record, organism=organism, genbank_id=genbank_id)
		write_fasta(record, arguments.output_file)

#Reformat Phytophthora DB files
for file_path in arguments.phyto_db:
	for record in SeqIO.parse(file_path, 'fasta'):
		alternate_id = record.description.split(' ')[0]
		organism = ' '.join(record.description.split(' ')[1:])
		organism = organism.replace('(', ' ').replace(')', ' ').strip()
		record = format_record(record, organism=organism, alternate_id=alternate_id)
		write_fasta(record, arguments.output_file)
		
#Reformat UNITE files
for file_path in arguments.unite:
	for record in SeqIO.parse(file_path, 'fasta'):
		organism, genbank_id, alternate_id, seq_type, taxonomy = record.description.split('|')
		taxonomy = [(taxon[0], taxon[3:]) for taxon in taxonomy.strip(';').split(';')]
		record = format_record(record, organism=organism, genbank_id=genbank_id, alternate_id=alternate_id, taxonomy=taxonomy)
		write_fasta(record, arguments.output_file)

#Reformat ITS1 files
for file_path in arguments.its1:
	for record in SeqIO.parse(file_path, 'fasta'):
		genbank_id, organism, taxon_id, notes = record.description.split('|')
		genbank_id = genbank_id.split('_')[0]
		record = format_record(record, organism=organism, genbank_id=genbank_id)
		write_fasta(record, arguments.output_file)

#Reformat fasta taxonomy-formatted (made by genbank_to_fasta.py) files
for file_path in arguments.gb2fa:
	for record in SeqIO.parse(file_path, 'fasta'):
		info = record.description.split('|')
		genbank_id =  info.pop(-1)
		organism = info.pop(-1)
		taxonomy = zip(taxonomy_level_characters, info)
		record = format_record(record, organism=organism, genbank_id=genbank_id, taxonomy=taxonomy)
		write_fasta(record, arguments.output_file)
		
#Reformat RDP 
taxonomy_correspondance = {'rootrank': 'k', 'domain':'d', 'phylum':'p', 'class':'c', 'order':'o', 'family':'f', 'genus':'g'}
for file_path in arguments.rdp:
	for record in SeqIO.parse(file_path, 'fasta'):
		identity, taxonomy = record.description.split('\t')
		identity = identity.split(';')[0].split(' ') # a list
		alternate_id = identity.pop(0)
		organism = ' '.join(identity)
		taxonomy = taxonomy.strip('Lineage=Root;rootrank;')
		taxonomy = taxonomy.split(';')
		new_taxonomy = []
		for taxon, level in zip([taxonomy[i] for i in range(0,len(taxonomy), 2)], [taxonomy[i] for i in range(1,len(taxonomy), 2)]):
			new_taxonomy.append([taxonomy_correspondance[level],taxon])
		#Optionaly add organism information to taxonomy
		if arguments.add_org_to_tax and organism.split(' ')[0].lower() not in ['uncultured', 'unknown', 'unidentified']:
			levels_present = zip(*new_taxonomy)[0]
			#add genus if not present
			if 'g' not in levels_present:
				new_taxonomy.append(['g', organism.split(' ')[0]])
			#add species if not present
			if 's' not in levels_present and len(organism.split(' ')) > 1:
				new_taxonomy.append(['s', '-'.join(organism.split(' ')[1:])])
		record = format_record(record, organism=organism, alternate_id=alternate_id, taxonomy=new_taxonomy)
		write_fasta(record, arguments.output_file)



