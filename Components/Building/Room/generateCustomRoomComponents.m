% Script to generate building room heating and cooling models.

% Copyright 2024 The MathWorks, Inc.

% Load Model
load_system('RoomHeaterModel')

% Generate SSC code for rooms (heating elements)
subsystem2ssc('RoomHeaterModel/RoomUnderFloorPiping');
subsystem2ssc('RoomHeaterModel/RoomRadiatorPiping');

% Close Model
close_system('RoomHeaterModel')

