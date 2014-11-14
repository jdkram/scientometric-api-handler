# Temporary file which asks as taskmanager.

require 'rushover'
require_relative '../lib/api_caller'
require_relative '../lib/csv_parser'

t1 = Time.now
puts "Task started at #{"%02d" % t1.getlocal.hour}:#{"%02d" % t1.getlocal.min}"

pmid1 = '20059573'
pmid2 = '18755769'
pmid3 = '24889601' # ID of the Facebook psych experiment study, high altmetric
grantid1= '082178'
pmid4 = '22440947'


# Let's chunk it up in case it crashes, deal with merging CSVs
#   at a later point.
def batch_altmetric(first, last)
  (first..last).each do | num |
    num = "%03d" % num
    puts "Running batch #{num}"
    t3 = Time.now
    altmetric_csv_create("../test/pmids/test#{num}.csv","../test/pmids/altmetric_test#{num}-2.csv")
    t4 = Time.now
    puts "Batch took #{t4 - t3} seconds. That's #{100 / (t4 - t3)} entries per second."
  end
end

puts get_altmetric('j2')[:altmetric_STATUS]
# File.open('../test/altmetric_hash', 'w'){ |file| file.write(get_altmetric_json(pmid3))}

# Check citations > Request Parameters section
# http://www.ebi.ac.uk/europepmc/webservices/rest/HIR/9855500/citations

# puts get_epmc(9855500, raw: false)
# puts get_epmc(9855500, raw: true)
# puts get_epmc_citations(9855500)

# epmc_guidelines_create('../test/WTCitedShortened.csv', '../test/epmc_guidelines.csv')

# puts get_orcid '0000-0002-1071-298X'
# puts get_orcid ('0000-0003-0763-3954')
# puts get_orcid '0000-0002-2464-0462'

# orcid_csv_create '../test/ORCID/20140403_attributing_orcids.csv' 
# orcid_csv_create '../test/ORCID/20140417_egrants_orcids_pmids.csv'

# batch_altmetric(0,0)

# xml = get_epmc('24737131', {raw: true})

t2 = Time.now
notification_message = "Task finished at #{"%02d" % t2.getlocal.hour}:#{"%02d" % t2.getlocal.min}"

# client = Rushover::Client.new(PUSHOVER_API_KEY)
# client.notify(PUSHOVER_USER_KEY, notification_message, :priority => 1, :title => "Task complete!")


puts notification_message
puts "Duration: #{t2-t1}"