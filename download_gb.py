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
default_batch_size = 100
default_comment_char = ''
#Functions
def log(handle, message):
	#print(message, end="",flush=True)
	handle.write(message)
	handle.flush()
	os.fsync(handle)

#Command Line Parsing 
command_line_parser = argparse.ArgumentParser(description=program_description)
command_line_parser.add_argument('input_file_path', metavar='ID_FILE_PATH', help='Path to a file containing a list of genbank identifiers, one per line.')
command_line_parser.add_argument('output_file_path', metavar='OUTPUT_FILE_PATH', help='Path to where the output will be stored in genbank (.gb) format.')
command_line_parser.add_argument('output_log_path', metavar='OUTPUT_LOG_PATH', help='Path to the runtime log file.')
command_line_parser.add_argument('--error_delay', metavar='SECONDS', action='store', type=int, default=default_error_delay, help='Seconds to wait after a failed attempt before trying again. Default: %d' % default_error_delay)
command_line_parser.add_argument('--batch_size', metavar='INTEGER', action='store', type=int, default=default_batch_size, help='Number of queries searched per submission. Default: %s' % default_batch_size)
command_line_parser.add_argument('--comment-char', metavar='CHAR',  action='store', default = default_comment_char, help='Character or string that indicates a line is a comment and should be ignored. Default: none')
arguments = command_line_parser.parse_args()

#Parse input file
with open(arguments.input_file_path, 'r') as input_file_handle:
	ids = [line.strip() for line in input_file_handle.readlines()]
	#remove lines with comments 
	if arguments.comment_char != '':
		ids = [line for line in ids if line.startswith(arguments.comment_char) == False]
	
#Download
success_count = 0
total_attempts = 0
failed_attempts = 0
total_input_count = len(ids)
with open(arguments.output_file_path, 'w') as output_file_handle:
	with open(arguments.output_log_path, 'w') as log_handle:
		while len(ids) > 0:
			query = ids[:arguments.batch_size]
			del ids[:arguments.batch_size]
			success = False
			attempts = 0
			log(log_handle, 'Downloading %d queries starting with "%s ..."' % (arguments.batch_size, query[0][:20]))
			while success == False:
				try:
					attempts += 1
					log(log_handle, "\tAttempt %d ... " % (attempts))
					result_handle = Entrez.efetch(db="nucleotide", id=query, rettype="gb", retmode="text")
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
				if attempts >= max_attempts:
					log(log_handle, 'Max attempts (%d) reached, skipping the following query:\n%s\n' % (max_attempts, query))
					break
		log(log_handle, "Download completed. %d of %d queries successfully processed. %d Errors encountered." % (success_count, total_input_count, failed_attempts))
