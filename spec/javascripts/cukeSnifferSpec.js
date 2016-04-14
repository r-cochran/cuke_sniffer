describe("CukeSniffer", function(){
    describe("Rules", function(){

    });
    describe("Dead Step Definitions", function(){

    });
    describe("Features", function(){
        beforeEach(function(){
            loadFixtures("features.html.erb");
        });
        it("test for ci to work", function(){
            expect(1).toBe(1)
        })
    });
    describe("Step Definitions", function(){

    });
    describe("Hooks", function(){

    });
});