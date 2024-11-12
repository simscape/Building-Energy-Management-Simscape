function plot3DlayoutBuilding(NameValueArgs)
% Wrapper function to plot building data based on availibility of external
% wall list. If the wall list has been created, a faster method is used for
% plot.

% Copyright 2024 The MathWorks, Inc.

    arguments
        NameValueArgs.Building struct {mustBeNonempty}
        NameValueArgs.PlotViewDirection (1,3) {mustBeNonempty,mustBeReal}
        NameValueArgs.ColorScheme (1,1) string {mustBeNonempty,mustBeMember(NameValueArgs.ColorScheme,["random","sunlight","radiation","temperature","wallsAndRoof","walls","roof"])}
        NameValueArgs.Hour (1,1) {mustBeNumeric} = 0
    end

    if isfield(NameValueArgs.Building.apartment1.room1.geometry.dim,"buildingExtBoundaryWallData")
        % disp('Wall data exists as separate list');
        plotBuildingData(NameValueArgs.Building,NameValueArgs.PlotViewDirection,NameValueArgs.ColorScheme,NameValueArgs.Hour);
    else
        % disp('Separate wall data has not been collated yet');
        plotWallsRoofFloorForBuilding(NameValueArgs.Building,NameValueArgs.PlotViewDirection,NameValueArgs.ColorScheme,NameValueArgs.Hour);
    end
end