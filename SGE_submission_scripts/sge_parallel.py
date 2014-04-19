import sys, os
command_file = sys.argv[1]

with open(command_file, 'r') as handle:
	commands = handle.readlines()
	
from subprocess import Popen, PIPE, STDOUT

qsub_input = r"""#!/bin/bash
#$ -cwd
#$ -S /bin/bash
#$ -N bt2pe
#$ -o parallel_qsub_output 
#$ -e parallel_qsub_error 
#$ -l mem_free=10G
#$ -V
#$ -t 1-""" + str(len(commands)) + r""":1
COMMAND=`head -n $SGE_TASK_ID """ + command_file + r""" | tail -1 `
$COMMAND
"""

#os.system('qsub')
#os.system(qsub_input)

#p = Popen(['qsub'], stdout=PIPE, stdin=PIPE, stderr=PIPE)
#stdout_data = p.communicate(input=qsub_input)[0]
#print stdout_data
#print qsub_input 

qsub_submission_script_path = command_file + '_qsub_submission.sh'
with open(qsub_submission_script_path, 'w') as handle:
	handle.write(qsub_input)
os.system('qsub ' + qsub_submission_script_path)
