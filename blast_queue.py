#imports
import sys, os, time, argparse
from Bio.Blast import NCBIWWW
from Bio.Blast import NCBIXML
from Bio import SeqIO

#constants
program_description =  "Blasts a list of queries in a file against as online database in batches. Saves result in XML format."
output_format = "XML"
max_attempts = 5

<<<<<<< HEAD

=======
>>>>>>> da6866d6a5d644de3a1600266393828be7196781
#Parameters
default_error_delay = 120
default_hit_list_size = 10
default_input_format = "fasta"
default_batch_size = 10

#Functions
def log(handle, message):
	print(message, end="",flush=True)
	handle.write(message)
	handle.flush()
	os.fsync()

#Command line parseing
command_line_parser = argparse.ArgumentParser(description=program_description)
<<<<<<< HEAD
command_line_parser.add_argument('query_file_path', metavar='QUERY', nargs=1, help='Path to file containing queries. Can be a fasta file or a list of accession numbers.')
command_line_parser.add_argument('output_file_path', metavar='OUTPUT', nargs=1, help='Path to the output file.')
command_line_parser.add_argument('output_log_path', metavar='LOG', nargs=1, help='Path to the runtime log file.')
command_line_parser.add_argument('--error_delay', metavar='SECONDS', action='store', type=int, nargs=1, default=default_error_delay, help='Seconds to wait after a failed attempt before trying again. Default: %d' % default_error_delay)
command_line_parser.add_argument('--hit_list_size', metavar='INTEGER', action='store', type=int, nargs=1, default=default_hit_list_size, help='Number of hits to return per query. Default: %d' % default_hit_list_size)
command_line_parser.add_argument('--batch_size', metavar='INTEGER', action='store', type=int, nargs=1, default=default_batch_size, help='Number of queries searched per submission. Default: %s' % default_batch_size)
command_line_parser.add_argument('--input_format', metavar='FILE_FORMAT', action='store', nargs=1, choices=['fasta', 'list'], default=default_hit_list_size, help='Format of input file. Default: %s' % default_input_format)
arguments = command_line_parser.parse_args()

def blast_xml_to_m8(result):
	for query_result in NCBIXML.parse(result):
		for hit in query_result.alignments:
			for hsp in hit.hsps:
				percent_id = (hsp.identities / hsp.align_length) * 100
				mismatches = hsp.align_length - hsp.identities
				line = [query_result.query, hit.hit_id, percent_id, hsp.align_length, mismatches, hsp.gaps, hsp.query_start, hsp.query_end, hsp.sbjct_start, hsp.sbjct_end, hsp.expect, hsp.bits]
				line = '\t'.join(line) + '\n'
				yield line
=======
command_line_parser.add_argument('query_file_path', metavar='QUERY', help='Path to file containing queries. Can be a fasta file or a list of accession numbers.')
command_line_parser.add_argument('output_file_path', metavar='OUTPUT', help='Path to the output file.')
command_line_parser.add_argument('output_log_path', metavar='LOG', help='Path to the runtime log file.')
command_line_parser.add_argument('--error_delay', metavar='SECONDS', action='store', type=int, default=default_error_delay, help='Seconds to wait after a failed attempt before trying again. Default: %d' % default_error_delay)
command_line_parser.add_argument('--hit_list_size', metavar='INTEGER', action='store', type=int, default=default_hit_list_size, help='Number of hits to return per query. Default: %d' % default_hit_list_size)
command_line_parser.add_argument('--batch_size', metavar='INTEGER', action='store', type=int, default=default_batch_size, help='Number of queries searched per submission. Default: %s' % default_batch_size)
command_line_parser.add_argument('--input_format', metavar='FILE_FORMAT', action='store', choices=['fasta', 'list'], default=default_hit_list_size, help='Format of input file. Default: %s' % default_input_format)
arguments = command_line_parser.parse_args()

>>>>>>> da6866d6a5d644de3a1600266393828be7196781


#Parse input file
if arguments.input_format == 'list':
	with open(arguments.query_file_path, 'r') as query_file_handle:
		query_data =[line.strip() for line in query_file_handle.readlines()]
if arguments.input_format == 'fasta':
	record_handle = SeqIO.parse(arguments.query_file_path, format=input_format)
	query_data = [record.format("fasta") for record in record_handle]


#Blast input data
success_count = 0
total_attempts = 0
failed_attempts = 0
<<<<<<< HEAD
=======
total_input_count = len(query_data)
>>>>>>> da6866d6a5d644de3a1600266393828be7196781
with open(arguments.output_file_path, 'w') as output_file_handle:
	with open(arguments.output_log_path, 'w') as log_handle:
		while len(query_data) > 0:
			query = '\n'.join(query_data[:arguments.batch_size])
			del query_data[:arguments.batch_size]
			success = False
			attempts = 0
			log(log_handle, 'Blasting %d queries starting with "%s ..."' % (arguments.batch_size, query.split('\n')[0][:20]))
			while success == False:
				try:
					attempts += 1
					log(log_handle, "\tAttempt %d ... " % (attempts))
					result_handle = NCBIWWW.qblast("blastn", "nr", query, format_type=arguments.output_format, hitlist_size=arguments.hit_list_size, descriptions=arguments.hit_list_size, alignments=arguments.hit_list_size)
				except KeyboardInterrupt:
					raise
					sys.exit(0)
				except BaseException as exception:
					failed_attempts += 1
<<<<<<< HEAD
					log(log_handle, "ERROR:\n%s\ Waiting %d seconds.\n" % (exception, arguments.error_delay))
=======
					log(log_handle, "ERROR:\n%s\n Waiting %d seconds.\n" % (exception, arguments.error_delay))
>>>>>>> da6866d6a5d644de3a1600266393828be7196781
					time.sleep(arguments.error_delay)
				else:
					success_count += 1
					result = result_handle.read()
					output_file_handle.write(result)
<<<<<<< HEAD
=======
					output_file_handle.flush()
					os.fsync()
>>>>>>> da6866d6a5d644de3a1600266393828be7196781
					success = True
					log(log_handle, "Complete\n")
				if attempts >= max_attempts:
					log(log_handle, 'Max attempts (%d) reached, skipping the following query:\n%s\n' % (max_attempts, query))
					break
<<<<<<< HEAD
=======
		log(log_handle, "Download completed. %d of %d queries successfully processed. %d Errors encountered." % (success_count, total_input_count, failed_attempts))
>>>>>>> da6866d6a5d644de3a1600266393828be7196781
