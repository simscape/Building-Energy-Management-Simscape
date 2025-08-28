function tblMatProp = updateBuildingMaterialCompositeWallProp(NameValueArgs)
% Update building material properties with composite wall properties.

% Copyright 2025 The MathWorks, Inc.

    arguments
        NameValueArgs.CompositeExternalWall (5,:) table {mustBeNonempty}
        NameValueArgs.CompositeInternalWall (5,:) table {mustBeNonempty}
        NameValueArgs.CompositeRoof (5,:) table {mustBeNonempty}
        NameValueArgs.CompositeFloor (5,:) table {mustBeNonempty}
        NameValueArgs.WindowTransmissivity (1,1) {mustBeInRange(NameValueArgs.WindowTransmissivity,0,1)} = 0.5
    end
    
    tblMatProp = initializeBuildingMaterialProperties;
    tblMatProp("Transmissivity [-]","Window") = array2table(NameValueArgs.WindowTransmissivity);
    % Assume that absorptivity and reflectivity are equal in value, and
    % hence (1-transmissivity)/2; In revit, only transmissivity was
    % defined.
    tblMatProp("Absorptivity [-]","Window") = array2table(round((1-NameValueArgs.WindowTransmissivity)/2,2));

    wallNames = ["ExternalWall","Floor","InternalWall","Roof","Window"];

    for i = 1:4
        removeWallData = wallNames(~strcmp(wallNames,wallNames(1,i)));
        tblWall = removevars(tblMatProp,removeWallData);
        tblWall = updateBuildingMaterialOneCompositeWall(BuildingWallDataTable=tblWall,CompositeWall=NameValueArgs.("Composite"+wallNames(1,i)));
        tblMatProp(:,wallNames(1,i)) = tblWall;
    end

    disp("*** Updated table properties");
    disp("");
    disp(tblMatProp);
    disp("");
end