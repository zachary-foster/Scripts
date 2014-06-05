#Change log
change_log = [('0.0.1',		'First version of the script')]
version = change_log[-1][0]

#Constants 
program_description = 'Subsamples a FASTA reference database, taking into consideration the taxonomy encoded in the headers. Version %s' % (version)
ambiguous_indicators = ['uncultured', 'unknown', 'unidentified']
taxon_delimiter = ';'

#Generic Imports
import os, sys, time
import argparse

#Specific Imports
sys.path += ['/usr/lib/python3.2/dist_packages/biopython-1.63/']
from Bio import SeqIO
import random
from collections import *

#Parameters

#Functions
def write_fasta(record, handle):
	output = '>%s\n%s\n' % (record.id.strip(), record.seq)
	handle.write(output)
	
def get_taxonomy_level(taxonomy_string, level):
	taxonomy_elements = taxonomy_string.split(taxon_delimiter)
	taxonomy_levels, taxonomy_names = zip(*[taxon.split('__') for taxon in taxonomy_elements])
	taxonomy = [taxon_delimiter.join(taxonomy_elements[0:index]) for index in range(1, len(taxonomy_elements) + 1)]
	return taxon_delimiter.join(taxonomy_elements[:taxonomy_levels.index(level) + 1])

#Command Line Parsing 
command_line_parser = argparse.ArgumentParser(description=program_description, prefix_chars = "--")
command_line_parser.add_argument('fasta', type=argparse.FileType('r'))
command_line_parser.add_argument('taxon_data',type=argparse.FileType('r'))
command_line_parser.add_argument('--remove_taxa', nargs='+', default = [], help='Removes all sequences that have the specified taxon in their taxonomy string in the header. Can accept multiple arguments. For example "--remove_taxa o__Helotiales g__Pythium" would remove all sequences that are of the order Helotiales and all sequences of the genus Pythium.')
command_line_parser.add_argument('--require_taxa', nargs='+', default = [], help='Removes all sequences that do not have one of the specified taxa in their taxonomy string. Can accept multiple arguments. For example "--require_taxa p__Ascomycota g__Pythium" would remove all sequences that are not of the phylum Ascomycota or the genus Pythium.')
command_line_parser.add_argument('--require_levels', nargs='+', default = [], help='Removes all sequences that do not have the specified taxonomic level in their taxonomy string. Can accept multiple arguments. Can accept multiple arguments. For example "--require_levels p s" would remove all sequences that do not have both a phylum and species level designation.')
command_line_parser.add_argument('--max_count', nargs=2, default = None, help='Specifies the maximum number of sequences that represent each species. Example: g 10')
command_line_parser.add_argument('--min_count', nargs=2, default = None, help='Specifies the minimum number of sequences that represent each species. If the minimum is not present for a specific species then remove all sequences of that taxon. Example: g 10')
command_line_parser.add_argument('--output_file', type=argparse.FileType('w'), default=sys.stdout)

arguments = command_line_parser.parse_args()

#Load statistics
header = arguments.taxon_data.readline().strip().split('\t')
data = [line.strip().split('\t') for line in arguments.taxon_data.readlines()]
taxon_data = dict(zip(header, zip(*data)))


taxon_data['count'] = list(map(int, taxon_data['count']))
del data
#levels, taxa, counts = zip(*taxon_data)
#taxa = ['__'.join([l, t]) for l, t in zip(levels, taxa)]
#counts = map(int, counts)

#Determine which sequences to keep 
taxon_indexes_to_keep = {}
if arguments.max_count != None:
	filtering_level = arguments.max_count[0]
if arguments.min_count != None:
	filtering_level = arguments.min_count[0]
if arguments.max_count != None or arguments.min_count != None:
	if arguments.max_count[0] != arguments.min_count[0]:
		print('ERROR: --max_count and --min_count must have same level')
		sys.exit()
	for index in range(len(taxon_data['count'])):
		taxon, level, count = taxon_data['taxon'][index], taxon_data['level'][index], taxon_data['count'][index]
		if level == filtering_level:
			if arguments.max_count != None and count > int(arguments.max_count[1]):
				taxon_indexes_to_keep[taxon] = random.sample(range(count), int(arguments.max_count[1]))
			elif arguments.min_count != None and count < int(arguments.min_count[1]):
				taxon_indexes_to_keep[taxon] = []
			else:
				taxon_indexes_to_keep[taxon] = range(count)
	current_count = Counter()
#Subsample data
for record in SeqIO.parse(arguments.fasta, 'fasta'):
	keep_record = True
	header = record.description
	sequence = record.seq
	organism, genbank_id, taxonomy_string, alternate_id  = header.split('|')
	taxonomy_elements = taxonomy_string.split(taxon_delimiter)
	taxonomy_levels, taxonomy_names = zip(*[taxon.split('__') for taxon in taxonomy_elements])
	taxonomy = [taxon_delimiter.join(taxonomy_elements[0:index]) for index in range(1, len(taxonomy_elements) + 1)]
	
	#Optional filtering
	for taxon_to_remove in arguments.remove_taxa:
		if taxon_to_remove in taxonomy_elements:
			keep_record = False
	for taxon_to_require in arguments.require_taxa:
		if taxon_to_require not in taxonomy_elements:
			keep_record = False
	for level_to_require in arguments.require_levels:
		if level_to_require not in taxonomy_levels:
			keep_record = False
	
	#min/max subsampling 
	if arguments.max_count != None or arguments.min_count != None:
		if filtering_level not in taxonomy_levels:
			keep_record = False
		else:
			relevant_taxon = get_taxonomy_level(taxonomy_string, filtering_level)
			current_count.update([relevant_taxon])
			if current_count[relevant_taxon] - 1 not in taxon_indexes_to_keep[relevant_taxon]:
				keep_record = False
	
	#write record
	if keep_record:
		write_fasta(record, arguments.output_file)

