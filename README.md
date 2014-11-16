# Hypothesis tester

A tool for batch downloading and inspecting hypotheses from a number of [scientometric][scientometric] sources:

- [EuropePMC REST Web Service][EPMC_REST] - access to all publications indexed by [EuropePMC][]
- [EuropePMC Grist API][EPMC_Grist]
- [Altmetric][] - Social media impact of articles with PMIDs / DOIs

PMIDs (described below) are used throughout as the original application of the caller was on biomedical literature, but the code could be adapted to work with DOIs (which may be more suitable for Altmetric records, which sometimes have a DOI but no PMID).

> A PMID (PubMed identifier or PubMed unique identifier) is a unique number assigned to each PubMed record. A PMID is not the same as a PMCID which is the identifier for all works published in the free-to-access PubMed Central.
> -- <cite>[PubMed on Wikipedia](https://en.wikipedia.org/wiki/PubMed)</cite>

## I/O ##

Inputs and outputs:
Input

    a) A list of PMIDs
    b) A list of grantIDs

Output

    a) CSV with EPMC metadata, including grantID and grant details, Altmetric data

## TODO ##

- [ ] Look in to citations - can we pull in the complete list of citations?
- [ ] Completely refactor
    - [ ] Command line interface (in bin, read Pickaxe first)
- [ ] Catch errors with URL handling
- [ ] Raise errors if PMIDs aren't valid

### Testing ###

- [ ] Create exemplar output from each API to use for testing

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

History entries don't seem correct in some cases:
=> {"at"=>7.25, "1d"=>0, "2d"=>0, "3d"=>0, "4d"=>0, "5d"=>0, "6d"=>0, "1w"=>0, "1m"=>0, "3m"=>0, "6m"=>0, "1y"=>0} for 10.7554/elife.00047

[EuropePMC]: http://europepmc.org/ 
[rubocop]: https://github.com/bbatsov/rubocop
[scientometric]: https://en.wikipedia.org/wiki/Scientometrics
[EPMC_REST]: http://europepmc.org/RestfulWebService
[EPMC_Grist]: http://plus.europepmc.org/GristAPI/
[Altmetric]: http://api.altmetric.com/
