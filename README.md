# Scientometric API Handler #

A tool for batch downloading and inspecting hypotheses from a number of [scientometric][scientometric] sources:

- [EuropePMC REST Web Service][EPMC_REST] - access to all publications indexed by [EuropePMC][]
- [EuropePMC Grist API][EPMC_Grist] - grant data
- [Altmetric][] - Social media impact of articles with PMIDs / DOIs

PMIDs (described below) are used throughout as the original application of the tool was for biomedical literature, but the code could be adapted to work with DOIs (which may be more suitable for Altmetric records, which sometimes have a DOI but no PMID).

> A PMID (PubMed identifier or PubMed unique identifier) is a unique number assigned to each PubMed record. A PMID is not the same as a PMCID which is the identifier for all works published in the free-to-access PubMed Central.
> -- <cite>[PubMed on Wikipedia](https://en.wikipedia.org/wiki/PubMed)</cite>

This tool then calls the API with each PMID, respecting rate limits, and returns the data from that API.

This is one of my first projects in Ruby, so please forgive some of the crimes against good code.

## Usage

The easiest way to get started: duplicate and alter `bin/sample_task.rb`.
Example commands:

```ruby
# Specify API
api = 'epmc'
# List of PMIDs to query
input_csv = './input/WTpmids2015_epmc.csv'
output_csv = ''
# Split the big input CSV in to blocks of 100, keep a hold of the directory
split_csv_directory = split_csv(input_csv) 
# Now churn through each and every CSV in that directory
process_split_csvs(split_csv_directory, :epmc)
# All done? Put it all together
# merge_csv(output_csv, directory_of_chunked_results)
merge_csv('./output/WT2015_all_papers.csv', '../input/WTpmids2015_epmc_SPLIT')
```

## APIs ##

### EPMC ###

Sample XML: <http://www.ebi.ac.uk/europepmc/webservices/rest/search/query=EXT_ID:26138067&resulttype=core>

Retrieved data:
- **pmid**
- **doi**
- **title**
- **journal**
- **cited_by_count**
- **pubtypes**
- **author_ids**: usually a collection of ORCID IDs
- **mesh_headings**
- **abstract**
- **dateofcreation**: one of many date fields in EPMC
- **authorstring**: all of the authors, pushed in to one string
- **firstauthor**: first author in list
- **lastauthor**: last author in list
- **url**
- **affiliations**: list of all affiliations. Duplicate values deleted - save on space, and we don't necessarily know which author an affiliation corresponds to if the two list are side by side
- **number_of_grants**
- **all_grants**
- **WT_grants**: all grants with "Wellcome Trust"
- **WT_six_digit_grants**: pulling out any six digit value we can find in those WT grants
- **hasTextMinedTerms**
- **hasLabsLinks**
- **labsLinks**
- **hasDbCrossReferences**
- **dbCrossReferenceList**

## TODO ##

- [x] Aim for a command line interface which takes a .csv of PMIDs as input alongside flags for each API to call
- [ ] Look in to citations - can we pull in the complete list of citations?
- [x] Command line interface (in bin, read Pickaxe first)
- [ ] Catch errors with URL handling
- [x] Raise errors if PMIDs aren't valid
- [ ] Create tests for new ORCID API integration
- [x] Refactor individual API calls to own Ruby files
- [x] Process grant information past the first 10
    - [x] Pull out WT related funding and cleaned, unique six digit grant codes
- [ ] Change EPMC to use JSON
- [ ] Abstract method for checking if fields are part of the EPMC metadata (lots of repetition in `api_caller.rb`)
- [ ] Add EPMC search - ability to download all the results for a query (beyond the first 2000 available via web interface)
- [ ] Add time to completion for all PMIDs currently being processed

## Sample search strings ##

EPMC CORE SEARCH: <http://www.ebi.ac.uk/europepmc/webservices/rest/search/query=QUERY&resulttype=core>
[LABSLINKS (MED)](http://www.ebi.ac.uk/europepmc/webservices/rest/MED/24727771/labsLinks)
[Grant lookup](http://europepmc.org/GrantLookup/details.php?all=&init=&name=&title=&key=&i=&gid=082178&f%5B%5D=ACT&f%5B%5D=ARC&f%5B%5D=FWF&f%5B%5D=BBSRC&f%5B%5D=BBC&f%5B%5D=BCC&f%5B%5D=BHF&f%5B%5D=CRUK&f%5B%5D=CSO&f%5B%5D=DUK&f%5B%5D=DMT&f%5B%5D=ERC&f%5B%5D=MCCC&f%5B%5D=MRC&f%5B%5D=MNDA&f%5B%5D=MSS&f%5B%5D=MT&f%5B%5D=NC3RS&f%5B%5D=DH&f%5B%5D=PUK&f%5B%5D=PCUK&f%5B%5D=TI&f%5B%5D=WT&f%5B%5D=WCR&f%5B%5D=YCR&uid=8486&bid=3)

Nice publications: <http://europepmc.org/search?query=PUB_TYPE%3A%22practice%20guideline%22%20NICE>

## Further resources / similar projects ##

- [PMID to DOI converter][PMID2DOI] as used in ScholarNinja's [Importer][ScholarNinja Importer]

[EuropePMC]: http://europepmc.org/ 
[rubocop]: https://github.com/bbatsov/rubocop
[scientometric]: https://en.wikipedia.org/wiki/Scientometrics
[EPMC_REST]: http://europepmc.org/RestfulWebService
[EPMC_Grist]: http://plus.europepmc.org/GristAPI/
[Altmetric]: http://api.altmetric.com/
[PMID2DOI]: http://www.pmid2doi.org/
[ScholarNinja Importer]: https://github.com/ScholarNinja/importer
