% Function to combine multiple buildings data struct.

% Copyright 2024 The MathWorks, Inc.

function buildingLandscape = combineMultipleBuildingDataStruct(buildingList)
    arguments
        buildingList (1,:) cell {mustBeNonempty}
    end

    nAptsAddedFromPrevBldg = 0;
    combinedDataWall  = buildingList{1,1}.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.wall;
    combinedDataRoof  = buildingList{1,1}.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.roof;
    combinedDataFloor = buildingList{1,1}.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.floor;
    for nBldg = 1:length(buildingList)
        % The section below is important for recording the top floor
        % number in the combined list of all apartments. Top floor
        % number is essential in function for plotting as information
        % regarding the max. hieight of a building amongst multiple
        % buildings is requried. Else, some of the roof plots may be
        % off. The top floor level number is just shifted by the number
        % of apartments already added from prev. list of buildings.
        %
        % updatedBuildingData.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.wall = aptRoomWallNumMat;
        % updatedBuildingData.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.roof = aptRoomRoofNumMat;
        % updatedBuildingData.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.floor = aptRoomFloorNumMat;
        % 
        % The apartment 1 of each building stores the wall, roof,
        % and floor list data (for plotting). The format of the
        % list of (i,j,k) columns, with i denoting apartment
        % number, j denoting the room number, and k denoting the
        % wall number. For roof and floor, k does not exist [the
        % data then is just defined as (i,j)]
        % 
        % As the buildings are combined together, the apartment
        % number get updated and the list should reflect the same.
        % The (i,j,k) for walls and (i,j) for roof/floor must be
        % updated for each building (other than the first one in
        % the buildingList. Then, the updated data must be combined
        % to reflect in apartment1.room1.... for the new data
        % struct(). The plot functions checks for the list ONLY at
        % apartment1.room1... as that would exist in any
        % simulation.
        [totalApts, ~] = getNumAptAndRoomsFromFloorPlan(buildingList{1,nBldg});
        if nBldg > 1
            wallData  = buildingList{1,nBldg}.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.wall;
            roofData  = buildingList{1,nBldg}.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.roof;
            floorData = buildingList{1,nBldg}.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.floor;
            for i = 1:size(wallData,1)
                wallData(i,1) = wallData(i,1) + nAptsAddedFromPrevBldg; % Apartment number updated
            end
            for i = 1:size(roofData,1)
                roofData(i,1) = roofData(i,1) + nAptsAddedFromPrevBldg; % Apartment number updated
            end
            for i = 1:size(floorData,1)
                floorData(i,1) = floorData(i,1) + nAptsAddedFromPrevBldg; % Apartment number updated
            end
            combinedDataWall  = [combinedDataWall ;wallData];
            combinedDataRoof  = [combinedDataRoof ;roofData];
            combinedDataFloor = [combinedDataFloor;floorData];
        end
        nAptsAddedFromPrevBldg = nAptsAddedFromPrevBldg + totalApts;
    end
    % Store in Building 1 from the list as in the combined list, this
    % building data would be the first one to be added.
    buildingList{1,1}.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.wall  = combinedDataWall;
    buildingList{1,1}.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.roof  = combinedDataRoof;
    buildingList{1,1}.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.floor = combinedDataFloor;

    % Combine all Building data
    nBuilding = 0;
    for nBldg = 1:length(buildingList)
        [totalApts, ~] = getNumAptAndRoomsFromFloorPlan(buildingList{1,nBldg});
        for nApt = 1:totalApts
            nBuilding = nBuilding + 1;
            buildingLandscape.("apartment"+num2str(nBuilding)) = buildingList{1,nBldg}.("apartment"+num2str(nApt));
        end
    end
end