function plotBuildingWallsAndRoof(NameValueArgs)
% Function to plot building walls and roof separately.

% Copyright 2024 The MathWorks, Inc.

    arguments
        NameValueArgs.Building struct {mustBeNonempty}
        NameValueArgs.PlotViewDirection (1,3) {mustBeNonempty}
    end

    strTitle = 'Plot Walls';
    figure('Name',strTitle);
    plot3DlayoutBuilding(Building=NameValueArgs.Building,...
                         PlotViewDirection=NameValueArgs.PlotViewDirection,...
                         ColorScheme="walls");
    title(strTitle);
    
    strTitle = 'Plot Roof';
    figure('Name',strTitle);
    plot3DlayoutBuilding(Building=NameValueArgs.Building,...
                         PlotViewDirection=NameValueArgs.PlotViewDirection,...
                         ColorScheme="roof");
    title(strTitle);
    
    strTitle = 'Plot Walls & Roof';
    figure('Name',strTitle);
    plot3DlayoutBuilding(Building=NameValueArgs.Building,...
                         PlotViewDirection=NameValueArgs.PlotViewDirection,...
                         ColorScheme="wallsAndRoof");
    title(strTitle);
end