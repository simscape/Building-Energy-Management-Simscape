% Function to model temperature variations throughout the day.

% Copyright 2024 The MathWorks, Inc.

function [hourlyTimeData,hourlyTempVar] = get24HrTemperatureProfile(TDavg,TDvar,TNavg,TNvar,SunR,SunS)
    arguments
        TDavg (1,:) {mustBeNonempty,mustBeNonnegative}
        TDvar (1,1) {mustBeNonempty,mustBeNonnegative}
        TNavg (1,:) {mustBeNonempty,mustBeNonnegative}
        TNvar (1,1) {mustBeNonempty,mustBeNonnegative}
        SunR  (1,:) {mustBeNonempty,mustBeNonnegative}
        SunS  (1,:) {mustBeNonempty,mustBeNonnegative}
    end

    curveFitOrder = 2;
    numOfDays = length(TDavg);
    polyfitCoeff = zeros(numOfDays,curveFitOrder+1);
    for i = 1:numOfDays
        TDmin = (1-TDvar)*TDavg(1,i);
        TDmax = (1+TDvar)*TDavg(1,i);
        TNmin = (1-TNvar)*TNavg(1,i);
        TNmax = (1+TNvar)*TNavg(1,i);
        R = SunR(1,i);
        S = SunS(1,i);
        N = 12*3600;   % Noon Time, s
        M = 24*3600-1; % Almost MidNight, s
        M0= 1;         % At 1 hr past mid night, s
        valTime = [M0 R N S (S+M)/2 M];
        valTemp = [TNavg(1,i) TDmin TDmax TNmax TNavg(1,i) TNmin];
        polyfitCoeff(i,:) = polyfit(valTime,valTemp,curveFitOrder);
    end

    oneHour = 24;
    hourlyTempVar = zeros(1,numOfDays*oneHour);
    for i = 1:numOfDays*oneHour
        dayNum = max(1,min(numOfDays,(i-mod(i,oneHour))/oneHour+1));
        hourlyTempVar(1,i) = polyval(polyfitCoeff(dayNum,:),mod(i*3600,24*3600));
    end
    hourlyTimeData = (1:numOfDays*oneHour)*3600;
end