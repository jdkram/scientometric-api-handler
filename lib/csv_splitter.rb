# CSV Splitter

require 'smarter_csv'

# csv = '../input/policy-project/pmidsWHO.csv'

def split_csv(csv, chunk_size=100)
  # Create a folder to put the split CSVs in
  filename = File.basename(csv, ".csv")
  # Without the :row_sep => :auto it wouldn't accept simple csvs 
  chunked_pmids = SmarterCSV.process(csv, {:chunk_size => 100, :row_sep => :auto})
  subfolder = File.join(File.dirname(csv), filename + "_SPLIT")
  Dir.mkdir(subfolder) unless File.exists?(subfolder)
  Dir.chdir(subfolder) do
    # puts Dir.getwd
    chunked_pmids.each_with_index do |chunk, index|
      # Put each of them in its own CSVs
      CSV.open("#{filename}_#{"%03d" % index}.csv", 'w') do |csv| 
        csv << ['pmids']
        chunk.each { |entry| csv << entry.each_value }
      end
    end
  end
end

# split_csv(csv)
