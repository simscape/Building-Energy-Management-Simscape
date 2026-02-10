classdef BuildingEnergyManagementMQC < matlab.unittest.TestCase
    %% Class implementation of unit test

    % Copyright 2024 - 2025 The MathWorks, Inc.

   properties
        workingFolderFixture;
        openfigureListBefore;
        openModelsBefore;
    end

    properties(TestParameter)
        testModels = getFilenameListInDirectory(["Components","Test","TestHarness"]);
    end

    methods (TestClassSetup)

        function setupWorkingFolder(testCase)
            % Set up working folder
            import matlab.unittest.fixtures.WorkingFolderFixture;
            testCase.workingFolderFixture = testCase.applyFixture(WorkingFolderFixture);
        end

        function suppressWarning_AutoSoftwareOpenGL(testCase)
            % Suppress known warnings
            import matlab.unittest.fixtures.SuppressedWarningsFixture
            testCase.applyFixture(SuppressedWarningsFixture("MATLAB:hg:AutoSoftwareOpenGL"))
        end

    end

    methods(TestMethodSetup)

        function listOpenFigures(test)
            % List all open figures
            test.openfigureListBefore = findall(0,'Type','Figure');
        end

    end

    methods(TestMethodTeardown)

        function closeOpenedFigures(testCase)
            % Close all figure opened during test
            figureListAfter = findall(0,'Type','Figure');
            figuresOpenedByTest = setdiff(figureListAfter, testCase.openfigureListBefore);
            arrayfun(@close, figuresOpenedByTest);
        end

        function closeOpenedModels(testCase)
            % Close all models opened during test
            openModelsAfter = get_param(Simulink.allBlockDiagrams(),'Name');
            modelsOpenedByTest = setdiff(openModelsAfter, testCase.openModelsBefore);
            close_system(modelsOpenedByTest, 0);
        end

    end

    methods (Test)

        function TestBuildingModelLibraries(testCase,testModels)
            mdl = testModels;
            load_system(mdl)
            testCase.addTeardown(@()close_system(mdl,0));
            sim(mdl);
        end
        
        function TestCreateBuildingModelPartFromBIM(test)
            %The test runs the |.mlx| file and makes sure that there are
            %no errors or warning thrown.
            test.verifyWarningFree(@()runCreateBuildingModelPartFromBIM, "'CreateBuildingModelPartFromBIM Live Script'  should execute wihtout any warning or error.");
        end

        function TestCreateBuildingModelPart(test)
            %The test runs the |.mlx| file and makes sure that there are
            %no errors or warning thrown.
            test.verifyWarningFree(@()runCreateBuildingModelPart, "'CreateBuildingModelPart Live Script'  should execute wihtout any warning or error.");
        end

        function TestCreateBuildingSimscapeLibrary(test)
            %The test runs the |.mlx| file and makes sure that there are
            %no errors or warning thrown.
            test.verifyWarningFree(@()runCreateBuildingSimscapeLibrary, "'CreateBuildingSimscapeLibrary Live Script'  should execute wihtout any warning or error.");
        end

        function TestCreateBuildingSimscapeSystemModel(test)
            %The test runs the |.mlx| file and makes sure that there are
            %no errors or warning thrown.
            test.verifyWarningFree(@()runCreateBuildingSimscapeSystemModel, "'CreateBuildingSimscapeSystemModel Live Script'  should execute wihtout any warning or error.");
        end

        function TestCreateBuildingUsingCustomLibraryBlocks(test)
            %The test runs the |.mlx| file and makes sure that there are
            %no errors or warning thrown.
            test.verifyWarningFree(@()runCreateBuildingUsingCustomLibraryBlocks, "'CreateBuildingUsingCustomLibraryBlocks Live Script'  should execute wihtout any warning or error.");
        end

        function TestEstimateRequirementsBuildingHVAC(test)
            %The test runs the |.mlx| file and makes sure that there are
            %no errors or warning thrown.
            test.verifyWarningFree(@()runEstimateRequirementsBuildingHVAC, "'EstimateRequirementsBuildingHVAC Live Script'  should execute wihtout any warning or error.");
        end

        function TestCreateDatacenterForUtilizationAnalysis(test)
            %The test runs the |.mlx| file and makes sure that there are
            %no errors or warning thrown.
            test.verifyWarningFree(@()runCreateDatacenterForUtilizationAnalysis, "'CreateDatacenterForUtilizationAnalysis Live Script'  should execute wihtout any warning or error.");
        end

    end

end  % classdef

function runCreateBuildingModelPartFromBIM()
    % Function runs the |.mlx| script.
    CreateBuildingModelPartFromBIM;

end

function runCreateBuildingModelPart()
    % Function runs the |.mlx| script.
    CreateBuildingModelPart;
end

function runCreateBuildingSimscapeLibrary()
    % Function runs the |.mlx| script.
    CreateBuildingSimscapeLibrary;
end

function runCreateBuildingSimscapeSystemModel()
    % Function runs the |.mlx| script.
    CreateBuildingSimscapeSystemModel;
end

function runCreateBuildingUsingCustomLibraryBlocks()
    % Function runs the |.mlx| script.
    CreateBuildingUsingCustomLibraryBlocks;
end

function runEstimateRequirementsBuildingHVAC()
    % Function runs the |.mlx| script.
    EstimateRequirementsBuildingHVAC;
end

function runCreateDatacenterForUtilizationAnalysis()
    % Function runs the |.mlx| script.
    CreateDatacenterForUtilizationAnalysis;
end