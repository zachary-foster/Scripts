from Bio.Blast import NCBIXML
from Bio import SeqIO

def blast_xml_to_m8(result):
	for query_result in NCBIXML.parse(result):
		for hit in query_result.alignments:
			for hsp in hit.hsps:
				percent_id = (float(hsp.identities) / float(hsp.align_length)) * 100
				mismatches = hsp.align_length - hsp.identities
				line = [query_result.query, hit.hit_id, percent_id, hsp.align_length, mismatches, hsp.gaps, hsp.query_start, hsp.query_end, hsp.sbjct_start, hsp.sbjct_end, hsp.expect, hsp.bits]
				line = '\t'.join(map(str,line)) + '\n'
				yield line