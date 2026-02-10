% Specify library and custom library paths.
% 
% Copyright 2025 The MathWorks, Inc.

%% Define custom library path
customBlkPath.roomVol = "RoomVolume_lib/Room Volume";
customBlkPath.extWall = "ExternalWall_lib/Wall External";
customBlkPath.selectWall = "WallSelector_lib/Wall Selector";
customBlkPath.roomRadUFP = "RoomWithRadiatorAndUFP/Room, Radiator, and Under-floor Piping";
customBlkPath.roomRad = "RoomWithRadiator/Room with Radiator";
customBlkPath.roomUFP = "RoomWithUFP/Room with Under-floor Piping";
customBlkPath.roomOnly = "RoomWithAirVolume/Room with Air Volume";
customBlkPath.solar = "SolarRadiationAtLocation_lib/Solar Radiation (LUT)";
customBlkPath.thermal = "TemperatureSource_lib/Temperature Source (LUT)";
customBlkPath.heatSourceControl = "HeatSourceControl/Heat Source Control";
customBlkPath.dailyScheduler = "DayScheduler_lib/Day Scheduler";
customBlkPath.heatPumpTL = "AirWaterHeatPumpTL/Air Water Heat Pump (TL)";

%% Define product library path
libBlkPath.thermalRes = "fl_lib/Thermal/Thermal Elements/Thermal Resistance";
libBlkPath.arrayConn = "nesl_utility/Array Connection";
libBlkPath.labelConn = "nesl_utility/Connection Label";
libBlkPath.connPort = "nesl_utility/Connection Port";
libBlkPath.concatPS = "fl_lib/Physical Signals/Functions/PS Concatenate";
libBlkPath.selectorPS = "fl_lib/Physical Signals/Nonlinear Operators/PS Selector";
libBlkPath.gainBlock = "fl_lib/Physical Signals/Functions/PS Gain";
libBlkPath.convHeatTransfer = "fl_lib/Thermal/Thermal Elements/Convective Heat Transfer";
libBlkPath.insulator = "fl_lib/Thermal/Thermal Elements/Perfect Insulator";
libBlkPath.addition = "fl_lib/Physical Signals/Functions/PS Add";
libBlkPath.pipe = "fl_lib/Thermal Liquid/Elements/Pipe (TL)";
libBlkPath.temperature = "fl_lib/Thermal/Thermal Sources/Temperature Source";