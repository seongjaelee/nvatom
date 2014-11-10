# MultiMarkdown

> “As the world goes multi-platform with all of the new mobile operating systems, MultiMarkdown provides an easy way to share formatting between all of my devices. It’s easy to learn (even for us mortals) and immediately useful.”
>
> \- David Sparks, [MacSparky.com](http://macsparky.com)

> “Personally, it’s changed my game — it’s how I think now. Can’t imagine writing more than a paragraph in anything that doesn’t do MMD.”
>
> \- Merlin Mann, kung fu grippe

## What is MultiMarkdown?

MultiMarkdown, or MMD, is a tool to help turn minimally marked-up plain text into well formatted documents, including HTML, PDF (by way of LaTeX), OPML, or OpenDocument (specifically, Flat OpenDocument or ‘.fodt’, which can in turn be converted into RTF, Microsoft Word, or virtually any other word-processing format).

MMD is a superset of the Markdown syntax, originally created by John Gruber. It adds multiple syntax features (tables, footnotes, and citations, to name a few), in addition to the various output formats listed above (Markdown only creates HTML). Additionally, it builds in “smart” typography for various languages (proper left- and right-sided quotes, for example).

MultiMarkdown started as a Perl script, which was modified from the original Markdown.pl.

MultiMarkdown v3 (aka ‘peg-multimarkdown’) was based on John MacFarlane’s peg-markdown. It used a parsing expression grammar (PEG), and was written in C in order to compile on almost any operating system. Thanks to work by Daniel Jalkut, MMD v3 was built so that it didn’t have any external library requirements.

MultiMarkdown v4 is basically a complete rewrite of v3. It uses the same basic PEG for parsing (Multi)Markdown text, but otherwise is almost completely rebuilt:

- The code is designed to be easier to maintain — it’s divided into separate files on a more logical structure
- All memory leaks (to my knowledge) have been fixed
- [greg] is used instead of [peg/leg] to create the parser — this allows the parser to be thread-safe
- The [test suite] has been modified to account for several improvements. MMD should fail one of the basic Markdown tests (see peg-markdown for more information). Currently it fails one of the LaTeX tests — this is not intentional and I am working on a fix.
- Command line options are slightly different.

For another description of what MultiMarkdown is, you can also check out a PDF slide show that describes and demonstrates how MultiMarkdown can be used.
