% Unit Test Driver Script for Building Energy Management Design Solution 

% Copyright 2024 - 2025 The MathWorks, Inc.

relstr = matlabRelease().Release;
disp("This MATLAB Release: " + relstr)
prjRoot = currentProject().RootFolder;

%% Suite and Runner
BEMSsuite = matlab.unittest.TestSuite.fromFile(fullfile(prjRoot, "Test", "BuildingEnergyManagementMQC.m"));
suite = BEMSsuite;
runner = matlab.unittest.TestRunner.withTextOutput( ...
  OutputDetail = matlab.unittest.Verbosity.Detailed);

%% JUnit Style Test Result
plugin = matlab.unittest.plugins.XMLPlugin.producingJUnitFormat( ...
  fullfile(prjRoot, "Test", ("TestResultsModelScripts_" + relstr + ".xml")));
addPlugin(runner, plugin)

%% Code Coverage Report Plugin
coverageReportFolder = fullfile(prjRoot, "Test", ("CodeCoverage_" + relstr));
if ~isfolder(coverageReportFolder)
  mkdir(coverageReportFolder)
end
coverageReport = matlab.unittest.plugins.codecoverage.CoverageReport(coverageReportFolder, MainFile = "BEMSCoverage_" + relstr + ".html" );

%% Code Coverage Plugin
list1 = dir(fullfile(prjRoot, "Components","WorkflowUtilities","BuildingCreator"));
list1 = list1(~[list1.isdir] & endsWith({list1.name}, '.m'));
list2 = dir(fullfile(prjRoot, "Components","WorkflowUtilities","BuildingDesign"));
list2 = list2(~[list2.isdir] & endsWith({list2.name}, '.m'));
list3 = dir(fullfile(prjRoot, "Components","WorkflowUtilities","BuildingImport","IFCtoSimscape"));
list3 = list3(~[list3.isdir] & endsWith({list3.name}, '.m'));
list4 = dir(fullfile(prjRoot, "Components","WorkflowUtilities","DatacenterModel"));
list4 = list4(~[list4.isdir] & endsWith({list4.name}, '.m'));
list5 = dir(fullfile(prjRoot, "Components","WorkflowUtilities","Misc"));
list5 = list5(~[list5.isdir] & endsWith({list5.name}, '.m'));
fullList = [list1;list2;list3;list4;list5];

fileList = arrayfun(@(x)[x.folder, filesep, x.name], fullList, "UniformOutput", false);
codeCoveragePlugin = matlab.unittest.plugins.CodeCoveragePlugin.forFile(fileList, Producing = coverageReport );
addPlugin(runner, codeCoveragePlugin);

%% Run tests
results = run(runner, suite);
testMQCruns = assertSuccess(results);
disp(testMQCruns);
