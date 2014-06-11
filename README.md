# Hypothesis tester

A tool for batch downloading and inspecting hypotheses from [EuropePMC].

## TODO ##

- [ ] Clean up with [rubocop][]
- [ ] Extend to include Altmetric data

## Regex ##

### Find end of sentence ###

```ruby

```


## Development snippets ##

Bits and pieces of code that are good to have at hand while developing this tool.

Sample output from get_epmc:
```ruby
hash = {:title=>"Effects of related and unrelated context on recall and recognition by adults with high-functioning autism spectrum disorder.\n", :journal=>"Neuropsychologia\n", :authors=>"Bowler DM, Gaigg SB, Gardiner JM.", :abstract=>"Memory in autism spectrum disorder (ASD) is characterised by greater difficulties with recall rather than recognition and with a diminished use of semantic or associative relatedness in the aid of recall. Two experiments are reported that test the effects of item-context relatedness on recall and recognition in adults with high-functioning ASD (HFA) and matched typical comparison participants. In both experiments, participants studied words presented inside a red rectangle and were told to ignore context words presented outside the rectangle. Context words were either related or unrelated to the study words. The results showed that relatedness of context enhanced recall for the typical group only. However, recognition was enhanced by relatedness in both groups of participants. On a behavioural level, these findings confirm the Task Support Hypothesis [Bowler, D. M., Gardiner, J. M., &amp; Berthollier, N. (2004). Source memory in Asperger's syndrome. Journal of Autism and Developmental Disorders, 34, 533-542], which states that individuals with ASD will show greater difficulty on memory tests that provide little support for retrieval. The findings extend this hypothesis by showing that it operates at the level of relatedness between studied items and incidentally encoded context. By showing difficulties in memory for associated items, the findings are also consistent with conjectures that implicate medial temporal lobe and frontal lobe dysfunction in the memory difficulties of individuals with ASD."}
```

[EuropePMC]: http://europepmc.org/ 
[rubocop]: https://github.com/bbatsov/rubocop