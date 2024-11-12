% Function to estimate external wall fraction exposed to ambient.

% Copyright 2024 The MathWorks, Inc.

function updatedBuilding = estimateExtWallSurfAreaFracToAmbient(bldgName,building,tolr)
    updatedBuilding = building;
    numApartments = numel(fieldnames(building));
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

                for itr = 1:lenData
                    if itr < lenData
                        testCoord = extVer2D(itr:itr+1,:);
                    else
                        testCoord = extVer2D([itr,1],:);
                    end

                    [m2,c2] = slopeOfLineThroughTwoPoint(testCoord,tolr);
               
                    if ismembertol(m1,m2,tolr) && ismembertol(c1,c2,tolr)
                        % wallFracVal = testParallelLineOverlap(wallCoord,testCoord,tolr);
                        wallFracVal = testParallelLineOverlapLength(testCoord,wallCoord,tolr);
                        if wallFracVal > 0
                            wallSurfFrac = wallSurfFrac + wallFracVal/wallLength;
                            if isfield(building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim,'allExtWallWindowFrac')
                                windowSurfFrac = building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim.allExtWallWindowFrac;
                                windowSurfFracVal = windowSurfFracVal + windowSurfFrac(itr,1);
                            end
                            if isfield(building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim,'allExtWallVentFrac')
                                ventSurfFrac = building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim.allExtWallVentFrac;
                                ventSurfFracVal = ventSurfFracVal + ventSurfFrac(itr,1);
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
end