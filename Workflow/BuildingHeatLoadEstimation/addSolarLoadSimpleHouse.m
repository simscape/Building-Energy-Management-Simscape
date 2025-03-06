function [building3D,dateTimeVec] = addSolarLoadSimpleHouse(NameValueArgs)
% Function to add solar load to a simple house with inclined roof.

% Copyright 2025 The MathWorks, Inc.

    arguments
        NameValueArgs.Building struct {mustBeNonempty}
        NameValueArgs.Location (1,3) table {mustBeNonempty}
        NameValueArgs.DayLightSavingHrs (1,1) {mustBeReal} = 0
        NameValueArgs.StartTime datetime {mustBeNonempty}
        NameValueArgs.EndTime datetime {mustBeNonempty}
        NameValueArgs.Plot {mustBeNonempty} = false
    end

    building3D = getHourlyBuildingSolarLoad(Building=NameValueArgs.Building,...
                                            Location=NameValueArgs.Location,...
                                            DayLightSavingHrs=NameValueArgs.DayLightSavingHrs,...
                                            StartTime=NameValueArgs.StartTime,...
                                            EndTime=NameValueArgs.EndTime);

    dateTimeVec = NameValueArgs.StartTime:hours(1):NameValueArgs.EndTime;

    if NameValueArgs.Plot
        viewingAngle = [-1 -1 1];
        geoLocation = NameValueArgs.Location;
        for nHrs = 1:length(dateTimeVec)
            figure('Name',strcat('BuildingPlotNum',num2str(nHrs)));
            plot3DlayoutBuilding(Building=building3D,...
                                 PlotViewDirection=viewingAngle,...
                                 ColorScheme="radiation",...
                                 Hour=nHrs);
            title(strcat(geoLocation.Row,', Date/Time :',string(dateTimeVec(1,nHrs))," (Radiation, W/m^2)"));
        end
    end
end