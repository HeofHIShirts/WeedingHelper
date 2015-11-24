# WeedingHelper
A Ruby script that parses a CSV file of possible weeding/deaccession candidates according to user-specified criteria (e.g. date, circulation count) and returns a CSV file of those that meet the criteria.

## Information: 

* Script last updated 24 November 2015

* Script developed on Ruby 2.2.3, but successfully tested on Ruby 1.9.1. Just in case you wanted to know.

* Licensed under a GPL (Version 2).

* This script is ILS and service agnostic - so long as you can get a CSV output of your file, it doesn't particularly care what generated it.

## Assumptions: 

﻿This script makes a few assumptions, based on the CSV methods in the standard library of Ruby:

1. Your file has headers, and they are the very first row of your data. Column names are derived from your headers, so if you need to make them more descriptive, do that.
2. You know at least part of the name(s) of the collections or call numbers that you want to weed with, and those collection names are in your file somewhere, because there's some regex matching going on.
3. When weeding by date, you want to weed things older than the date you input as your comparison date. 
4. If selecting multiple columns or headers for data, the data in all of those columns is in the same format, so that we can compare apples to apples.

If you want to work on making these assumptions explicit asks, go for it!

## Philosophy:

### Why build this thing?

First, because there wasn't anything on GitHub that looked like this. So why not?

Second, and more impoprtantly, I built this script because not everyone has access to the database of their systems, not everyone knows SQL so that they can pull useful information out of their databases, not everyone has a system that will help with weeding decisions, and not everyone has an IT department at their library (or library system) that will build them custom or customizable reports based on the data they have, so that they can make informed weeding decisions. 

I also built this script because it's exceedingly tedious to have to trek out to the shelves, pull off materials onto a cart, bring them into a workroom, scan them to get their data, make a decision based on that data, then trek all the way back out to the shelves to put those materials that aren't being weeded back.

And because I don't necessarily see the need to pay other services large amounts of money to help with weeding decisions, because they inevitably force you to set options that don't work for everyone in your library system or they produce garbage results because they're not customizable enough to suit your requirements. Every librarian, archivist, or collection manager has their own weighting to the data that's there, and that touch is what makes collections personal and quirky enough to attract the attention of others that enjoy similar things.

That said, this script is not a substitute for actually touching the materials in your collection. It can't detect broken or worn objects, nor can it show you that something is the only copy in your collection and might be worth holding on to. You still have to exercise judgment and responsibility. I just hope this helps.

-HeofHIShirts
