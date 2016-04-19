describe("CukeSniffer", function(){
    beforeEach(function(){
        CukeSniffer.init();
        $.fx.off = true;
        loadFixtures("complex_report.html.erb");
    });
    afterEach(function(){
        $(document).off("click", "[expand]");
        $(document).off("click", "[collapse]");
        $(document).off("click", ".panel-title");
        $(document).off("click", "#rulesTab");
        $(document).off("click", ".rule");
        $(document).off("click", ".rule :checkbox");
        $(document).off("click", "#ruleFilters .btn");
        $(document).off("click", ".deadStep > .row > .title," +
            " .feature > .row > .title, " +
            ".stepDefinition > .row > .title, " +
            ".hook .title");
        $(document).off("click", "#enableAllRules");
        $(document).off("click", "#disableAllRules");
        $(document).off("click", ".rule input[type='checkbox']");
    });
    describe("Rules", function(){
        describe("collapsing/expanding", function(){
            it("clicking expand all shows all rules", function(){
                $("[expand]").click()
                expect($(".rule .details")).toBeVisible();
            });
            it("clicking collapse all hides all rules", function(){
                $("[expand]").click()
                expect($(".rule .details")).toBeVisible();
                $("[collapse]").click()
                expect($(".rule .details")).not.toBeVisible();
            });
            it("clicking a rules expands its details", function(){
                var $rule = $(".rule:eq(0)");
                $rule.find("div:has([data-phrase])").click();
                expect($rule.find(".details")).toBeVisible();
            });
            it("clicking the checkbox for a rule does not expand it's details", function(){
                var $rule = $(".rule:eq(0)");
                $rule.find(":checkbox").click();
                expect($rule.find(".details")).not.toBeVisible();
            });
            it("clicking a rules again collapses its details", function(){
                var $rule = $(".rule:eq(0)");
                $rule.find("div:has([data-phrase])").click();
                expect($rule.find(".details")).toBeVisible();
                $rule.find("div:has([data-phrase])").click();
                expect($rule.find(".details")).not.toBeVisible();
            });
        });

        describe("filtering the rules", function(){
            describe("by type", function(){
                describe("feature filter", function(){
                    it("hides all feature only rules when unchecked", function(){
                        var $featureFilter = $(".btn:has([data-rule-type='feature'])")
                        $featureFilter.click();
                        expect($("[rule-feature]:not([rule-scenario], [rule-background])")).toBeHidden();
                        expect($("[rule-feature][rule-scenario]")).toBeVisible();
                        expect($("[rule-feature][rule-background]")).toBeVisible();
                    });
                    it("shows all feature rules when checked", function(){
                        var $featureFilter = $(".btn:has([data-rule-type='feature'])")
                        $featureFilter.click();
                        expect($("[rule-feature]:not([rule-scenario], [rule-background])")).toBeHidden();
                        $featureFilter.click();
                        expect($("[rule-feature]:not([rule-scenario], [rule-background])")).toBeVisible();
                    });
                });
                describe("background filter", function(){
                    it("hides all background only rules when unchecked", function(){
                        var $backgroundFilter = $(".btn:has([data-rule-type='background'])")
                        $backgroundFilter.click();
                        expect($("[rule-background]:not([rule-scenario], [rule-feature])")).toBeHidden();
                        expect($("[rule-background][rule-scenario]")).toBeVisible();
                        expect($("[rule-background][rule-feature]")).toBeVisible();
                    });
                    it("shows all background rules when checked", function(){
                        var $backgroundFilter = $(".btn:has([data-rule-type='background'])")
                        $backgroundFilter.click();
                        expect($("[rule-background]:not([rule-scenario], [rule-feature])")).toBeHidden();
                        $backgroundFilter.click();
                        expect($("[rule-background]:not([rule-scenario], [rule-feature])")).toBeVisible();
                    });
                });
                describe("scenario filter", function(){
                    it("hides all scenario only rules when unchecked", function(){
                        var $scenarioFilter = $(".btn:has([data-rule-type='scenario'])")
                        $scenarioFilter.click();
                        expect($("[rule-scenario]:not([rule-background], [rule-feature])")).toBeHidden();
                        expect($("[rule-scenario][rule-background]")).toBeVisible();
                        expect($("[rule-scenario][rule-feature]")).toBeVisible();
                    });
                    it("shows all scenario rules when checked", function(){
                        var $scenarioFilter = $(".btn:has([data-rule-type='scenario'])")
                        $scenarioFilter.click();
                        expect($("[rule-scenario]:not([rule-background], [rule-feature])")).toBeHidden();
                        $scenarioFilter.click();
                        expect($("[rule-scenario]:not([rule-background], [rule-feature])")).toBeVisible();
                    });
                });
                describe("step definition filter", function(){
                    it("hides all step definition only rules when unchecked", function(){
                        var $stepDefinitionFilter = $(".btn:has([data-rule-type='stepdefinition'])")
                        $stepDefinitionFilter.click();
                        expect($("[rule-stepdefinition]")).toBeHidden();
                    });
                    it("shows all step definition rules when checked", function(){
                        var $stepDefinitionFilter = $(".btn:has([data-rule-type='stepdefinition'])")
                        $stepDefinitionFilter.click();
                        expect($("[rule-stepdefinition]")).toBeHidden();
                        $stepDefinitionFilter.click();
                        expect($("[rule-stepdefinition]")).toBeVisible();
                    });
                });
                describe("hook filter", function(){
                    it("hides all hook only rules when unchecked", function(){
                        var $hookFilter = $(".btn:has([data-rule-type='hook'])")
                        $hookFilter.click();
                        expect($("[rule-hook]")).toBeHidden();
                    });
                    it("shows all hook rules when checked", function(){
                        var $hookFilter = $(".btn:has([data-rule-type='hook'])")
                        $hookFilter.click();
                        expect($("[rule-hook]")).toBeHidden();
                        $hookFilter.click();
                        expect($("[rule-hook]")).toBeVisible();
                    });
                });
                it("remembers the type filter status as a cookie", function(){

                });
            });
            describe("by severity", function(){
                describe("info filter", function(){
                    it("hides all info level rules when unchecked", function(){

                    });
                    it("shows all info level rules when checked", function(){

                    });
                });
                describe("warning filter", function(){
                    it("hides all warning level rules when unchecked", function(){

                    });
                    it("shows all warning level rules when checked", function(){

                    });
                });
                describe("error filter", function(){
                    it("hides all error level rules when unchecked", function(){

                    });
                    it("shows all error level rules when checked", function(){

                    });
                });
                describe("fatal filter", function(){
                    it("hides all fatal level rules when unchecked", function(){

                    });
                    it("shows all fatal level rules when checked", function(){

                    });
                });
                it("remembers the severity filter status as a cookie", function(){

                });
            });
            describe("by text", function(){
                it("will filter the rules description on a keypress", function(){

                });
                it("will filter the rules details on a keypress", function(){

                });
                it("will clear the search when the input is cleared", function(){

                });
            });
        });

        describe("toggling rules", function(){
            describe("features section", function(){
                describe("disabling", function(){
                    it("will hide feature rules when uncheck unchecked", function(){

                    });

                    it("will hide background rules when unchecked", function(){

                    });

                    it("will hide the background section when its last rule is disabled", function() {

                    });

                    it("will hide scenario rules when unchecked", function(){

                    });

                    it("will hide the scenario section when its last rule is disabled", function() {

                    });

                    it("will hide the scenarios section when the last scenario is hidden due to disabled rules", function(){

                    });

                    it("will hide the feature row when there are no active rules being shown for the feature, background, or scenarios", function(){

                    });
                });
                describe("enabling", function(){
                    it("does nothing when a rule checkbox is disabled due to report generation configuration", function(){

                    });
                    it("shows a feature row when a feature rule is enabled and no other rules apply", function(){

                    });
                    it("shows a feature row when a background rule is enabled and no other rules apply", function(){

                    });
                    it("shows a feature row when a scenario rule is enabled and no other rules apply", function(){

                    });
                });
            });
            describe("step definitions section", function(){
                describe("disabling", function(){
                    it("hides a step definition rule when its rule is disabled", function(){

                    });
                    it("hides the step definition row when its last rule is disabled", function(){

                    });
                });
                describe("enabling", function(){
                    it("shows a step definition rule when its rule is enabled", function(){

                    });
                    it("shows the step definition row when its first rule is enabled", function(){

                    });
                });
            });
            describe("hooks section", function(){
                describe("disabling", function(){
                    it("hides a hook rule when its rule is disabled", function(){

                    });
                    it("hides the hook row when its last rule is disabled", function(){

                    });
                });
                describe("enabling", function(){
                    it("shows a hook rule when its rule is enabled", function(){

                    });
                    it("shows the hook row when its first rule is enabled", function(){

                    });
                });
            });
            it("remembers the disabled rules as a cookie", function(){

            });
        })
    });
    describe("Dead Step Definitions", function(){
        describe("collapsing/expanding", function(){
            it("clicking expand all shows all dead step", function(){
                $("[expand]").click()
                expect($(".deadStep > .row > .details")).toBeVisible();
            });
            it("clicking collapse all hides all dead step", function(){
                $("[expand]").click()
                expect($(".deadStep > .row > .details")).toBeVisible();
                $("[collapse]").click()
                expect($(".deadStep > .row > .details")).not.toBeVisible();
            });
            it("clicking a dead step expands its details", function(){
                var $deadStep = $(".deadStep:eq(0)");
                $deadStep.find("> .row > .title").click();
                expect($deadStep.find("> .row > .details")).toBeVisible();
            });
            it("clicking a dead step again collapses its details", function(){
                var $deadStep = $(".deadStep:eq(0)");
                $deadStep.find("> .row > .title").click();
                expect($deadStep.find(".details")).toBeVisible();
                $deadStep.find("> .row > .title").click();
                expect($deadStep.find(".details")).not.toBeVisible();
            });
        });
    });
    describe("Features", function(){
        describe("collapsing/expanding", function(){
            it("clicking expand all shows all features", function(){
                $("[expand]").click()
                expect($(".feature > .row > .details")).toBeVisible();
            });
            it("clicking collapse all hides all features", function(){
                $("[expand]").click()
                expect($(".feature > .row > .details")).toBeVisible();
                $("[collapse]").click()
                expect($(".feature > .row > .details")).not.toBeVisible();
            });
            it("clicking a feature expands its details", function(){
                var $feature = $(".feature:eq(0)");
                $feature.find("> .row > .title").click();
                expect($feature.find("> .row > .details")).toBeVisible();
            });
            it("clicking a feature again collapses its details", function(){
                var $feature = $(".feature:eq(0)");
                $feature.find("> .row > .title").click();
                expect($feature.find(".details")).toBeVisible();
                $feature.find("> .row > .title").click();
                expect($feature.find(".details")).not.toBeVisible();
            });
        });
    });
    describe("Step Definitions", function(){
        describe("collapsing/expanding", function(){
            it("clicking expand all shows all step definitions", function(){
                $("[expand]").click()
                expect($(".stepDefinition > .row > .details")).toBeVisible();
            });
            it("clicking collapse all hides all step definitions", function(){
                $("[expand]").click()
                expect($(".stepDefinition > .row > .details")).toBeVisible();
                $("[collapse]").click()
                expect($(".stepDefinition > .row > .details")).not.toBeVisible();
            });
            it("clicking a step definitions expands its details", function(){
                var $stepDefinition = $(".stepDefinition:eq(0)");
                $stepDefinition.find("> .row > .title").click();
                expect($stepDefinition.find("> .row > .details")).toBeVisible();
            });
            it("clicking a step definitions again collapses its details", function(){
                var $stepDefinition = $(".stepDefinition:eq(0)");
                $stepDefinition.find("> .row > .title").click();
                expect($stepDefinition.find(".details")).toBeVisible();
                $stepDefinition.find("> .row > .title").click();
                expect($stepDefinition.find(".details")).not.toBeVisible();
            });
        });
    });
    describe("Hooks", function(){
        describe("collapsing/expanding", function(){
            it("clicking expand all shows all hooks", function(){
                $("[expand]").click()
                expect($(".hook .details")).toBeVisible();
            });
            it("clicking collapse all hides all hooks", function(){
                $("[expand]").click()
                expect($(".hook .details")).toBeVisible();
                $("[collapse]").click()
                expect($(".hook .details")).not.toBeVisible();
            });
            it("clicking a hook expands its details", function(){
                var $hook = $(".hook:eq(0)");
                $hook.find(".title").click();
                expect($hook.find(".details")).toBeVisible();
            });
            it("clicking a hook again collapses its details", function(){
                var $hook = $(".hook:eq(0)");
                $hook.find(".title").click();
                expect($hook.find(".details")).toBeVisible();
                $hook.find(".title").click();
                expect($hook.find(".details")).not.toBeVisible();
            });
        });
    });
});