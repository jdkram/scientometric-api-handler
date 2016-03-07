require 'require_all'

require_all 'lib'

# Specify API
api = 'epmc'
# List of PMIDs to query
input_csv = './input/WTpmids2015_epmc.csv'
# Split the big input CSV in to blocks of 100, keep a hold of the directory
split_csv_directory = split_csv(input_csv) 
# Now churn through each and every CSV in that directory
process_split_csvs(split_csv_directory, :epmc)
# All done? Put it all together
merge_csv('./output/WT2015_all_papers.csv', '../input/WTpmids2015_epmc_SPLIT')