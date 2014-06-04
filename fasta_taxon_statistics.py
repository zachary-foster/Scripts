#Change log
change_log = [('0.0.1',		'First version of the script')]
version = change_log[-1][0]

#Constants 
program_description = 'Calculates taxon-specific statistics from a FASTA file with taxonomy information in the header. Version %s' % (version)
taxon_delimiter = ';'
taxonomy_level_characters = ['k','d', 'p', 'c', 'o', 'f', 'g', 's']

#Generic Imports
import os, sys, time
import argparse

#Specific Imports
sys.path += ['/usr/lib/python3.2/dist_packages/biopython-1.63/']
from Bio import SeqIO
from collections import *
from functools import cmp_to_key

#Parameters

#Functions
def taxon_sort_function(a, b):
	a_level = a.split(taxon_delimiter)[-1].split('__')[0]
	b_level = b.split(taxon_delimiter)[-1].split('__')[0]
	if taxonomy_level_characters.index(a_level) > taxonomy_level_characters.index(b_level):
		return 1
	elif taxonomy_level_characters.index(a_level) < taxonomy_level_characters.index(b_level):
		return -1
	else:
		a_dict = dict([x.split('__') for x in a.split(taxon_delimiter)])
		b_dict = dict([x.split('__') for x in b.split(taxon_delimiter)])
		for level in taxonomy_level_characters:
			try:
				if a_dict[level] > b_dict[level]:
					return 1
				elif a_dict[level] < b_dict[level]:
					return -1
			except:
				continue
		return 0

#Command Line Parsing 
command_line_parser = argparse.ArgumentParser(description=program_description, prefix_chars = "--")
command_line_parser.add_argument('input', type=argparse.FileType('r'), default=sys.stdin)
command_line_parser.add_argument('--taxa_out', type=argparse.FileType('w'))
arguments = command_line_parser.parse_args()

#Calculate statistics
taxa_count = Counter()
taxa_children = defaultdict(lambda: set())
taxa_parents = defaultdict(lambda: set()) #should only contain one, but allows more
for record in SeqIO.parse(arguments.input, 'fasta'):

	#parse record information
	header = record.description
	sequence = record.seq
	alternate_id, organism, genbank_id, taxonomy  = header.split('|')
	
	#get taxonomy string for each taxon
	taxonomy_elements = taxonomy.split(taxon_delimiter)
	taxonomy = [taxon_delimiter.join(taxonomy_elements[0:index]) for index in range(1, len(taxonomy_elements) + 1)]
	
	#Count taxa
	taxa_count.update(taxonomy)
	
	#Store adjacency information
	for index in range(len(taxonomy) - 1):
		taxa_children[taxonomy[index]].update([taxonomy[index + 1]])
		taxa_parents[taxonomy[index + 1]].update([taxonomy[index]])

#Sort data 
taxa = list(taxa_count.keys())
taxa.sort(key=cmp_to_key(taxon_sort_function)) #slow due to cmp_to_key

#Write output file
level, name = zip(*[x.split(taxon_delimiter)[-1].split('__') for x in taxa])
count = [taxa_count[x] for x in taxa]
children = [';'.join(map(str, sorted([taxa.index(y) + 1 for y in taxa_children[x]]))) for x in taxa]
parents = [';'.join(map(str, sorted([taxa.index(y) + 1 for y in taxa_parents[x]]))) for x in taxa]
count = [taxa_count[x] for x in taxa]
identity = [str(x) for x in range(1, len(taxa) + 1)]
data = zip(identity, taxa, level, name, [str(x) for x in count], parents, children)
arguments.taxa_out.write('\t'.join(['id', 'taxon', 'level', 'name', 'count', 'parent', 'children']) + '\n')
for line in data:
	arguments.taxa_out.write('\t'.join(line) + '\n')
	
