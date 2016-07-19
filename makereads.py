#! /arch/bin/python

###Imports / Variable Initilization##########################################################################################
import os, string, sys, time, copy, re, random
from optparse import *
from datetime import *
argList     = sys.argv #argumen list supplied by user
argNum      = len(argList) #the number of arguments supplied
debugLog    = ['***********DEBUG LOG***********\n'] #where all errors/anomalies are recorded; saved if the -d modifier is supplied
timeStamp = datetime.now().ctime().replace(' ','-').replace(':','-').replace('--','-')  #Ex: 'Mon-Jun-14-11-08-55-2010'
cwd         = os.getcwd()
progName, progVersion, progArgNum = ('makereads.py','1.01', 1)
progDescription =\
'''
Randomly generates reads to aid in the testing of alignment programs. Reads are made from randomly reading chunks from the input fasta sequence.
To simulate herterozygous/polyploid reads, supply multiple sequences in the input file. The script will make reads for each sequence, writing them all to the same file. 
'''
progUsage = 'python %s [options] <reference fasta file>' % progName
#############################################################################################################################

def errorExit(message=None,exitStatus=1):
    '''Version 1.0
    Is called when the script encounters a fatal error. Prints the debug log to standard out (usually the screen)'''
    
    if message:
        print '%s: Error: %s' % (progName, message)
    else:
        print progName +': Unknown error, printing debug log...'
        for line in debugLog: print line   #print debug log
    sys.exit(exitStatus)

def verbose(toPrint):
    if options.verbose:
        print toPrint,
        printLog.append(toPrint)

def parseFasta(filePath):
    headers = []
    seqs = []
    fileHandle = open(filePath, 'r')
    fileData = fileHandle.readlines() + ['>']   #the additional header line is there make to following for loop process the last sequence 
    fileHandle.close()
    currSeq = ''
    for line in fileData:
        if line[0] == '>':   #if the line is a fasta header
            headers.append(line[1:].strip() )   #the fisrt character is the '>' and the last is a newline '\n'
            seqs.append(list(currSeq))
            currSeq = ''
        else:
            currSeq += line.strip()
    return (headers[:-1], seqs[1:])


def saveFasta(filePath, headers, sequences):
    outHandle = open(filePath, 'w')
    if len(headers) != 0 and len(sequences) != 0:
        if len(headers) != len(sequences): errorExit('saveFastaFile: different number of headers and sequences')
        if type(headers) == str and type(sequences) == str:
            headers = [headers]
            sequences = [sequences]
        if type(sequences[0]) == list: sequences = [''.join(seq) for seq in sequences]
        for index in range(0,len(headers)):
            outHandle.write('>%s\n' % headers[index])
            if type(sequences[index]) == str: sequences[index] = [sequences[index]]  #if there is only one line of sequence for a given header, make it a one-item list for the next loop
            for seq in sequences[index]:
                outHandle.write(seq + '\n')
    outHandle.close()

def reverseCompliment(seq):
    conversionKey = {'A':'T','T':'A','G':'C','C':'G','R':'Y','Y':'R','M':'K','K':'M','S':'S','W':'W','H':'D','D':'H','B':'V','V':'B','N':'N','-':'-','~':'~'}
    outSeq = []
    for base in seq: outSeq.append(conversionKey[base.upper()])
    outSeq.reverse()
    return outSeq

def rangeCallback(option, opt_str, value, parser):
    '''Version: 1.0
    Callback function for interpreting range arguments from  a command line in conjunction with the python module OptParse'''
    value = []
    def floatable(str):
        try:
            float(str)
            return True
        except ValueError: return False
    for arg in parser.rargs:         
        if arg[:2] == "--" and len(arg) > 2: break   # stop on --foo like options             
        if arg[:1] == "-" and len(arg) > 1 and not floatable(arg): break   # stop on -a, but not on -3 or -3.0
        value.append(arg)
        break
    if len(value) == 0: errorExit("option '%s' requires an argument; none supplied." % option.dest)
    else:
        try: 
            Range = value[0].split('-')
            if len(Range) != 2: errorExit("option '%s' requires one argument, in the form of two numbers separated by a hyphen, such as 1.2-4.5; to only specify a maximum or minimum, omit the first or second number respectively, such as -4.5" % option.dest)
            if Range[0] == '': Range[0] = None
            else: Range[0] = float(Range[0])
            if Range[1] == '': Range[1] = None
            else: Range[1] = float(Range[1])
        except ValueError: errorExit("option '%s': cannot convert the argument '%s' to a number range; numerical values required." % (option.dest, value[0]))
        del parser.rargs[:len(value)]
        setattr(parser.values, option.dest, Range)

