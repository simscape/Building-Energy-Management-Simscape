function tblMatProp = updateBuildingMaterialOneCompositeWall(NameValueArgs)
% Update building material properties for a given composite wall.

% Copyright 2025 The MathWorks, Inc.

    arguments
        NameValueArgs.BuildingWallDataTable (6,1) table {mustBeNonempty}
        NameValueArgs.CompositeWall (5,:) table {mustBeNonempty}
    end
    
    tblMatProp = NameValueArgs.BuildingWallDataTable;
    wallName = tblMatProp.Properties.VariableNames;
    compositeWallMat = NameValueArgs.CompositeWall;
    checkTableData = compositeWallMat;

    checkTableData("Absorptivity [-]",:) = [];
    [~,remCol] = find(or(table2array(checkTableData)==0,isnan(table2array(checkTableData))));
    success = false;
    if size(remCol,1) > 0
        rm = unique(remCol);
        if size(rm,1) == size(NameValueArgs.CompositeWall,2)
            disp(strcat("*** Error: Data incomplete in ",string(wallName),"-composite-wall."));
        else
            listOfWallRemove = [];
            for i = 1:size(rm,1)
                listOfWallRemove = [listOfWallRemove,compositeWallMat.Properties.VariableNames(1,rm(i,1))];
            end
            compositeWallMat = removevars(compositeWallMat,listOfWallRemove);
            success = true;
        end
    else
        disp(strcat("*** Error: Data not updated for ",string(wallName),"-composite-wall."));
    end

    if success
        thickness = sum(table2array(compositeWallMat("Thickness [m]",:)));
        density = sum(table2array(compositeWallMat("Thickness [m]",:)).*table2array(compositeWallMat("Density [kg/m^3]",:)))/thickness;
        heatCapacity = sum(table2array(compositeWallMat("Heat Capacity [J/kg-K]",:)).*table2array(compositeWallMat("Thickness [m]",:)).*table2array(compositeWallMat("Density [kg/m^3]",:)))/sum(table2array(compositeWallMat("Thickness [m]",:)).*table2array(compositeWallMat("Density [kg/m^3]",:)));
        thermalK = thickness/sum(table2array(compositeWallMat("Thickness [m]",:))./table2array(compositeWallMat("Thermal Conductivity [W/K-m]",:)));
        disp(strcat("*** Updated: Data for ",string(wallName),"-composite-wall."));

        tblMatProp("Density [kg/m^3]",:) = array2table(density);
        tblMatProp("Heat Capacity [J/kg-K]",:) = array2table(heatCapacity);
        tblMatProp("Thickness [m]",:) = array2table(thickness);
        tblMatProp("Thermal Conductivity [W/K-m]",:) = array2table(thermalK);
        if or(strcmp(string(wallName),"ExternalWall"),strcmp(string(wallName),"Roof"))
            tblMatProp("Absorptivity [-]",:) = array2table(mean(table2array(compositeWallMat("Absorptivity [-]",:))));
        end
    end
end