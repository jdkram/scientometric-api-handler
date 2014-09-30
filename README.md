# Hypothesis tester

A tool for batch downloading and inspecting hypotheses from [EuropePMC].

## I/O ##

Inputs and outputs:
Input

    a) A list of PMIDs
    b) A list of grantIDs

Output

    a) CSV with EPMC metadata, including grantID and grant details, Altmetric data

## TODO ##


- [ ] Clean up with [rubocop][]
- [ ] Extend to include Altmetric data
- [ ] Look in to citations - can we pull in the complete list of citations?
- [ ] Completely refactor
    - [ ] Command line interface (in bin, read Pickaxe first)
    - [ ] 
- [ ] Catch errors with URL handling
- [ ] Raise errors if PMIDs aren't valid

## Regex ##

### Find end of sentence ###

[Demonstrated on sample text in Rubular](http://www.rubular.com/r/ZDDLghJHQd).
```ruby
/(?<!\s\w|\d\))(?:\.|\?|\!)(?= [^a-z]|$|\n)/
```


## Development snippets ##

Bits and pieces of code that are good to have at hand while developing this tool.

Sample output from get_epmc:
```ruby
hash = {:title=>"Effects of related and unrelated context on recall and recognition by adults with high-functioning autism spectrum disorder.\n", :journal=>"Neuropsychologia\n", :authors=>"Bowler DM, Gaigg SB, Gardiner JM.", :abstract=>"Memory in autism spectrum disorder (ASD) is characterised by greater difficulties with recall rather than recognition and with a diminished use of semantic or associative relatedness in the aid of recall. Two experiments are reported that test the effects of item-context relatedness on recall and recognition in adults with high-functioning ASD (HFA) and matched typical comparison participants. In both experiments, participants studied words presented inside a red rectangle and were told to ignore context words presented outside the rectangle. Context words were either related or unrelated to the study words. The results showed that relatedness of context enhanced recall for the typical group only. However, recognition was enhanced by relatedness in both groups of participants. On a behavioural level, these findings confirm the Task Support Hypothesis [Bowler, D. M., Gardiner, J. M., &amp; Berthollier, N. (2004). Source memory in Asperger's syndrome. Journal of Autism and Developmental Disorders, 34, 533-542], which states that individuals with ASD will show greater difficulty on memory tests that provide little support for retrieval. The findings extend this hypothesis by showing that it operates at the level of relatedness between studied items and incidentally encoded context. By showing difficulties in memory for associated items, the findings are also consistent with conjectures that implicate medial temporal lobe and frontal lobe dysfunction in the memory difficulties of individuals with ASD."}
```

### Sample search strings ###

PubMedCentral and EuropePubmedCentral and the Grant Lookup Tool are a bit of a nightmare in terms of their search syntax. Examples below:

<http://europepmc.org/GrantLookup/details.php?all=&init=&name=&title=&key=&i=&gid=082178&f%5B%5D=ACT&f%5B%5D=ARC&f%5B%5D=FWF&f%5B%5D=BBSRC&f%5B%5D=BBC&f%5B%5D=BCC&f%5B%5D=BHF&f%5B%5D=CRUK&f%5B%5D=CSO&f%5B%5D=DUK&f%5B%5D=DMT&f%5B%5D=ERC&f%5B%5D=MCCC&f%5B%5D=MRC&f%5B%5D=MNDA&f%5B%5D=MSS&f%5B%5D=MT&f%5B%5D=NC3RS&f%5B%5D=DH&f%5B%5D=PUK&f%5B%5D=PCUK&f%5B%5D=TI&f%5B%5D=WT&f%5B%5D=WCR&f%5B%5D=YCR&uid=8486&bid=3>

[Nice publications](http://europepmc.org/search?query=PUB_TYPE%3A%22practice%20guideline%22%20NICE)

## Scratchpad ##

From grant metadata find publications attached to it

  - Title
  - Authors

For purposes of checking.


PMID 

  1. Lookup on EPMC, get metadata including grantID
  2. grantID lookup on GRIST - metadata for grant
  3. lookup grantID on EPMC using string like
    (GRANT_ID:"082178" OR GRANT_ID:"WT082178") GRANT_AGENCY:"Wellcome Trust"
    (GRANT_ID:"082178" OR GRANT_ID:"WT082178") GRANT_AGENCY:"Wellcome Trust" AND PUB_TYPE:"practice guideline"


What do we want?

All WT funded papers that are cited in guidelines
  -> grants associated with those (metadata)
  -> 


On the website - increase discoverability

Is there a limit on this? Are only a small subset being linked here because they've included grantIDs?

Looks like data isn't being paired up from funding agency and practice guidelines
  Linking funding agency to guidelines - only 10 results out of 21691 linked to WT grants, seems absurdly low.

## Instructions ##

Come up with instructions for what you can feed this and what comes out (basic UML diagrams).


Talk to EuropePMC about visibility and analytics and documentation of search terms.

## Error handling ##

I keep encountering an error when attempting batch:
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