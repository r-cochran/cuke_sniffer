@wip @john_in_progress @robert_in_progress @12832
@do_not_run
Feature: Story Card (1234528) Login

  @wip @john_in_progress @OH @KY
  Scenario: I can log in to the system
    Given I type my user name in the text box
    Given I type my password in the text box
    When I push the login button
    Then I am taken to the welcome page

  @wip @john_in_progress

  Scenario: I can't log into the system
    Given I type my user name in the text box
    Given I type my password in the text box
    When I push the login button
    Then I am left on the login screen
    And I get a warning pop up that says I have "Incorrect username or password"

  @wip @robert_in_progress

  @OH
  Scenario: Login
    Given I am logged in
    Then I am already logged in
    And I am on the welcome page
    When I have a name Bob Bobert
    Then I see the label "Welcome, Bob Bobert"
    And I can click a logout button

  @wip @robert_in_progress

  @KY
  Scenario: Login
    Given I am logged in
    Then I am already logged in
    And I am on the welcome page
    When I have a name Bob Bobert
    Then I see the label "Welcome, Bob Bobert"
    And I can click a logout button

  @john_in_prog
  Scenario Outline:
    Given I type the username <name> in the "username" text box
    Given I type the password <password> in the "password" text box
    Then I am <status> in
  Examples:
    | name | password | status     |
    | Bob  | Bobert   | not logged |