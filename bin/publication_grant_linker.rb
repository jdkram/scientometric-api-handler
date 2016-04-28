require 'require_all'
require 'yamlb'

# A series of commands that currently do a specific job:
#   Using the array of grant numbers attached to publications to pull in
#     a property of that grant - in this case, areas of strength
#   Creating a lists of areas of strength for each publication
#   Populating boolean columns for each area of strength based on list

require_all 'lib'

# Load CSV of grants <-> Areas of Strength
areas_of_strength_csv = './input/grants_areas.csv'
areas_of_strength = SmarterCSV.process(areas_of_strength_csv, convert_values_to_numeric: false)
grantid_to_area = {}
# Create hash of areas of strength e.g. {12345678: "Genomics and genetics"}
areas_of_strength.each do |line|
  grantid_to_area[line[:grantid]] = line[:area_of_strength]
end

# Load the CSV of pmids <-> grant associations
csv = './input/pmids_grants.csv'

chunked_pmids = SmarterCSV.process(csv, { :row_sep => "\n"})
chunk = chunked_pmids # This step turned out to be unnecessary 

# Columns that will be applied to each pmid - true/false for each area
areas_columns = {
  culture_society: /Cultural/,
  genomics_genetics_epigenetics: /Genomics/,
  development_and_ageing: /ageing/,
  infectious_diseases: /Infectious/,
  innovations: /Innovations/,
  neuroscience: /Neuro/,
  population_env_health: /Population/,
  public_engagement: /Engagement/
}

# Create the output
CSV.open('./output/WT_grants_with_areas_of_strength.csv', 'wb') do |csv|
  tester_hash = {}
  tester_hash[:pmid] = ''
  tester_hash = tester_hash.merge(areas_columns)
  csv << tester_hash.keys

  chunk.each do |article|
    str = article[:wt_six_digit_grants]
    grants = YAML.load(str) # safe way of loading in the str as array
    grants.map { |e| sprintf "%06d", e.to_i }
    grants.uniq!
    article_areas = [] # list of areas of strength
    areas_bool = {} # true false for each area
    grants.each do | grant |
      article_areas << grantid_to_area[grant]
    end
    article_areas.uniq!
    areas_columns.each do |area, regex|
      areas_bool[area] = !regex.match(article_areas.to_s).nil?
    end
    output = {}
    output[:pmid] = article[:pmid]
    output = output.merge(areas_bool)
    csv << output.values 
  end
end
