require 'csv'

require_relative '../lib/api_handler'

################################################################
# CSV PARSING
################################################################
# Read from one CSV (of PMIDs)
#   and output another (of info from API)

def epmc_csv_create(inputcsv, outputcsv)
  CSV.open(outputcsv, 'w') do |csv|
    headers, pmids = [], []
    get_epmc('1') . each { |header, value| headers << header.to_s }
    csv << headers # Create header row
    pmids = CSV.read(inputcsv) # Input data (efficient?)
    queries_per_second = 2 # Rate limit
    pause = 1.0 / queries_per_second
    puts "Parsing #{pmids.length}.
    This will take at least #{pmids.length * pause} seconds."
    i = 0
    pmids.each do |pmid|
      row = []
      # Create array from hash values
      get_epmc(pmid[0]).each { |k,v| row << v } 
      csv << row
      sleep pause # Let's not thrash their server
      i += 1
      puts "#{i} / #{pmids.length} complete. Approximately
      #{((pmids.length - i) * pause).round} seconds remain" if i % 5 == 0
    end
    puts 'Task complete!'
  end
end

ALTMETRIC_TIME_PER_PMID = 1.7085062989028295

def altmetric_csv_create(inputcsv, outputcsv)
  CSV.open(outputcsv, 'w') do |csv|
    headers, pmids = [], []
    get_altmetric('test').each_key { |key| headers << key}    
    csv << headers # Create header row
    pmids = CSV.read(inputcsv) # Input data (efficient?)
    pmids.shift # remove header row
    queries_per_second = 2 # Rate limit
    pause = 1.0 / queries_per_second
    puts "Parsing #{pmids.length}.
    This will take at least #{pmids.length * pause * ALTMETRIC_TIME_PER_PMID } seconds."
    i = 0
    pmids.each do |pmid|
      next if !(pmid[0] =~ /\d{8}/) # Skip if not a valid pmid
      row = []
      # Create array from hash values
      get_altmetric(pmid[0]).each { |k,v| row << v } 
      csv << row
      sleep pause # Let's not thrash their server
      i += 1
      puts "#{i} / #{pmids.length} complete. Approximately #{((pmids.length - i) * pause * ALTMETRIC_TIME_PER_PMID).round} seconds remain" if i % 5 == 0
    end
    puts 'Task complete!'
  end
end

EPMC_TIME = 2.0

def epmc_guidelines_create(inputcsv,outputcsv)
  CSV.open(outputcsv, 'w') do |csv|
    headers, pmids = [], []
    get_epmc_citations('test').each_key { |key| headers << key}    
    csv << headers # Create header row
    pmids = CSV.read(inputcsv) # Input data (efficient?)
    pmids.shift # remove header row
    queries_per_second = 2 # Rate limit
    pause = 1.0 / queries_per_second
    puts "Parsing #{pmids.length}.
    This will take at least #{pmids.length * pause * EPMC_TIME } seconds."
    i = 0
    pmids.each do |pmid|
      next if !(pmid[0] =~ /\d{8}/) # Skip if not a valid pmid
      row = []
      # Create array from hash values
      get_epmc_citations(pmid[0]).each { |k,v| row << v } 
      csv << row
      sleep pause # Let's not thrash their server
      i += 1
      puts "#{i} / #{pmids.length} complete. Approximately #{((pmids.length - i) * pause * ALTMETRIC_TIME_PER_PMID).round} seconds remain" if i % 5 == 0
    end
    puts 'Task complete!'
  end
end
# sample_abstract = "Memory in autism spectrum disorder (ASD) is characterised by greater difficulties with recall rather than recognition and with a diminished use of semantic or associative relatedness in the aid of recall. Two experiments are reported that test the effects of item-context relatedness on recall and recognition in adults with high-functioning ASD (HFA) and matched typical comparison participants. In both experiments, participants studied words presented inside a red rectangle and were told to ignore context words presented outside the rectangle. Context words were either related or unrelated to the study words. The results showed that relatedness of context enhanced recall for the typical group only. However, recognition was enhanced by relatedness in both groups of participants. On a behavioural level, these findings confirm the Task Support Hypothesis [Bowler, D. M., Gardiner, J. M., &amp; Berthollier, N. (2004). Source memory in Asperger's syndrome. Journal of Autism and Developmental Disorders, 34, 533-542], which states that individuals with ASD will show greater difficulty on memory tests that provide little support for retrieval. The findings extend this hypothesis by showing that it operates at the level of relatedness between studied items and incidentally encoded context. By showing difficulties in memory for associated items, the findings are also consistent with conjectures that implicate medial temporal lobe and frontal lobe dysfunction in the memory difficulties of individuals with ASD."

# sample_abstract = get_epmc(test_pmid)[:abstract]

# puts @test_pmid

def orcid_csv_create(inputcsv, outputcsv = false)
  trimmed = inputcsv.gsub(/\.csv$/, '')
  outputcsv = trimmed + '_OUTPUT.csv' unless outputcsv.is_a? String
  CSV.open(outputcsv, 'w') do |csv|
    headers, orcids = [], []
    get_orcid('0000-0002-2464-0462').each_key { |key| headers << key}    
    csv << headers # Create header row
    orcids = CSV.read(inputcsv) # Input data (efficient?)
    orcids.shift # remove header row
    queries_per_second = 2 # Rate limit
    pause = 1.0 / queries_per_second
    puts "Parsing #{orcids.length}.
    This will take at least #{orcids.length * pause * EPMC_TIME } seconds."
    i = 0
    orcids.each do |orcid|
      next if !(orcid[0] =~ /\d{4}-\d{4}-\d{4}-\d{4}/) # Skip if not a valid orcid
      row = []
      # Create array from hash values
      get_orcid(orcid[0]).each { |k,v| row << v } 
      csv << row
      sleep pause # Let's not thrash their server
      i += 1
      puts "#{i} / #{orcids.length} complete. Approximately #{((orcids.length - i) * pause * 1.7).round} seconds remain" if i % 5 == 0
    end
    puts 'Task complete!'
  end
end

def grist_csv_create(inputcsv, outputcsv)
  CSV.open(outputcsv, 'w') do |csv|
    headers, grantids = [], []
    get_grist('091769').each { |header, value| headers << header.to_s }
    csv << headers # Create header row
    grantids = CSV.read(inputcsv) # Input data (efficient?)
    queries_per_second = 2 # Rate limit
    pause = 1.0 / queries_per_second
    puts "Parsing #{grantids.length}.
    This will take at least #{grantids.length * pause} seconds."
    i = 0
    grantids.each do |grantid|
      row = []
      # Create array from hash values
      get_grist(grantid[0]).each { |k,v| row << v } 
      csv << row
      sleep pause # Let's not thrash their server
      i += 1
      puts "#{i} / #{grantids.length} complete. Approximately #{((grantids.length - i) * pause).round} seconds remain" if i % 5 == 0
    end
    puts 'Task complete!'
  end
end


