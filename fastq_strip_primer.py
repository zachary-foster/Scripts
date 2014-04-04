#!/usr/bin/python
# Like fastq_strip_barcode_relabel except:
#	relabels with barcode label instead of barcode sequence.
# Expect seq = <barcode><primer><gene>
# Allow 2 mismatches with primer
# Allow 0 mismatches with barcode
# Strips primer & barcode, adds barcode label to seq label.

#Modified from fastq_strip_barcode_relabel2.py from the UPARSE set of tools

import sys, os
import fasta
import fastq
import primer

MAX_PRIMER_MISMATCHES = 3

FileName = sys.argv[1]
Primer = sys.argv[2]
LabelPrefix = sys.argv[3]

SeqCount = 0
OutCount = 0
PrimerMismatchCount = 0

PL = len(Primer)

def MatchesPrimer(Seq, Primer):
	return primer.MatchPrefix(Seq, Primer)
	
def OnRec(Label, Seq, Qual):
	global PL, LabelPrefix, Barcode, SeqCount, OutCount, PrimerMismatchCount

	SeqCount += 1
	BarcodeLabel = os.path.basename(FileName).split('-')[-1].split('_')[0]


	Diffs = MatchesPrimer(Seq, Primer)
	if Diffs > MAX_PRIMER_MISMATCHES:
		PrimerMismatchCount += 1

	OutCount += 1
	Label = Label.replace(' ', '_') + ";barcodelabel=" + BarcodeLabel + ";"
	fastq.WriteRec(sys.stdout, Label, Seq[PL:], Qual[PL:])

fastq.ReadRecs(FileName, OnRec)

print >> sys.stderr, "%10u seqs" % SeqCount
print >> sys.stderr, "%10u matched" % OutCount
print >> sys.stderr, "%10u primer mismatches" % PrimerMismatchCount
