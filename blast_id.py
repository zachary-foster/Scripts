#imports
import sys, os, time
from Bio.Blast import NCBIWWW
from Bio.Blast import NCBIXML
from Bio import SeqIO


#constants
minimum_argument_number = 3
maximum_argument_number = 3
output_format = "XML"
max_attempts = 5


#Parameters
delay_time = 120
hit_list_size = 10
input_format = "fasta"
queries_per_blast = 10


#Command line parseing
arguments = sys.argv[1:]
if len(arguments) > maximum_argument_number or len(arguments) < minimum_argument_number:
	raise Exception("Incorrect number of arguments. Between %d and %d arguments required. %d received." % (minimum_argument_number, maximum_argument_number, len(arguments)))
query_file_path, output_file_path, log_output_path = arguments

def blast_xml_to_m8(result):
	for query_result in NCBIXML.parse(result):
		for hit in query_result.alignments:
			for hsp in hit.hsps:
				percent_id = (hsp.identities / hsp.align_length) * 100
				mismatches = hsp.align_length - hsp.identities
				line = [query_result.query, hit.hit_id, percent_id, hsp.align_length, mismatches, hsp.gaps, hsp.query_start, hsp.query_end, hsp.sbjct_start, hsp.sbjct_end, hsp.expect, hsp.bits]
				line = '\t'.join(line) + '\n'
				yield line


#Parse input file
if input_format == 'id':
	with open(query_file_path, 'r') as query_file_handle:
		query_data =[line.strip() for line in query_file_handle.readlines()]
if input_format == 'fasta':
	record_handle = SeqIO.parse(query_file_path, format=input_format)
	query_data = [record.format("fasta") for record in record_handle]


#Blast input data
success_count = 0
total_attempts = 0
failed_attempts = 0
with open(output_file_path, 'w') as output_file_handle:
	with open(log_output_path, 'w') as log:
		while len(query_data) > 0:
			query = '\n'.join(query_data[:queries_per_blast])
			del query_data[:queries_per_blast]
			success = False
			attempts = 0
			log.write('Blasting %d queries starting with "%s ..."' % (queries_per_blast, query.split('\n')[0][:20])) 
			while success == False:
				try:
					attempts += 1
					log.write("\tAttempt %d ... " % (attempts))
					result_handle = NCBIWWW.qblast("blastn", "nr", query, format_type=output_format, hitlist_size=hit_list_size, descriptions=hit_list_size, alignments=hit_list_size)
				except KeyboardInterrupt:
					raise
					sys.exit(0)
				except BaseException as exception:
					failed_attempts += 1
					log.write("ERROR:\n%s\ Waiting %d seconds.\n" % (exception, delay_time))
					time.sleep(delay_time)
				else:
					success_count += 1
					result = result_handle.read()
					output_file_handle.write(result)
					success = True
					log.write("Complete\n")
				if attempts >= max_attempts:
					log.write('Max attempts (%d) reached, skipping the following query:\n%s\n' % (max_attempts, query))
					break
