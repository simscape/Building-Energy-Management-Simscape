 function config = testConfig()
% testConfig - Test configuration for the repository

% Copyright 2026 The MathWorks, Inc.

%% Get project Root
try
    projectRoot = string(currentProject().RootFolder);
catch
    try
        prj = matlab.project.loadProject(pwd);
        projectRoot = string(prj.RootFolder);
    catch
        error("testConfig:NoProject", ...
            "Could not resolve ProjectRoot. Open the MATLAB project or run from the project root.");
    end
end

%% Project Root
config.ProjectRoot = projectRoot;

%% Model Discovery
config.Models.IncludeDirectories = [fullfile("Workflow"), fullfile("Components","Test","TestHarness")]; %#ok<*NBRAK2>
config.Models.IncludeFiles = string.empty;
config.Models.FileTypes = ["SLX-file"; "MDL-file"];
config.Models.ExcludeDirectories = [fullfile("Workflow","BuildingPowerManagement")];
config.Models.ExcludeFiles = string.empty;

%% Workflow Discovery
config.Workflows.IncludeDirectories = ["Workflow"];
config.Workflows.IncludeFiles = string.empty;
config.Workflows.FileTypes = ["MLX-file"; "M-file"];
config.Workflows.ExcludeDirectories = [ fullfile("Workflow","BuildHeatLoadCalculation"),...
                                        fullfile("Workflow","DetailedHouseModel")];
config.Workflows.ExcludeFiles = string.empty;

%% Custom Tests
config.CustomTests.Files = string.empty;
config.CustomTests.Directories = string.empty;

%% Code Coverage
config.CodeCoverage.IncludeDirectories = ["Workflow", fullfile("Components","WorkflowUtilities")];
config.CodeCoverage.IncludeFiles = string.empty;
config.CodeCoverage.FileTypes = ["M-file"; "MLX-file"];
config.CodeCoverage.ExcludeDirectories = "Test";
config.CodeCoverage.ExcludeFiles = string.empty;

%% Reporting
config.Reports.FolderName = "BuildingEnergyManagement";
config.Reports.GenerateJUnitXML = true;
config.Reports.GenerateHTMLReport = true;
config.Reports.GenerateCodeCoverage = true;
config.Reports.OpenInBrowser = false;

%% Warning Suppression
config.SuppressedWarnings = ["MATLAB:hg:AutoSoftwareOpenGL"];

end