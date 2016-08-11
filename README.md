cuke_sniffer 
============
[![Gem Version](https://badge.fury.io/rb/cuke_sniffer.png)](http://badge.fury.io/rb/cuke_sniffer)
[![Build Status](https://travis-ci.org/r-cochran/cuke_sniffer.png?branch=master)](https://travis-ci.org/r-cochran/cuke_sniffer)
[![Dependency Status](https://gemnasium.com/r-cochran/cuke_sniffer.png)](https://gemnasium.com/r-cochran/cuke_sniffer)
[![Code Climate](https://codeclimate.com/github/r-cochran/cuke_sniffer.png)](https://codeclimate.com/github/r-cochran/cuke_sniffer)
![](http://ruby-gem-downloads-badge.herokuapp.com/cuke_sniffer?type=total)

##Purpose
A ruby library used to root out smells in your cukes. Tailored for identifying critical problems as well as general improvements to your project/features/scenarios/step definitions.

Scoring is based on the number of 'smells' in a cucumber project, where smells
are potential misuses or errors. Cuke_sniffer follows a 'golf score' type system
where the lower the number, the better. 'Min' refers to the overall best score
for a particular object and the 'Max' is the overall worst object score.


`SEE LICENSE FOR CURRENT CUKE_SNIFFER USE DETAILS`

[Patch Notes] (https://github.com/r-cochran/cuke_sniffer/wiki/Patch-notes)

[Release 1 Tracking Board] (https://trello.com/board/cuke-sniffer/51635ebc2a64e41173017526)

Installation
-----------

    gem install cuke_sniffer

----
Usage
---
cuke_sniffer can be used through the [command line] (https://github.com/r-cochran/cuke_sniffer/wiki/Command-Line) or [inline](https://github.com/r-cochran/cuke_sniffer/wiki/Ruby-inline). Follow the links to learn more.

----
Rules
----
The list of rules/improvements has been constructed on opinions from the authors and feedback from community members. Not everyone will share these opinions and for that reason all improvements can be turned off when generating this report. See the wiki for instructions on how.

[Rule List] (https://github.com/r-cochran/cuke_sniffer/wiki/Rules-list)

---    
Output
----
cuke_sniffer data can be used in several different formats. Follow the links to learn more and see examples of each output.

[Console Output] (https://github.com/r-cochran/cuke_sniffer/wiki/Console-Output)

[HTML Output] (https://github.com/r-cochran/cuke_sniffer/wiki/Html-Output)

[Xml Output] (https://github.com/r-cochran/cuke_sniffer/wiki/Xml-Output)

---
Helping Out
-----
To better help others in the community with comparison of the scores we need data. We would appreciate it if you could submit a min_html report for your projects. This report has no identifiable data for you or your project and has only the summary, improvement list, and rules section. 

Feel like programming? Fork the project and grab something from the [backlog] (https://trello.com/board/cuke-sniffer/51635ebc2a64e41173017526) or come up with something you think that will advance the project!


---
Submitting Issues
-----
To submit an issue you have found in CukeSniffer, please use the GitHub issue page for this gem.

Authored by: Robert Cochran, Chris Vaughn, Robert Anderson

Contributions by [Manifest Solutions](http://manifestcorp.com/Home.aspx)
