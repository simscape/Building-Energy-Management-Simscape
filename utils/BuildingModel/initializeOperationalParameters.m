function opsParams = initializeOperationalParameters
% Function to initialize operational parameters.

% Copyright 2025 The MathWorks, Inc.

    % The parameters below must be defined for any simulation.
    opsParams.averageDayTvec = [];
    opsParams.averageNightTvec = [];
    opsParams.desiredTempSetPoint = [];
    opsParams.groundThermalResistance = [];
    opsParams.initialTemperature = [];
    opsParams.listOfDays = [];
    opsParams.percentDayTvar = [];
    opsParams.percentNightTvar = [];
    opsParams.simRunTime = [];
    opsParams.simStartTime = [];
    opsParams.sunrise = [];
    opsParams.sunset = [];

    % Parameters below are requried for few types of simulation, not all.
    % Hence, a default value must be provided to them and must not be
    % defined as null.
    opsParams.perPersonHeatLoadWatts = 0;
end