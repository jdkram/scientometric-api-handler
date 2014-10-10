################################################################
# HYPOTHESIS INSPECTION
################################################################

# Overly generous list for now, limit this.
# Also need plural forms?
HYPOTHESIS_SYNONYMS = %w(
  theory theorem thesis conjecture supposition
  speculation postulation postulate proposition premise
  surmise assumption presumption presupposition notion
  concept idea contention opinion view belief
  )


POSITIVE_INDICATORS = %w(support prove confirm extend)
CONFIRMERS = Regexp.union(POSITIVE_INDICATORS)

# Vary these keywords to support present, past and future tenses?

# Check for negation

NEGATIVE_INDICATORS = %w(un dis not\ )
NEGATORS = Regexp.union(NEGATIVE_INDICATORS)

sentence_regex = /(?:\.|\?|\!)(?= [^a-z]|$|\n)/
# Stricter regex which attempts to solve problem of initialed names:
strict_sentence_regex = /(?<!\s\w|\d\))(?:\.|\?|\!)(?= [^a-z]|$|\n)/

# Outputs array of sentences with hypothesis in
def extract_hypotheses(hypothesis, regex)
  hypothesis.split(regex).select{ |s| s.downcase[/hypoth|theory/] }
  # We also want the sentences immediately after
end


def hypothesis_tester (hypothesis)
  hypothesis.downcase!
  hypothesis[CONFIRMERS]
  # TODO: think hard about this
end

# test_hypothesis_sentences = extract_hypotheses(sample_abstract, strict_sentence_regex)

# test_hypotheses.each do
#   |h| 
#   puts "Testing hypothesis sentence: #{h}"
#   puts hypothesis_tester(h)
# end

# Need a way of checking the sentence after for confirmed, etc.

# puts get_epmc(test_pmid)
# 
# csv_create('test_pmids.csv', 'test4.csv')