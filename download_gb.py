#Generic Imports
import os, sys, time
import argparse

#Specific Imports
from Bio import SeqIO
from Bio import Entrez

#Constants 
program_description = 'Downloads the full genbank records of a list of identifiers in batches.'
Entrez.email = "zacharyfoster1989@gmail.com"
max_attempts = 5

#Parameters
default_error_delay = 120
default_batch_size = 500
default_start = 1
default_end = 0

#Functions
def log(handle, message):
	print(message, end="",flush=True)
	handle.write(message)
	handle.flush()
	os.fsync(handle)

#Command Line Parsing 
command_line_parser = argparse.ArgumentParser(description=program_description)
command_line_parser.add_argument('input_file_path', metavar='ID_FILE_PATH', help='Path to a file containing a list of genbank identifiers, one per line.')
command_line_parser.add_argument('output_file_path', metavar='OUTPUT_FILE_PATH', help='Path to where the output will be stored in genbank (.gb) format.')
command_line_parser.add_argument('output_log_path', metavar='LOG', help='Path to the runtime log file.')
command_line_parser.add_argument('--error_delay', metavar='SECONDS', action='store', type=int, default=default_error_delay, help='Seconds to wait after a failed attempt before trying again. Default: %d' % default_error_delay)
command_line_parser.add_argument('--batch_size', metavar='INTEGER', action='store', type=int, default=default_batch_size, help='Number of queries searched per submission. Default: %s' % default_batch_size)
command_line_parser.add_argument('--start', metavar='INTEGER', action='store', type=int, default=default_start, help='The query number at which to start processing (inclusive). Default: %s' % default_start)
command_line_parser.add_argument('--end', metavar='INTEGER', action='store', type=int, default=default_end, help='The query number at which to stop processing (inclusive). Default: last record')
command_line_parser.add_argument('--append', action='store_true', default=False, help='Append to output file. Default: Create or overwrite')
arguments = command_line_parser.parse_args()

#Parse input file
with open(arguments.input_file_path, 'r') as input_file_handle:
	ids = [line.strip() for line in input_file_handle.readlines()]
	if len(ids[0].split('\t')) > 1:
		ids = [line.split('\t')[1].split('|')[1] for line in ids] #if in m8 blast format
	
#subset query if asked
total_input_count = len(ids)
if arguments.end != 0:
	ids = ids[arguments.start - 1: arguments.end]
else:
	ids = ids[arguments.start - 1:]
print(len(ids))
	
#Download
line_count = arguments.start
success_count = 0
total_attempts = 0
failed_attempts = 0
total_subset_count = 0
query_length = len(ids)
if arguments.append:
	write_type = 'a'
else:
	write_type = 'w'
with open(arguments.output_file_path, write_type) as output_file_handle:
	with open(arguments.output_log_path, write_type) as log_handle:
		while len(ids) > 0:
			query = ids[:arguments.batch_size]
			del ids[:arguments.batch_size]
			success = False
			attempts = 0
			log(log_handle, 'Downloading queries %d to %d (of %d) starting with "%s ..."' % (line_count, line_count + len(query) - 1, total_input_count, query[0][:20]))
			while success == False:
				try:
					attempts += 1
					log(log_handle, "\tAttempt %d ... " % (attempts))
					#result_handle = Entrez.efetch(db="nucleotide", id=query, rettype="gb", retmode="text")
					result_handle = Entrez.efetch(db="nucleotide", id=query, retmode="xml")
				except KeyboardInterrupt:
					raise
					sys.exit(0)
				except BaseException as exception:
					failed_attempts += 1
					log(log_handle, "ERROR:\n%s\n Waiting %d seconds.\n" % (exception, arguments.error_delay))
					time.sleep(arguments.error_delay)
				else:
					success_count += 1
					result = result_handle.read()
					output_file_handle.write(result)
					output_file_handle.flush()
					os.fsync(output_file_handle)
					success = True
					log(log_handle, "Complete\n")
					line_count += len(query)
				if attempts >= max_attempts:
					log(log_handle, 'Max attempts (%d) reached, skipping the following query:\n%s\n' % (max_attempts, query))
					line_count += len(query)
					break
		log(log_handle, "Download completed. %d of %d queries successfully processed. %d Errors encountered." % (success_count, total_subset_count, failed_attempts))