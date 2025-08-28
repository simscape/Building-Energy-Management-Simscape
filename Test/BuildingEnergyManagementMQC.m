classdef BuildingEnergyManagementMQC < matlab.unittest.TestCase
    %% Class implementation of unit test

    % Copyright 2024 The MathWorks, Inc.

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
        
        function TestBuildingModelWithSolarLoad(testCase)
            mdl = "BuildingModelWithSolarLoad";
            load_system(mdl)
            testCase.addTeardown(@()close_system(mdl,0));
            set_param(mdl,'StopTime','7200');
            sim(mdl);
            close all;
            bdclose all;
        end

        function TestBuildingTestHarness(testCase)
            mdl = "BuildingTestHarness";
            load_system(mdl)
            testCase.addTeardown(@()close_system(mdl,0));
            sim(mdl);
            close all;
            bdclose all;
        end

        function TestHeatPumpTestHarness(testCase)
            mdl = "HeatPumpTestHarness";
            load_system(mdl)
            testCase.addTeardown(@()close_system(mdl,0));
            sim(mdl);
            close all;
            bdclose all;
        end

        function TestSunModelTestHarness(test)
            %The test runs the |.mlx| file and makes sure that there are
            %no errors or warning thrown.
            test.verifyWarningFree(@()runSunModelTestHarness, "'SunModelTestHarness Live Script'  should execute wihtout any warning or error.");
        end

        function TestCreateBuildingModelWithSolarLoad(test)
            %The test runs the |.mlx| file and makes sure that there are
            %no errors or warning thrown.
            test.verifyWarningFree(@()runCreateBuildingModelWithSolarLoad, "'CreateBuildingModelWithSolarLoad Live Script'  should execute wihtout any warning or error.");
        end

        function TestBuildingManagementSystemRequirementAnalysis(test)
            %The test runs the |.mlx| file and makes sure that there are
            %no errors or warning thrown.
            test.verifyWarningFree(@()runBuildingManagementSystemRequirementAnalysis, "'BuildingManagementSystemRequirementAnalysis Live Script'  should execute wihtout any warning or error.");
        end

        function TestSimulateBuildingEnergyManagement(test)
            %The test runs the |.mlx| file and makes sure that there are
            %no errors or warning thrown.
            test.verifyWarningFree(@()runSimulateBuildingEnergyManagement, "'SimulateBuildingEnergyManagement Live Script'  should execute wihtout any warning or error.");
        end

        function TestBuildingHeatLoadEstimation(test)
            %The test runs the |.mlx| file and makes sure that there are
            %no errors or warning thrown.
            test.verifyWarningFree(@()runBuildingHeatLoadEstimation, "'BuildingHeatLoadEstimation Live Script'  should execute wihtout any warning or error.");
        end

        function TestImportBIMforHeatLoadAnalysis(test)
            %The test runs the |.mlx| file and makes sure that there are
            %no errors or warning thrown.
            test.verifyWarningFree(@()runImportBIMforHeatLoadAnalysis, "'ImportBIMforHeatLoadAnalysis Live Script'  should execute wihtout any warning or error.");
        end

        function TestDetailedHouseModel(test)
            %The test runs the |.mlx| file and makes sure that there are
            %no errors or warning thrown.
            test.verifyWarningFree(@()runDetailedHouseModelUsingCustomLib, "'DetailedHouseModelUsingCustomLib Live Script'  should execute wihtout any warning or error.");
        end
    end

end  % classdef

function runSunModelTestHarness()
    % Function runs the |.mlx| script.
    warning("off"); % Passes in local machine, throws warning online - Identifier: "MATLAB:hg:AutoSoftwareOpenGL"
    SunModelTestHarness;
    close all;
    bdclose all;
end

function runCreateBuildingModelWithSolarLoad()
    % Function runs the |.mlx| script.
    warning("off"); % Passes in local machine, throws warning online - Identifier: "MATLAB:hg:AutoSoftwareOpenGL"
    CreateBuildingModelWithSolarLoad;
    close all;
    bdclose all;
end

function runBuildingManagementSystemRequirementAnalysis()
    % Function runs the |.mlx| script.
    warning("off"); % Passes in local machine, throws warning online - Identifier: "MATLAB:hg:AutoSoftwareOpenGL"
    BuildingManagementSystemRequirementAnalysis;
    close all;
    bdclose all;
end

function runSimulateBuildingEnergyManagement()
    % Function runs the |.mlx| script.
    warning("off"); % Passes in local machine, throws warning online - Identifier: "MATLAB:hg:AutoSoftwareOpenGL"
    SimulateBuildingEnergyManagement;
    close all;
    bdclose all;
end

function runBuildingHeatLoadEstimation()
    % Function runs the |.mlx| script.
    warning("off"); % Passes in local machine, throws warning online - Identifier: "MATLAB:hg:AutoSoftwareOpenGL"
    BuildingHeatLoadEstimation;
    close all;
    bdclose all;
end

function runImportBIMforHeatLoadAnalysis()
    % Function runs the |.mlx| script.
    warning("off"); % Passes in local machine, throws warning online - Identifier: "MATLAB:hg:AutoSoftwareOpenGL"
    ImportBIMforHeatLoadAnalysis;
    close all;
    bdclose all;
end

function runDetailedHouseModelUsingCustomLib()
    % Function runs the |.mlx| script.
    warning("off"); % Passes in local machine, throws warning online - Identifier: "MATLAB:hg:AutoSoftwareOpenGL"
    DetailedHouseModelUsingCustomLib;
    close all;
    bdclose all;
end
