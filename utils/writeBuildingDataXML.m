function writeBuildingDataXML(NameValueArgs)
% Create XML file for storing building data.

% Copyright 2024 The MathWorks, Inc.

    arguments
        NameValueArgs.Location table {mustBeNonempty}
        NameValueArgs.StartTime datetime {mustBeNonempty}
        NameValueArgs.EndTime datetime {mustBeNonempty}
        NameValueArgs.Building struct {mustBeNonempty}
        NameValueArgs.FileName string {mustBeNonempty}
    end
    
    [nApt, nRooms] = getNumAptAndRoomsFromFloorPlan(NameValueArgs.Building);
    % Copy everything other than floor plan (polyshape object) as it cannot
    % be stored in XML (struct2XML fails)
    for i = 1:nApt
        for j = 1:nRooms(i,1)
            bldg.("apartment"+num2str(i)).("room"+num2str(j)).name = NameValueArgs.Building.("apartment"+num2str(i)).("room"+num2str(j)).name;
            bldg.("apartment"+num2str(i)).("room"+num2str(j)).physics = NameValueArgs.Building.("apartment"+num2str(i)).("room"+num2str(j)).physics;
            bldg.("apartment"+num2str(i)).("room"+num2str(j)).geometry = NameValueArgs.Building.("apartment"+num2str(i)).("room"+num2str(j)).geometry;
        end
    end

    % Convert matrix data to vector values (use reshape) so that XML write
    % is possible
    for i = 1:nApt
        for j = 1:nRooms(i,1)
            nWalls = NameValueArgs.Building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim.numWalls;
            % Change wall vertices data to vector array
            for k = 1:nWalls
                wallVert = NameValueArgs.Building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.("wall"+num2str(k)).vertices;
                [r,c] = size(wallVert);
                bldg.("apartment"+num2str(i)).("room"+num2str(j)).geometry.("wall"+num2str(k)).vertices = reshape(wallVert,[1,r*c]);
                bldg.("apartment"+num2str(i)).("room"+num2str(j)).geometry.("wall"+num2str(k)).verticesMATsize = [r,c];
            end
            
            % Change roof vertices data to vector array
            roofVert = NameValueArgs.Building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.roof.vertices;
            [r,c] = size(roofVert);
            bldg.("apartment"+num2str(i)).("room"+num2str(j)).geometry.roof.vertices = reshape(roofVert,[1,r*c]);
            bldg.("apartment"+num2str(i)).("room"+num2str(j)).geometry.roof.verticesMATsize = [r,c];
            
            % Change floor vertices data to vector array
            floorVert = NameValueArgs.Building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.floor.vertices;
            [r,c] = size(floorVert);
            bldg.("apartment"+num2str(i)).("room"+num2str(j)).geometry.floor.vertices = reshape(floorVert,[1,r*c]);
            bldg.("apartment"+num2str(i)).("room"+num2str(j)).geometry.floor.verticesMATsize = [r,c];
           
            % Change allExtWallVertices data stored in each room (matrix)
            % to vector data
            allExtVert = NameValueArgs.Building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim.allExtWallVertices;
            [r,c] = size(allExtVert);
            bldg.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim.allExtWallVertices = reshape(allExtVert,[1,r*c]);
            bldg.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim.allExtWallVerticesMATsize = [r,c];
            
            % bldg.("apartment"+num2str(i)).("room"+num2str(j)) = rmfield(bldg.("apartment"+num2str(i)).("room"+num2str(j)),'floorplan');
            if isfield(bldg.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim,"buildingExtBoundaryWallData")
                % Save data used during plotting, list of walls in
                % apartment1, room1. Sometimes, this data struct may exist
                % in other apartment numbers too. This can happen when
                % multiple buildings are combined, apartment numbers
                % renamed -- some part of data may be retained in such
                % cases, if not deleted (ideal scenario) during copy to
                % apartment1.room1....
                listOfWall  = NameValueArgs.Building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim.buildingExtBoundaryWallData.wall;
                listOfRoof  = NameValueArgs.Building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim.buildingExtBoundaryWallData.roof;
                listOfFloor = NameValueArgs.Building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim.buildingExtBoundaryWallData.floor;
                [r,c] = size(listOfWall);
                bldg.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim.buildingExtBoundaryWallData.wall = reshape(listOfWall,[1,r*c]);
                bldg.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim.buildingExtBoundaryWallData.wallMATsize = [r,c];
                [r,c] = size(listOfRoof);
                bldg.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim.buildingExtBoundaryWallData.roof = reshape(listOfRoof,[1,r*c]);
                bldg.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim.buildingExtBoundaryWallData.roofMATsize = [r,c];
                [r,c] = size(listOfFloor);
                bldg.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim.buildingExtBoundaryWallData.floor = reshape(listOfFloor,[1,r*c]);
                bldg.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim.buildingExtBoundaryWallData.floorMATsize = [r,c];
            end
            solarDataLengthHrs = length(bldg.("apartment"+num2str(i)).("room"+num2str(j)).geometry.roof.sunlightFrac);
        end
    end

    % Save other relevant data in README section
    saveData.README.FileGeneratedOn = datetime("now");
    saveData.README.Location = NameValueArgs.Location.Row;
    saveData.README.Latitude = NameValueArgs.Location.Latitude;
    saveData.README.Longitude = NameValueArgs.Location.Longitude;
    saveData.README.StdTimeZone = NameValueArgs.Location.("Meredian (Time Zone)");
    saveData.README.BuildingInfo = strcat("The building model contains ",num2str(nApt),...
        "-apartments and a total of ",num2str(sum(nRooms)),"-rooms.");
    saveData.README.nApt = nApt;
    saveData.README.nRooms = nRooms;
    saveData.README.SolarDataHrs = strcat("The building model contains ",...
        num2str(solarDataLengthHrs),"-hours of solar tracking data.");
    if NameValueArgs.StartTime < NameValueArgs.EndTime
        saveData.README.StartTime = NameValueArgs.StartTime;
        saveData.README.EndTime = NameValueArgs.EndTime;
    else
        saveData.README.StartTime = NameValueArgs.EndTime;
        saveData.README.EndTime = NameValueArgs.StartTime;
    end
   
    saveData.DATA = bldg;

    storeDataToFilename = fullfile(matlab.project.rootProject().RootFolder,'ScriptsData','Parts',NameValueArgs.FileName);
    writestruct(saveData,storeDataToFilename);
end