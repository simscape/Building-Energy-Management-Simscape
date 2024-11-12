% Create icon for the Ambient custom component.

% Copyright 2024 The MathWorks, Inc.

function [t,Tamb] = createIconAmbientCustomComponent(NameValueArgs)
    
    arguments
        NameValueArgs.AvgDayTemperatureVec (1,:) {mustBeNonempty}
        NameValueArgs.PercentDayTemperatureVar {mustBeNonempty}
        NameValueArgs.AvgNightTemperatureVec (1,:) {mustBeNonempty}
        NameValueArgs.PercentNightTemperatureVar {mustBeNonempty}
        NameValueArgs.SunriseVec (1,:) {mustBeNonempty}
        NameValueArgs.SunsetVec (1,:) {mustBeNonempty}
    end

    [t,Tamb] = get24HrTemperatureProfile(NameValueArgs.AvgDayTemperatureVec,...
                                         NameValueArgs.PercentDayTemperatureVar/100,...
                                         NameValueArgs.AvgNightTemperatureVec,...
                                         NameValueArgs.PercentNightTemperatureVar/100,...
                                         NameValueArgs.SunriseVec,...
                                         NameValueArgs.SunsetVec);
    
    figure('Name','Ambient Custom Component Icon');
    plot(t,Tamb);ylabel('Temperature [K]');
    saveas(gcf,'EnvModel.png');
    customCompIconLoc = fullfile(matlab.project.rootProject().RootFolder,'Components','Ambient');
    movefile('EnvModel.png',customCompIconLoc);
end