###Command Line Parser#######################################################################################################
cmndLineParser  = OptionParser(usage=progUsage, version="Version %s" % progVersion, description=progDescription)
cmndLineParser.add_option("-v", "--verbose",                action="store_true",    default=False,                                          help="Print progress updates and relevant statistics to the standard output. (Default: run silently)")
cmndLineParser.add_option("-p", "--paired-end-reads",       action="store_true",    default=False,                                          help="Simulate paired-end reads. (Default: generate individual reads)")
cmndLineParser.add_option("-l", "--read-length",            action="store",         default=100,      type="int",       metavar="INT",      help="Length of simulated reads. (Default: 100)")
cmndLineParser.add_option("-c", "--coverage",               action="store",         default=20,       type="int",       metavar="INT",      help="Average read coverage of the input sequence. Determins the number of reads generated.(Default: 20)")
cmndLineParser.add_option("-r", "--random-number-seed",     action="store",         default=None,     type="int",       metavar="INT",      help="Supply a seed to the random number generator to get a specific result. (Default: Use system time)")
cmndLineParser.add_option("-s", "--SNP-error-rate",         action="store",         default=0.01,     type="float",     metavar="FLOAT",    help="The rate at which single nucleotide polymorphisms are randomly inserted into read to simulate sequenceing error. (Default: .01)")
#NYI cmndLineParser.add_option("-d", "--DIP-error-rate",         action="store",         default=0.01,     type="float",     metavar="FLOAT",    help="The rate at which deletions/insertions are randomly inserted into read to simulate sequenceing error. (Default: .01)")
cmndLineParser.add_option("-i", "--insert-size",            action="callback",      default=[200,400],                 metavar='LOW HIGH', callback=rangeCallback,   dest='insert_size',       help="Specify the range of insert sizes for paired-end reads. Accepts a range of values.(Default: 200-400)")
(options, args) = cmndLineParser.parse_args(argList)
if len(args) == 1:
    cmndLineParser.print_help()
    sys.exit(0)
argNum = len(args) - 1   #counts the amount of arguments, negating the 'qualtofa' at the start of the command line
if argNum != progArgNum: errorExit('%s takes exactly %d argument(s); %d supplied' % (progName, progArgNum, argNum), 0)
inPath = args[-1] #The file path to the input file supplied by the user
outFilePath = os.path.join(cwd, '%s_%s_%s.fa' % (os.path.splitext(os.path.basename(inPath))[0], progName, timeStamp))
if options.random_number_seed == None: random.seed()
else: random.seed(options.random_number_seed)
if options.SNP_error_rate >= 1 or options.SNP_error_rate < 0: errorExit('The argument for option "-s/--SNP-error-rate" must be between 0 and 1')
#NYI if options.DIP_error_rate >= 1 or options.DIP_error_rate < 0: errorExit('The argument for option "-s/--DIP-error-rate" must be between 0 and 1')
#############################################################################################################################

def appySNPerrorRate(read, errorRate):
    nucleotides = ['A','G','C','T']
    while random.randint(1,int(1.0/errorRate)) == 1:
        SNPindex = random.randint(0, len(read) - 1)
        currentNucleotide = read[SNPindex].upper()
        possibleSNPs = copy.deepcopy(nucleotides)
        possibleSNPs.remove(currentNucleotide)
        read[SNPindex] = possibleSNPs[random.randint(0,2)]
        #read = ''.join((read[:SNPindex - 1], possibleSNPs[random.randint(0,2)], read[SNPindex + 1:]))
    return read

inHandle = open(inPath, 'r')
referenceHeaders, referenceSequences = parseFasta(inPath)
outReadHeaders, outReadSequences = [], []
for sequence in referenceSequences:
    sequenceLength = len(sequence)
    totalReadCount = sequenceLength * options.coverage / options.read_length
    if options.paired_end_reads: totalReadCount = totalReadCount / 2
    lastPossibleStart = sequenceLength - options.read_length
    for readCount in range(1, totalReadCount + 1):
        if options.paired_end_reads:
            insertSize = random.randint(*options.insert_size)
            lastPossibleStart = sequenceLength - (options.read_length * 2 + insertSize)
            outReadHeaders.append('read_%d_1' % readCount)
        else: outReadHeaders.append('read_%d' % readCount)
        start = random.randint(0,lastPossibleStart)
        read = sequence[start: start + options.read_length]
        read = appySNPerrorRate(read, options.SNP_error_rate)
        outReadSequences.append(read)
        if options.paired_end_reads:
            start += insertSize
            read = reverseCompliment(sequence[start: start + options.read_length])
            read = appySNPerrorRate(read,options.SNP_error_rate)
            outReadHeaders.append('read_%d_2' % readCount)
            outReadSequences.append(read)
saveFasta(outFilePath, outReadHeaders, outReadSequences)
