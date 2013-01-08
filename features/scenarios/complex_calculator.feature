Feature: Complex Calculator

  Scenario: Add two numbers
    Given the first number is "1"
    And the second number is "1"
    When the calculator adds
    Then the result is "2"