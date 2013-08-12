cuke_sniffer 
============
[![Gem Version](https://badge.fury.io/rb/cuke_sniffer.png)](http://badge.fury.io/rb/cuke_sniffer)
[![Build Status](https://travis-ci.org/r-cochran/cuke_sniffer.png?branch=master)](https://travis-ci.org/r-cochran/cuke_sniffer)
[![Dependency Status](https://gemnasium.com/r-cochran/cuke_sniffer.png)](https://gemnasium.com/r-cochran/cuke_sniffer)
[![Code Climate](https://codeclimate.com/github/r-cochran/cuke_sniffer.png)](https://codeclimate.com/github/r-cochran/cuke_sniffer)

##Purpose
A ruby library used to root out smells in your cukes. Tailored for identifying 		 critical problems as well as general improvements to your project/features/scenarios/step definitions.

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


Usage
-----
Note for JRuby: Make sure you have your

    JRUBY_OPTS=--1.9 

###Command Line

    cd <your_features_folder>
    cuke_sniffer

Or

    cuke_sniffer -f <your_features_folder> -s <your_step_definitions_folder> -hk <your_hooks_directory> 

Or
	
	cuke_sniffer -p <your_project_root>
	cuke_sniffer --project <your_project_root>

Or
	
	cuke_sniffer -f <your_features_folder>
	cuke_sniffer --features <your_features_folder>

Or
	
	cuke_sniffer -s <your_step_definitions_folder>
	cuke_sniffer --step_definitions <your_step_definitions_folder>

Or

	cuke_sniffer -hk <your_hooks_directory>
	cuke_sniffer --hooks <your_hooks_directory>

Or

	cuke_sniffer -f <your_features_folder> -s <your_step_definitions_folder>


HTML output

    cuke_sniffer -o html 
	cuke_sniffer -o html <name_of_object>

XML output

    cuke_sniffer -o xml
	cuke_sniffer -o xml <name_of_object>

###From Ruby files

    require 'cuke_sniffer'
    cuke_sniffer = CukeSniffer::CLI.new
    cuke_sniffer.output_results
    
Or 

    require 'cuke_sniffer'
    cuke_sniffer = CukeSniffer::CLI.new(
		{	
			:features_location => <your_features_folder>, 
			:step_definitions_location => <your_step_definitions_folder>, 
			:hooks_location => <your_hooks_directory>
		})
    cuke_sniffer.output_html
    
Customizing Rules
----
Command line: coming soon.

Inline:
All rules are symbols in this hash and correspond to the message that is eventually displayed. Each rule has a :enabled, :phrase, :score attribute.
Some rules have a :min, :max, a custom named attribute for edge case information.

#####Turning off a rule

    CukeSniffer::RuleConfig::RULES[:numbers_in_description][:enabled] = false

#####Changing a phrase

    CukeSniffer::RuleConfig::RULES[:background_with_no_scenarios][:phrase] = "Found a bad feature, background with no scenarios"
    
#####Changing a score (custom)

    CukeSniffer::RuleConfig::RULES[:asterisk_step][:score] = 3000
    
#####Changing a score (stock)

    CukeSniffer::RuleConfig::RULES[:asterisk_step][:score] = CukeSniffer::RuleConfig::FATAL

You can also edit your source or use a gem extension to add/use your own rules! If you do let us know so we can consider putting it in the gem!

Console Output
----

	Suite Summary
	  Total Score: 192
        Features
          Min: 0 
          Max: 0 
          Average: 0.0
      Scenarios
          Min: 0 
          Max: 10 
          Average: 3.33
      Step Definitions
          Min: 0 
          Max: 10 
          Average: 1.38
      Hooks
          Min: 21 
          Max: 25 
          Average: 24.43
	  Improvements to make:
        (6)Hook without a begin/rescue. Reduced visibility when debugging.
        (1)Hook with no content.
        (1)Hook found outside of the designated hooks file
        (1)Hook is only comments.
        (1)Nested step call.
        (1)Lazy Debugging through puts, p, or print
        (1)Scenario steps out of Given/When/Then order.


----        
HTML Output
-----
Since there is a large amount of information that can be displayed each major section is hidden by default and can be shown/hidden by clicking on the green title bar for that section. Following that pattern, if you want to see more details of an item you can click on its title (see features, step definitions, hooks).

**Default Display**
![summary](http://i.imgur.com/9XNlbHs.png)

**Improvement List**
![improvement_list](http://i.imgur.com/uZ7R0yd.png)

**Dead Steps**
![dead_steps](http://i.imgur.com/KHtz2v0.png)

**Features**
![features](http://i.imgur.com/qicQUiN.png)

**Features (expanded to show details)**
![features_expand](http://i.imgur.com/mTkKlmo.png)

**Step Definitions**
![step_definitions](http://i.imgur.com/xvNMS9t.png)

**Step Definitions (expanded to show details)**
![step_definitions_expand](http://i.imgur.com/tn4p5ny.png)

**Hooks**
![hooks](http://i.imgur.com/y6nitqI.png)

**Hooks (expanded to show details)**
![hooks_expand](http://i.imgur.com/GbNouqT.png)

XML Output
----
https://github.com/r-cochran/cuke_sniffer/blob/master/cuke_sniffer.xml

The xml output follows the same object structure as the classes in this gem.

    cuke_sniffer
  		rules
			rule
				enabled
				phrase
				score

    	feature_summary
			score
			count
			average
			good
			bad
			threshold
		scenarios_summary
			score
			count
			average
			good
			bad
			threshold
		step_definitions_summary
			score
			count
			average
			good
			bad
			threshold
		hooks_summary
			score
			count
			average
			good
			bad
			threshold
		improvement_list
			improvement
				rule
				total
		features
			feature
				background
					start_line
					steps
						step
					examples
						example
					score
					location
					rules
						rule
							phrase
							score
				scenarios
					start_line
					steps
						step
					examples
						example
					score
					location
					rules
						rule
							phrase
							score
				score
				location
				rules
					rule
						phrase
						score
				
		step_definitions
			step_definition
				start_line
				regex
				parameters
					parameter
				nested_steps
					nested_step
				calls
					call
						location
						call
				code
					code
				score
				location
				rules
					rule
						phrase
						score
		hooks
			hook
				start_line
				type
				tags
					tag
				parameters
				code
					code
				score
				rules
					rule
						phrase
						score


Submitting Issues
-----
To submit an issue you have found in CukeSniffer, please use the GitHub issue page for this gem.

Authored by: Robert Cochran, Chris Vaughn, Robert Anderson

Contributions by [Manifest Solutions](http://manifestcorp.com/Home.aspx)
