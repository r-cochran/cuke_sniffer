cuke_sniffer
============
A ruby library used to root out smells in your cukes. Tailored for identifying critical problems as well as general improvements to your project/features/scenarios/step definitions.

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

Command Line

    cd <your_features_folder>
    cuke_sniffer
    
JRuby

    cuke_sniffer.rb
        
Or,

    cuke_sniffer <your_features_folder> <your_step_definitions_folder>

From Ruby files

    require 'cuke_sniffer'
    cuke_sniffer = CukeSniffer::CLI.new
    cuke_sniffer.output_results
    
    
Or, 

    require 'cuke_sniffer'
    cuke_sniffer = CukeSniffer::CLI.new(<your_features_folder>, <your_step_definitions_folder>)
    cuke_sniffer.output_html
    
Customizing Rules [in 0.0.3]
----
Command line: coming soon.

Inline:
All rules are symbols in this hash and correspond to the message that is eventually displayed. Each rule has a :enabled, :phrase, :score attribute.
Some rules have a :min, :max, a custom named attribute for edge case information.

Turning off a rule

    CukeSniffer::RuleConfig::RULES[:numbers_in_description][:enabled] = false

Changing a phrase

    CukeSniffer::RuleConfig::RULES[:background_with_no_scenarios][:phrase] = "Found a bad feature, background with no scenarios"
    
Changing a score (custom)

    CukeSniffer::RuleConfig::RULES[:asterisk_step][:score] = 3000
    
Changing a score (stock)

    CukeSniffer::RuleConfig::RULES[:asterisk_step][:score] = CukeSniffer::RuleConfig::FATAL

You can also edit your source or use a gem extension to add/use your own rules! If you do let us know so we can consider putting it in the gem!

Example Console Output
----
    Suite Summary
      Total Score: 325
        Features (../features/scenarios)
          Min: 0
          Max: 213
          Average: 55.75
        Step Definitions (../features/step_definitions)
          Min: 0
          Max: 101
          Average: 11.33
      Improvements to make:
        (4)Scenario steps out of Given/When/Then order.
        (2)Nested step call.
        (1)Implementation word used: screen.
        (1)No steps in Scenario.
        (1)Scenario Outline with no examples table.
        (1)Scenario with too many steps.
        (1)Implementation word used: button.
        (1)Implementation word used: page.
        (1)Invalid first step. Began with And/But.
        (1)Recursive nested step call.
        (1)Scenario has no description.
        (1)Feature has numbers in the description.
----        
Summary
-----
![summary](http://i.imgur.com/G7GM1gF.png)
-----

Expanded
-----
![expand_improvement_list](http://i.imgur.com/SiVAVd1.png)
![expand_dead_steps](http://i.imgur.com/YNfLORb.png)
![expand_features](http://i.imgur.com/D3C7ss7.png)
![expand_step_definitions](http://i.imgur.com/md6aKIG.png)
----

Expanded for more details
-----
![expand_details_features](http://i.imgur.com/tZtbA8R.png)
![expand_details_step_definitions](http://i.imgur.com/O1aBepe.png)
----

Submitting Issues
-----
To submit an issue you have found in CukeSniffer, please use the GitHub issue page for this gem.
