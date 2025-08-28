classdef BuildingEnergyManagementLibTest < matlab.unittest.TestCase
    %% Class implementation of unit test

    % Copyright 2025 The MathWorks, Inc.

    properties
        openfigureListBefore;
    end

    properties(TestParameter)
        testModels = getFilenameListInDirectory("TestHarness");
    end

    methods(TestMethodSetup)
        function listOpenFigures(test)
            % List all open figures
            test.openfigureListBefore = findall(0,'Type','Figure');
        end

        function setupWorkingFolder(test)
            % Set up working folder
            import matlab.unittest.fixtures.WorkingFolderFixture;
            test.applyFixture(WorkingFolderFixture);
        end
    end

    methods (Test)
        function TestBuildingModelLibraries(testCase,testModels)
            mdl = testModels;
            load_system(mdl)
            testCase.addTeardown(@()close_system(mdl,0));
            sim(mdl);
            close all;
            bdclose all;
        end
    end

end  % classdef
