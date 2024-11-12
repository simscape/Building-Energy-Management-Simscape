function [listOfDays,simStartTime,sunrise,sunset] = getAmbientTemperatureVariationModelData(NameValueArgs)
% Function to model ambient temperature variation.

% Copyright 2024 The MathWorks, Inc.

    arguments
        NameValueArgs.DateTimeVector datetime {mustBeNonempty}
        NameValueArgs.Location table {mustBeNonempty}
        NameValueArgs.DayLightSavingHrs (1,1) {mustBeNonempty,mustBeNonnegative} = 0
    end
    
    solarDataTimeSeries = getSolarAnglesAndSunMovementData(NameValueArgs.DateTimeVector,...
                                                           NameValueArgs.Location,...
                                                           NameValueArgs.DayLightSavingHrs);
    % listOfDays = unique(day(solarDataTimeSeries.Time));
    listOfDays = unique(day(solarDataTimeSeries.Time,'dayofyear'));
    simStartTime  = hour(solarDataTimeSeries.Time(1,1))*3600 + ...
                    minute(solarDataTimeSeries.Time(1,1))*60 + ...
                    second(solarDataTimeSeries.Time(1,1));
    % Find sunrise and sunset time
    numOfDays = length(listOfDays);
    if numOfDays == 1
        listOfDays = [listOfDays;listOfDays];
        numOfDays = length(listOfDays);
    end
    sunrise = zeros(1,numOfDays);
    sunset = zeros(1,numOfDays);
    for i = 1:numOfDays
        rowNum = find(day(solarDataTimeSeries.Time,'dayofyear')==listOfDays(i,1),1);
        sunrise(1,i) = solarDataTimeSeries.sunriseTime(rowNum,1)*3600;
        sunset(1,i) = solarDataTimeSeries.sunsetTime(rowNum,1)*3600;
    end
end