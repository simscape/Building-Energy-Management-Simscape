% Script to generate Air Water Heat Pump (AWHP) model SSC code.

% Copyright 2024 The MathWorks, Inc.

% Load Model
load_system('AWHPModel')

subsystem2ssc('AWHPModel/AirWaterHeatPump')

% Close Model
close_system('AWHPModel')
