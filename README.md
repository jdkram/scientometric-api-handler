# Scientometric API Handler #

A tool for batch downloading and inspecting hypotheses from a number of [scientometric][scientometric] sources:

- [EuropePMC REST Web Service][EPMC_REST] - access to all publications indexed by [EuropePMC][]
- [EuropePMC Grist API][EPMC_Grist]
- [Altmetric][] - Social media impact of articles with PMIDs / DOIs

PMIDs (described below) are used throughout as the original application of the caller was on biomedical literature, but the code could be adapted to work with DOIs (which may be more suitable for Altmetric records, which sometimes have a DOI but no PMID).

> A PMID (PubMed identifier or PubMed unique identifier) is a unique number assigned to each PubMed record. A PMID is not the same as a PMCID which is the identifier for all works published in the free-to-access PubMed Central.
> -- <cite>[PubMed on Wikipedia](https://en.wikipedia.org/wiki/PubMed)</cite>

This tool then calls the API with each PMID, respecting rate limits, and returns the data from that API.

This is one of my first projects in Ruby, so please forgive some of the crimes against Ruby in here.

# Use #

Can be called via the command line. The only two necessary arguments are input .csv file of PMIDs and the API to call:

    sah altmetric.csv -a altmetric

The output file can be specified:

    sah ~/Documents/pmids.csv -a epmc -o ~/Documents/output.csv


## I/O ##

Inputs and outputs:
Input

    a) A list of PMIDs
    b) A list of grantIDs

Output

    a) CSV with EPMC metadata, including grantID and grant details, Altmetric data

## TODO ##

- [x] Aim for a command line interface which takes a .csv of PMIDs as input alongside flags for each API to call
- [ ] Look in to citations - can we pull in the complete list of citations?
- [ ] Completely refactor
    - [x] Command line interface (in bin, read Pickaxe first)
- [ ] Catch errors with URL handling
- [ ] Raise errors if PMIDs aren't valid

### Sample search strings ###

PubMedCentral and EuropePubmedCentral and the Grant Lookup Tool are a bit of a nightmare in terms of their search syntax. Examples below:

<http://europepmc.org/GrantLookup/details.php?all=&init=&name=&title=&key=&i=&gid=082178&f%5B%5D=ACT&f%5B%5D=ARC&f%5B%5D=FWF&f%5B%5D=BBSRC&f%5B%5D=BBC&f%5B%5D=BCC&f%5B%5D=BHF&f%5B%5D=CRUK&f%5B%5D=CSO&f%5B%5D=DUK&f%5B%5D=DMT&f%5B%5D=ERC&f%5B%5D=MCCC&f%5B%5D=MRC&f%5B%5D=MNDA&f%5B%5D=MSS&f%5B%5D=MT&f%5B%5D=NC3RS&f%5B%5D=DH&f%5B%5D=PUK&f%5B%5D=PCUK&f%5B%5D=TI&f%5B%5D=WT&f%5B%5D=WCR&f%5B%5D=YCR&uid=8486&bid=3>

[Nice publications](http://europepmc.org/search?query=PUB_TYPE%3A%22practice%20guideline%22%20NICE)

## Scratchpad ##

PMID 

  1. Lookup on EPMC, get metadata including grantID
  2. grantID lookup on GRIST - metadata for grant
  3. lookup grantID on EPMC using string like
    (GRANT_ID:"082178" OR GRANT_ID:"WT082178") GRANT_AGENCY:"Wellcome Trust"
    (GRANT_ID:"082178" OR GRANT_ID:"WT082178") GRANT_AGENCY:"Wellcome Trust" AND PUB_TYPE:"practice guideline"

## Error handling ##

I keep encountering an error when attempting a batch:
<http://api.altmetric.com/v1/pmid/23197817> causes issues due to there being no context data, unlike for every other entry in existence.

Erroring entries:

- In 003, 23197817
- In 017, 22182802
- In 026, 22826610
- In 031, 23251783
- 20390432
- 21073404

__It's possible that I skipped over all old pmids (those without 8 digits) due to this line of code:__

>       next if !(pmid[0] =~ /\d{8}/) # Skip if not a valid pmid

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
