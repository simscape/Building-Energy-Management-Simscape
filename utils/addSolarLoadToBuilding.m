function [building3D,dateTimeVec] = addSolarLoadToBuilding(NameValueArgs)
% Function to add solar load to a simple house with inclined roof.

% Copyright 2025 The MathWorks, Inc.

    arguments
        NameValueArgs.Building struct {mustBeNonempty}
        NameValueArgs.Location (1,3) table {mustBeNonempty}
        NameValueArgs.DayLightSavingHrs (1,1) {mustBeReal} = 0
        NameValueArgs.StartTime datetime {mustBeNonempty}
        NameValueArgs.EndTime datetime {mustBeNonempty}
        NameValueArgs.Plot {mustBeNonempty} = false
        NameValueArgs.PlotFrequency (1,1) {mustBeGreaterThanOrEqual(NameValueArgs.PlotFrequency,1)} = 1
        NameValueArgs.PlotStartHourNum (1,1) {mustBeGreaterThanOrEqual(NameValueArgs.PlotStartHourNum,1)} = 1
        NameValueArgs.PlotColorScheme (1,1) string {mustBeMember(NameValueArgs.PlotColorScheme,["random","radiation","simple"])} = "simple"
        NameValueArgs.PlotViewAngle (1,3) {mustBeNonempty} = [-1 -1 1]
    end

    building3D = getHourlyBuildingSolarLoad(Building=NameValueArgs.Building,...
                                            Location=NameValueArgs.Location,...
                                            DayLightSavingHrs=NameValueArgs.DayLightSavingHrs,...
                                            StartTime=NameValueArgs.StartTime,...
                                            EndTime=NameValueArgs.EndTime);

    dateTimeVec = NameValueArgs.StartTime:hours(1):NameValueArgs.EndTime;

    if NameValueArgs.Plot
        geoLocation = NameValueArgs.Location;
        for nHrs = NameValueArgs.PlotStartHourNum:NameValueArgs.PlotFrequency:length(dateTimeVec)
            figure('Name',strcat('BuildingSolarLoadPlotNum',num2str(nHrs)));
            plot3DlayoutBuilding(Building=building3D,...
                                 PlotViewDirection=NameValueArgs.PlotViewAngle,...
                                 ColorScheme=NameValueArgs.PlotColorScheme,...
                                 Hour=nHrs);
            title(strcat(geoLocation.Row,', Date/Time :',string(dateTimeVec(1,nHrs)),"(",NameValueArgs.PlotColorScheme,")"));
        end
    end
end