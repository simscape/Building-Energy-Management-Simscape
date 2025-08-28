function createIconBuildingCustomComponent(NameValueArgs)
% Create ico for the building custom component.

% Copyright 2024 The MathWorks, Inc.

    arguments
        NameValueArgs.Building struct {mustBeNonempty}
        NameValueArgs.PlotViewDirection (1,3) {mustBeNonempty,mustBeReal}
        NameValueArgs.Transparency (1,1) {mustBeLessThanOrEqual(NameValueArgs.Transparency,1),mustBeGreaterThanOrEqual(NameValueArgs.Transparency,0)} = 1
    end

    figure('Name','Create Building Icon');
    plot3DlayoutBuilding(Building=NameValueArgs.Building,...
                         PlotViewDirection=NameValueArgs.PlotViewDirection,...
                         ColorScheme="wallsAndRoof",...
                         Transparency=NameValueArgs.Transparency);
    axis off;colorbar off
    saveas(gcf,'BuildingModel.png');
    customCompIconLoc = fullfile(matlab.project.rootProject().RootFolder,'Components','Models','Building');
    movefile('BuildingModel.png',customCompIconLoc);
end