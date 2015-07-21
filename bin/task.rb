require_all 'lib'

input = '../input/PubMed_1000_original_2014-06-15.csv'
output = '../output/PubMed_1000_original_altmetric.csv'
api = 'altmetric'

# input = '../input/MOPs_Jo_M_June_2015.csv'
# output = '../output/MOPs_Jo_M_June_2015.csv'
# api = 'epmc'

csv_create(input, api: api)
# csv_create(input, output_csv: output, api: api)
# get_altmetric('24668137', false)

# puts get_epmc('16585510', false)
