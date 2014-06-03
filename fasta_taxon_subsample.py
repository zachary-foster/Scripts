#Change log
change_log = [('0.0.1',		'First version of the script')]
version = change_log[-1][0]

#Constants 
program_description = 'Subsamples a FASTA reference database, taking into consideration the taxonomy encoded in the headers. Version %s' % (version)

#Generic Imports
import os, sys, time
import argparse

#Specific Imports
sys.path += ['/usr/lib/python3.2/dist_packages/biopython-1.63/']
from Bio import SeqIO
import random

#Parameters

#Functions
def write_fasta(record, handle):
	output = '>%s\n%s\n' % (record.id.strip(), record.seq)
	handle.write(output)

#Command Line Parsing 
command_line_parser = argparse.ArgumentParser(description=program_description, prefix_chars = "--")
command_line_parser.add_argument('fasta', type=argparse.FileType('r'))
command_line_parser.add_argument('taxon_data',type=argparse.FileType('r'))
command_line_parser.add_argument('--remove_taxa', nargs='+', metavar='STRING', default = [], help='Removes all sequences that have the specified taxon in their taxonomy string in the header. Can accept multiple arguments. For example "--remove_taxa o__Helotiales g__Pythium" would remove all sequences that are of the order Helotiales and all sequences of the genus Pythium.')
command_line_parser.add_argument('--require_taxa', nargs='+', metavar='STRING', default = [], help='Removes all sequences that do not have one of the specified taxa in their taxonomy string. Can accept multiple arguments. For example "--require_taxa p__Ascomycota g__Pythium" would remove all sequences that are not of the phylum Ascomycota or the genus Pythium.')
command_line_parser.add_argument('--require_levels', nargs='+', metavar='STRING', default = [], help='Removes all sequences that do not have the specified taxonomic level in their taxonomy string. Can accept multiple arguments. Can accept multiple arguments. For example "--require_levels p s" would remove all sequences that do not have both a phylum and species level designation.')
command_line_parser.add_argument('--max_count', type=int, metavar='INT', default = [], help='Specifies the maximum number of sequences that represent each species')
command_line_parser.add_argument('--min_count', type=int, metavar='INT', default = [], help='Specifies the minimum number of sequences that represent each species. If the minimum is not present for a specific species then remove all sequences of that taxon.')
command_line_parser.add_argument('--output_file', type=argparse.FileType('w'), default=sys.stdout)

arguments = command_line_parser.parse_args()

#Load statistics
header = arguments.taxon_data.readline() 
taxon_data = [line.strip().split('\t') for line in arguments.taxon_data.readlines()]
levels, taxa, counts = zip(*taxon_data)
taxa = ['__'.join([l, t]) for l, t in zip(levels, taxa)]
counts = map(int, counts)

#Determine which sequences to keep 
taxon_indexes_to_keep = []
for level, taxon, count in taxon_data:
	if int(count) > arguments.max_count:
		taxon_indexes_to_keep.append(random.sample(range(int(count)), arguments.max_count))
	elif int(count) < arguments.min_count:
		taxon_indexes_to_keep.append([])
	else:
		taxon_indexes_to_keep.append(range(int(count)))
print(len(taxon_indexes_to_keep))
print(len(taxon_data))

#Subsample data
current_count = [-1]*len(taxa)

for record in SeqIO.parse(arguments.fasta, 'fasta'):
	keep_record = True
	header = record.description
	sequence = record.seq
	alternate_id, organism, genbank_id, taxonomy  = header.split('|')
	taxonomy = taxonomy.split(';')
	record_levels = [taxon.split('__')[0] for taxon in taxonomy]
	for taxon in taxonomy: 
		current_count[taxa.index(taxon)] += 1
	leaf_current_count = current_count[taxa.index(taxonomy[-1])]
	
	for taxon_to_remove in arguments.remove_taxa:
		if taxon_to_remove in taxonomy:
			keep_record = False
	for taxon_to_require in arguments.require_taxa:
		if taxon_to_require not in taxonomy:
			keep_record = False
	for level_to_require in arguments.require_levels:
		if level_to_require not in record_levels:
			keep_record = False
	try:
		if leaf_current_count not in taxon_indexes_to_keep[taxa.index(taxonomy[-1])]:
			keep_record = False
	except:
		print(len(taxa))
		break
	if keep_record:
		write_fasta(record, arguments.output_file)
		
