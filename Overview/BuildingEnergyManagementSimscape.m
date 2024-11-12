%% Building Energy Management System with Simscape
% 
% This project contains custom libraries, models, and code to help 
% you analyze a building energy HVAC requirements and design controllers
% for building energy managmement systems, BEMS.
%

% Copyright 2024 The MathWorks, Inc.

%%
% Building energy management is an important step when addressing energy 
% goals and the transition to clean energy. Enhanced energy management in 
% buildings supports the transition to renewable energy sources, aids in 
% the global commitment to limit temperature rise, and combats climate
% change. In this project, you will learn how to create a system-level 
% model using Simscape(TM) and Simscape Fluids(TM) to assess building HVAC 
% needs and develop BEMS.
% 
% 
% The end of this document contains a workflow representation. Live Script 
% based workflows are used to parameterize Simscape Custom components for 
% building energy simulations.
%
%% Create Building Model with Solar Loads
% 
% * To learn how to create buildings quickly and define solar loading on
% them, see <matlab:open('CreateBuildingModelWithSolarLoad.mlx') Create 
% Building Model with Solar Loads>. 
% 
% In this workflow, you will learn how to define rooms, create apartments, 
% and construct a 3D building. At the end of the workflow, you will be able 
% to save your building definition in a XML part and use it later or share 
% with others.
% 
%% Run Building Model for HVAC Requirement Analysis
% 
% * To learn how to evaluate HVAC requirements for a building, see 
% <matlab:open('BuildingManagementSystemRequirementAnalysis.mlx') Simulate 
% Building Model for HVAC Requirement Analysis> to open and run the live 
% script. 
% 
% The live script opens the Simscape Model which you can run and analyze 
% the results. To enable the post-processing functions to work in the live 
% script, you must run the model programatically, as shown in code example. 
% This model uses two different custom Simscape blocks - the *Building* and 
% the *Ambient* block. To learn more about each custom block, open the block 
% mask and see the documentation link.
% 
%% Setup Building Model for BEMS Design
% 
% * To learn how to evaluate actual energy consumption and design
% controllers, see <matlab:open('SimulateBuildingEnergyManagement.mlx') 
% Simulate Building Model for BEMS Design>. This will open a live script 
% which sets up the model, parameterizes it, and opens the model to run.
% 
% This is a detailed model that uses four different custom Simscape blocks -
% the *Building* , the *Heat Pump* , the *Ambient* , and the *Operational 
% Data* blocks. To learn more about each custom block, open the block mask and 
% see the documentation link.
% 
% In this example, you will also learn how to use a air-water heat pump 
% (AWHP) to maintain a desired set-point temperature within the building 
% rooms. You will be able to specify different conditions for different 
% rooms by using a physics table data. You will learn how to specify 
% different heating or cooling options within a room: radiator, under-floor 
% piping, or both. 

%% Appendix A: Custom Component Documentation
% To learn more about the different custom components used in the simulation: 
% 
% * See <matlab:open('DocumentationCustomBlockBuilding.html') Building 
% Model Documentation> to learn more about the building custom component.
% * See <matlab:open('DocumentationCustomBlockAmbient.html') Ambient 
% Model Documentation> to learn more about the ambient model custom 
% component.
% * See <matlab:open('DocumentationHeatPumpBlock.html') Heat Pump Model 
% Documentation> to learn more about the datasheet (EN14511) based heat 
% pump models.
% * See <matlab:open('DocumentationBuildingOperation.html') Building 
% Operational Data Documentation> to learn more about the block.
%
%% Appendix B: Overall Workflow Pictorial
% 
% <<../Images/overallSummaryBuildingSim.png>>
% 