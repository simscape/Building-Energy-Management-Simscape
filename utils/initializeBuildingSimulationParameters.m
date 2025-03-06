function [physTable,opsParams] = initializeBuildingSimulationParameters(NameValueArgs)
% Function to initialize parameters for building simulations.

% Copyright 2025 The MathWorks, Inc.

    arguments
        NameValueArgs.Building struct {mustBeNonempty}
        NameValueArgs.Location (1,3) table {mustBeNonempty}
        NameValueArgs.DateTimeVec datetime {mustBeNonempty}
        NameValueArgs.RoomTsetPoint (1,1) simscape.Value {simscape.mustBeCommensurateUnit(NameValueArgs.RoomTsetPoint, "K")}
        NameValueArgs.DayTemperature (1,:) simscape.Value {simscape.mustBeCommensurateUnit(NameValueArgs.DayTemperature, "K")}
        NameValueArgs.NightTemperature (1,:) simscape.Value {simscape.mustBeCommensurateUnit(NameValueArgs.NightTemperature, "K")}
        NameValueArgs.DayTemperatureVar (1,1) {mustBeNonempty} = 1
        NameValueArgs.NightTemperatureVar (1,1) {mustBeNonempty} = 1
        NameValueArgs.GroundResistance (1,1) simscape.Value {simscape.mustBeCommensurateUnit(NameValueArgs.GroundResistance, "K/W")}
        NameValueArgs.HeatLoadPerPerson (1,1) simscape.Value {simscape.mustBeCommensurateUnit(NameValueArgs.HeatLoadPerPerson, "W")} = simscape.Value(0,"W")
    end

    dayTempVec = value(NameValueArgs.DayTemperature,"K");
    nightTempVec = value(NameValueArgs.NightTemperature,"K");

    % Initialize physics table parameters.
    physTable = initializeRoomOperationalPhysicsData(Building=NameValueArgs.Building,...
                                                     Duration=NameValueArgs.DateTimeVec);
    % Initialize other parameters required by the model.
    opsParams = initializeOperationalParameters;

    % Set opsParams
    opsParams.perPersonHeatLoadWatts = value(NameValueArgs.HeatLoadPerPerson,"W");

    opsParams.desiredTempSetPoint = value(NameValueArgs.RoomTsetPoint,"K");
    
    [opsParams.listOfDays, opsParams.simStartTime, opsParams.sunrise, opsParams.sunset] = ...
        getSunriseSunsetData(DateTimeVector=NameValueArgs.DateTimeVec,Location=NameValueArgs.Location);
    
    nDaySimulation = length(opsParams.listOfDays);
    err = false;
    if or(length(dayTempVec)~=nDaySimulation,length(nightTempVec)~=nDaySimulation)
        err = true;
        disp("*** Error: The day and night average temperature vector must be equal in length to the number of days specified in the datetime vector.");
    end

    opsParams.averageDayTvec = dayTempVec;
    opsParams.averageNightTvec = nightTempVec;
    opsParams.percentDayTvar = NameValueArgs.DayTemperatureVar;
    opsParams.percentNightTvar = NameValueArgs.NightTemperatureVar;
    
    [t,Tamb] = get24HrTemperatureProfile(opsParams.averageDayTvec,...
        opsParams.percentDayTvar/100,opsParams.averageNightTvec,...
        opsParams.percentNightTvar/100,opsParams.sunrise,opsParams.sunset);

    opsParams.initialTemperature = round(interp1(t,Tamb,hour(NameValueArgs.DateTimeVec(1,1)),"nearest","extrap"),1);
    
    opsParams.groundThermalResistance = value(NameValueArgs.GroundResistance,"K/W");
    opsParams.simRunTime = nDaySimulation*24*3600;

    if err
        opsParams = [];
        physTable = [];
    end
end