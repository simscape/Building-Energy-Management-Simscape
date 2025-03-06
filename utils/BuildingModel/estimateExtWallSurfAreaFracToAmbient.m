% Function to estimate external wall fraction exposed to ambient.

% Copyright 2024 The MathWorks, Inc.

function updatedBuilding = estimateExtWallSurfAreaFracToAmbient(bldgName,building,tolr)
    updatedBuilding = building;
    numApartments = numel(fieldnames(building));

    extVertices2D = building.apartment1.room1.geometry.dim.allExtWallVertices;
    flrLvlVec = zeros(1,numApartments);
    for i = 1:numApartments
        flrLvlVec(1,i) = building.("apartment"+i).room1.geometry.dim.floorLevel;
    end
    flrLvlTotal = unique(flrLvlVec);
    numAptPerFlr = numApartments/max(flrLvlTotal);
    lenExtVertices2D = max(flrLvlTotal)*size(extVertices2D,1);
    % listExternalWallData = zeros(lenExtVertices2D,9); % Column 1:3 for i,j,k; Column 4,5 for WIN/VENT fraction and Column 6-9 for (x1,y1) & (x2,y2)
    listExternalWallData = [];

    for i = 1:numApartments
        numRooms = numel(fieldnames(building.("apartment"+num2str(i))));
        for j = 1:numRooms
            updatedBuilding.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim.partOfBuilding = bldgName;
            roomVerticesMat = building.("apartment"+num2str(i)).("room"+num2str(j)).floorPlan.Vertices;
            numSidesRoom = size(roomVerticesMat,1);
            %
            for k = 1:numSidesRoom
                extVer2D = building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim.allExtWallVertices;
                lenData = size(extVer2D,1);
                
                wallCoord = building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.("wall"+num2str(k)).vertices(1:2,1:2)';
                [m1,c1] = slopeOfLineThroughTwoPoint(wallCoord,tolr);

                wallLength = sqrt(sum(wallCoord(:,1).^2) + sum(wallCoord(:,2).^2));
                wallSurfFrac = 0;
                ventSurfFracVal = 0;
                windowSurfFracVal = 0;

                listExternalWallDataItr = zeros(1,9);
                for itr = 1:lenData
                    if itr < lenData
                        testCoord = extVer2D(itr:itr+1,:);
                    else
                        testCoord = extVer2D([itr,1],:);
                    end

                    [m2,c2] = slopeOfLineThroughTwoPoint(testCoord,tolr);
               
                    if ismembertol(m1,m2,tolr) && ismembertol(c1,c2,tolr)
                        % wallFracVal = testParallelLineOverlap(wallCoord,testCoord,tolr);
                        [wallFracVal,overlapVertices] = testParallelLineOverlapLength(testCoord,wallCoord,tolr);
                        if wallFracVal > 0
                            flrLvl = building.("apartment"+i).("room"+j).geometry.dim.floorLevel;
                            idx = (flrLvl-1)*numAptPerFlr*lenData+itr;
                            % listExternalWallData(idx,1:3) = [i,j,k];
                            % listExternalWallData(idx,6:7) = overlapVertices(1,:);
                            % listExternalWallData(idx,8:9) = overlapVertices(2,:);
                            listExternalWallDataItr(1,1:3) = [i,j,k];
                            listExternalWallDataItr(1,6:7) = overlapVertices(1,:);
                            listExternalWallDataItr(1,8:9) = overlapVertices(2,:);
                            % listExternalWallDataItr = [i,j,k,0,0,overlapVertices(1,1),overlapVertices(1,2),overlapVertices(2,1),overlapVertices(2,1)];
                            wallSurfFrac = wallSurfFrac + wallFracVal/wallLength;
                            if isfield(building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim,'allExtWallWindowFrac')
                                windowSurfFrac = building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim.allExtWallWindowFrac;
                                windowSurfFracVal = windowSurfFracVal + windowSurfFrac(itr,1);
                                % listExternalWallData(idx,4) = listExternalWallData(idx,4) + windowSurfFrac(itr,1);
                                listExternalWallDataItr(1,4) = listExternalWallDataItr(1,4) + windowSurfFrac(itr,1);
                            end
                            if isfield(building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim,'allExtWallVentFrac')
                                ventSurfFrac = building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim.allExtWallVentFrac;
                                ventSurfFracVal = ventSurfFracVal + ventSurfFrac(itr,1);
                                % listExternalWallData(idx,5) = listExternalWallData(idx,5) + ventSurfFrac(itr,1);
                                listExternalWallDataItr(1,5) = listExternalWallDataItr(1,5) + ventSurfFrac(itr,1);
                            end
                        end
                    end
                end
                % wallSurfFrac reresents total fraction of entire wall
                % expose to ambient. It has to be multiplied with
                % window and vent fractions to estimate solid wall,
                % vent, and window area-fraction.
                windowSurfFracVal = min(1,max(0,windowSurfFracVal));
                ventSurfFracVal = min(1,max(0,ventSurfFracVal));
                wallSurfFrac = wallSurfFrac*min(1,max(0,1-windowSurfFracVal-ventSurfFracVal));
                
                if sum(listExternalWallDataItr) > 0
                    listExternalWallData = [listExternalWallData;listExternalWallDataItr];
                end
                updatedBuilding.("apartment"+num2str(i)).("room"+num2str(j)).geometry.("wall"+num2str(k)).AmbientWallSurfFrac = max(0,min(1,wallSurfFrac));
                updatedBuilding.("apartment"+num2str(i)).("room"+num2str(j)).geometry.("wall"+num2str(k)).AmbientWindowSurfFrac = max(0,min(1,windowSurfFracVal));
                updatedBuilding.("apartment"+num2str(i)).("room"+num2str(j)).geometry.("wall"+num2str(k)).AmbientVentSurfFrac = max(0,min(1,ventSurfFracVal));
                wallCoord3D = building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.("wall"+num2str(k)).vertices;
                wallAreaVal = sqrt(sum((wallCoord3D(:,1)-wallCoord3D(:,2)).^2)) * ...
                              sqrt(sum((wallCoord3D(:,2)-wallCoord3D(:,3)).^2));
                updatedBuilding.("apartment"+num2str(i)).("room"+num2str(j)).geometry.("wall"+num2str(k)).WallAreaTotal = wallAreaVal;
            end
        end
    end
    updatedBuilding.apartment1.room1.geometry.dim.plotWallVert2D = listExternalWallData;
end