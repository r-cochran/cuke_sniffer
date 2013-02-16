cuke_sniffer
============
A ruby library used to root out smells in your cukes. Tailored for identifying critical problems as well as general improvements to your project/features/scenarios/step definitions.

`SEE LICENSE FOR CURRENT CUKE_SNIFFER USE DETAILS`

Installation
-----------

    gem install cuke_sniffer


Usage
-----
Command Line

    cd <your_features_folder>
    cuke_sniffer
    
    
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
    
    
Example Output
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
![summary](http://i.imgur.com/G7GM1gF.png)
----
Expanded
![expand_improvement_list](http://i.imgur.com/SiVAVd1.png)
![expand_dead_steps](http://i.imgur.com/YNfLORb.png)
![expand_features](http://i.imgur.com/D3C7ss7.png)
![expand_step_definitions](http://i.imgur.com/md6aKIG.png)
----
Expanded for more details
![expand_details_features](http://i.imgur.com/tZtbA8R.png)
![expand_details_step_definitions](http://i.imgur.com/O1aBepe.png)
----

Submitting Issues
-----
To submit an issue you have found in CukeSniffer, please use the GitHub issue page for this gem.
