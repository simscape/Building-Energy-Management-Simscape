% Unit Test Driver Script for Building Energy Management Design Solution 

% Copyright 2024 The MathWorks, Inc.

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
list1 = dir(fullfile(prjRoot, 'utils'));
list1 = list1(~[list1.isdir] & endsWith({list1.name}, {'.m', '.mlx'}));

fileList = arrayfun(@(x)[x.folder, filesep, x.name], list1, 'UniformOutput', false);
codeCoveragePlugin = matlab.unittest.plugins.CodeCoveragePlugin.forFile(fileList, Producing = coverageReport );
addPlugin(runner, codeCoveragePlugin);

%% Run tests
results = run(runner, suite);
out = assertSuccess(results);
disp(out);
