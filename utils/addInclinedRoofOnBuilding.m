function [updatedBldg,err] = addInclinedRoofOnBuilding(NameValueArgs)
% Function to add sloping roofs to a building.

% Copyright 2025 The MathWorks, Inc.

    arguments
        NameValueArgs.Building struct {mustBeNonempty}
        NameValueArgs.InclinationSide string {mustBeMember(NameValueArgs.InclinationSide,["Longer","Shorter"])} = "Longer"
        NameValueArgs.RoofTopFractionalDistance {mustBeInRange(NameValueArgs.RoofTopFractionalDistance,0.01,0.99)} = 0.5
        NameValueArgs.RoofHeight (1,1) simscape.Value
        NameValueArgs.Tol {mustBeNonempty} = 0.01
    end

    err = true;
    roofHeight = value(NameValueArgs.RoofHeight,'m');
    updatedBldg = NameValueArgs.Building;
    extVert = NameValueArgs.Building.apartment1.room1.geometry.dim.allExtWallVertices;
    nSideBuilding = size(extVert,1);

    roofZmin = NameValueArgs.Building.apartment1.room1.geometry.dim.height*NameValueArgs.Building.apartment1.room1.geometry.dim.topFloorLevelNum;

    if nSideBuilding == 4
        % Inclined roofs can be added.
        err = false;
        sideLength = sqrt(diff(extVert(:,1)).^2+diff(extVert(:,2)).^2);
        longerSideLen = max(sideLength(1,1),sideLength(2,1));
        % shorterSideLen = min(sideLength(1,1),sideLength(2,1));

        if longerSideLen == sideLength(1,1)
            longerSide = [extVert(1,1),extVert(1,2),extVert(2,1),extVert(2,2); extVert(3,1),extVert(3,2),extVert(4,1),extVert(4,2)];
            shorterSide = [extVert(2,1),extVert(2,2),extVert(3,1),extVert(3,2); extVert(4,1),extVert(4,2),extVert(1,1),extVert(1,2)];
        else
            shorterSide = [extVert(1,1),extVert(1,2),extVert(2,1),extVert(2,2); extVert(3,1),extVert(3,2),extVert(4,1),extVert(4,2)];
            longerSide = [extVert(2,1),extVert(2,2),extVert(3,1),extVert(3,2); extVert(4,1),extVert(4,2),extVert(1,1),extVert(1,2)];
        end

        if strcmp(NameValueArgs.InclinationSide,"Longer")
            inclinedSide1xy1 = longerSide(1,1:2);
            inclinedSide1xy2 = longerSide(1,3:4);
            inclinedSide2xy3 = longerSide(2,1:2);
            inclinedSide2xy4 = longerSide(2,3:4);
            otherSide1xy1 = shorterSide(1,1:2);
            otherSide1xy2 = shorterSide(1,3:4);
            otherSide2xy3 = shorterSide(2,1:2);
            otherSide2xy4 = shorterSide(2,3:4);
        else
            inclinedSide1xy1 = shorterSide(1,1:2);
            inclinedSide1xy2 = shorterSide(1,3:4);
            inclinedSide2xy3 = shorterSide(2,1:2);
            inclinedSide2xy4 = shorterSide(2,3:4);
            otherSide1xy1 = longerSide(1,1:2);
            otherSide1xy2 = longerSide(1,3:4);
            otherSide2xy3 = longerSide(2,1:2);
            otherSide2xy4 = longerSide(2,3:4);
        end
        roofTopSide1xy = otherSide1xy1 + NameValueArgs.RoofTopFractionalDistance*(otherSide1xy2-otherSide1xy1);
        roofTopSide1xyz = [roofTopSide1xy,roofZmin+roofHeight];
        roofTopSide2xy = otherSide2xy4 + NameValueArgs.RoofTopFractionalDistance*(otherSide2xy3-otherSide2xy4);
        roofTopSide2xyz = [roofTopSide2xy,roofZmin+roofHeight];
        % 2 rectangular inclined faces, 2 vertical triangular faces for the roof
        
        if strcmp(NameValueArgs.InclinationSide,"Longer")
            patchInclRoofXmat = [inclinedSide1xy1(1,1),inclinedSide1xy2(1,1),roofTopSide2xyz(1,1),roofTopSide1xyz(1,1);...                % restangular face on side 1
                                 inclinedSide2xy3(1,1),inclinedSide2xy4(1,1),roofTopSide1xyz(1,1),roofTopSide2xyz(1,1);...                % restangular face on side 2
                                 otherSide1xy1(1,1),(otherSide1xy1(1,1)+otherSide1xy2(1,1))/2,otherSide1xy2(1,1),roofTopSide1xyz(1,1);... % traingular face on side 1
                                 otherSide2xy3(1,1),(otherSide2xy3(1,1)+otherSide2xy4(1,1))/2,otherSide2xy4(1,1),roofTopSide2xyz(1,1)];   % traingular face on side 2
            
            patchInclRoofYmat = [inclinedSide1xy1(1,2),inclinedSide1xy2(1,2),roofTopSide2xyz(1,2),roofTopSide1xyz(1,2);...                % restangular face on side 1
                                 inclinedSide2xy3(1,2),inclinedSide2xy4(1,2),roofTopSide1xyz(1,2),roofTopSide2xyz(1,2);...                % restangular face on side 2
                                 otherSide1xy1(1,2),(otherSide1xy1(1,2)+otherSide1xy2(1,2))/2,otherSide1xy2(1,2),roofTopSide1xyz(1,2);... % traingular face on side 1
                                 otherSide2xy3(1,2),(otherSide2xy3(1,2)+otherSide2xy4(1,2))/2,otherSide2xy4(1,2),roofTopSide2xyz(1,2)];   % traingular face on side 2
        else
            patchInclRoofXmat = [inclinedSide1xy1(1,1),inclinedSide1xy2(1,1),roofTopSide1xyz(1,1),roofTopSide2xyz(1,1);...                % restangular face on side 1
                                 inclinedSide2xy3(1,1),inclinedSide2xy4(1,1),roofTopSide2xyz(1,1),roofTopSide1xyz(1,1);...                % restangular face on side 2
                                 otherSide1xy1(1,1),(otherSide1xy1(1,1)+otherSide1xy2(1,1))/2,otherSide1xy2(1,1),roofTopSide1xyz(1,1);... % traingular face on side 1
                                 otherSide2xy3(1,1),(otherSide2xy3(1,1)+otherSide2xy4(1,1))/2,otherSide2xy4(1,1),roofTopSide2xyz(1,1)];   % traingular face on side 2
            
            patchInclRoofYmat = [inclinedSide1xy1(1,2),inclinedSide1xy2(1,2),roofTopSide1xyz(1,2),roofTopSide2xyz(1,2);...                % restangular face on side 1
                                 inclinedSide2xy3(1,2),inclinedSide2xy4(1,2),roofTopSide2xyz(1,2),roofTopSide1xyz(1,2);...                % restangular face on side 2
                                 otherSide1xy1(1,2),(otherSide1xy1(1,2)+otherSide1xy2(1,2))/2,otherSide1xy2(1,2),roofTopSide1xyz(1,2);... % traingular face on side 1
                                 otherSide2xy3(1,2),(otherSide2xy3(1,2)+otherSide2xy4(1,2))/2,otherSide2xy4(1,2),roofTopSide2xyz(1,2)];   % traingular face on side 2
        end
        % patchInclRoofZmat = [roofZmin,roofZmin,roofZmin+roofHeight,roofZmin+roofHeight;... % restangular face on side 1
        %                      roofZmin,roofZmin,roofZmin+roofHeight,roofZmin+roofHeight;... % restangular face on side 2
        %                      roofZmin,roofZmin,roofZmin,roofZmin+roofHeight;...            % traingular face on side 1
        %                      roofZmin,roofZmin,roofZmin,roofZmin+roofHeight];              % traingular face on side 2

        
        % For solar tracking, need to find orientation vector (x,y) of the
        % roof elements (outward normal) and the angle at which it is
        % inclined (to feed as degree angle in solar equation).
        
        inclinedSideInternalXY = (inclinedSide1xy1+inclinedSide1xy2+inclinedSide2xy3+inclinedSide2xy4)/4;
        [posX1,posY1] = getUnitVectorFromPointToLine(inclinedSideInternalXY,(inclinedSide1xy1+inclinedSide1xy2)/2);
        [posX2,posY2] = getUnitVectorFromPointToLine(inclinedSideInternalXY,(inclinedSide2xy3+inclinedSide2xy4)/2);
        
        otherSideInternalXY = (otherSide1xy1+otherSide1xy2+otherSide2xy3+otherSide2xy4)/4;
        [posX3,posY3] = getUnitVectorFromPointToLine(otherSideInternalXY,(otherSide1xy1+otherSide1xy2)/2);
        [posX4,posY4] = getUnitVectorFromPointToLine(otherSideInternalXY,(otherSide2xy3+otherSide2xy4)/2);
        
        % updatedBldg.apartment1.room1.geometry.dim.inclinedRoof.unitVecNormal = [posX1,posY1;posX2,posY2;posX3,posY3;posX4,posY4];
        
        % Equation of inclined planes to find inclination angles through
        % simple geometrical operations (dot and cross products)
        side1PlaneCoeff = cross([inclinedSide1xy1,roofZmin]-roofTopSide1xyz,[inclinedSide1xy2,roofZmin]-roofTopSide1xyz);
        side1PlaneConst = -dot(side1PlaneCoeff,roofTopSide1xyz);
        side2PlaneCoeff = cross([inclinedSide2xy3,roofZmin]-roofTopSide2xyz,[inclinedSide2xy4,roofZmin]-roofTopSide2xyz);
        side2PlaneConst = -dot(side2PlaneCoeff,roofTopSide2xyz);
        horizPlaneCoeff = cross([inclinedSide1xy1,roofZmin]-[inclinedSide2xy3,roofZmin],[inclinedSide1xy2,roofZmin]-[inclinedSide2xy3,roofZmin]);
        % horizPlaneConst = -dot(horizPlaneCoeff,[inclinedSide1xy1,roofZmin]);
        side1AngleDeg = round(rad2deg(acos(dot(side1PlaneCoeff,horizPlaneCoeff)/(sqrt(sum(side1PlaneCoeff.^2))*sqrt(sum(horizPlaneCoeff.^2))))),1);
        side2AngleDeg = round(rad2deg(acos(dot(side2PlaneCoeff,horizPlaneCoeff)/(sqrt(sum(side2PlaneCoeff.^2))*sqrt(sum(horizPlaneCoeff.^2))))),1);

        % List of top floor rooms
        listTopFloorRoom = NameValueArgs.Building.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.roof;
        numTopFloorRoom = size(listTopFloorRoom,1);
        inclSide1Coord = polyshape(patchInclRoofXmat(1,:),patchInclRoofYmat(1,:));
        inclSide2Coord = polyshape(patchInclRoofXmat(2,:),patchInclRoofYmat(2,:));

        descritizedRoofElementsX = [];
        descritizedRoofElementsY = [];
        descritizedRoofElementsZ = [];
        descritizedRoofElementsAngle = [];
        descritizedRoofElementsConn = [];
        descritizedRoofElementsNormal = [];
        effHeightTopFloor = zeros(numTopFloorRoom,3);

        for i = 1:numTopFloorRoom
            nA = listTopFloorRoom(i,1);
            nR = listTopFloorRoom(i,2);
            topFloorRoomShape = NameValueArgs.Building.("apartment"+nA).("room"+nR).floorPlan;
            % Inclined plane intersection vertices
            intersectVert1 = inclSide1Coord.intersect(topFloorRoomShape);
            intersectVert2 = inclSide2Coord.intersect(topFloorRoomShape);
            vertRoom1 = intersectVert1.Vertices;
            vertRoom2 = intersectVert2.Vertices;
            effHeightTopFloorVal = 0;
            if size(vertRoom1,1) > 0
                xvec = vertRoom1(:,1)';
                yvec = vertRoom1(:,2)';
                zvec = (-side1PlaneCoeff(1,1)*xvec - side1PlaneCoeff(1,2)*yvec - side1PlaneConst)/side1PlaneCoeff(1,3);
                effHeightTopFloorVal = max(abs(diff(zvec)));
                descritizedRoofElementsX = [descritizedRoofElementsX;xvec];
                descritizedRoofElementsY = [descritizedRoofElementsY;yvec];
                descritizedRoofElementsZ = [descritizedRoofElementsZ;zvec];
                descritizedRoofElementsAngle = [descritizedRoofElementsAngle;side1AngleDeg];
                descritizedRoofElementsConn = [descritizedRoofElementsConn;[nA,nR]];
                descritizedRoofElementsNormal = [descritizedRoofElementsNormal;[posX1,posY1]];
            end
            if size(vertRoom2,1) > 0
                xvec = vertRoom2(:,1)';
                yvec = vertRoom2(:,2)';
                zvec = (-side2PlaneCoeff(1,1)*xvec - side2PlaneCoeff(1,2)*yvec - side2PlaneConst)/side2PlaneCoeff(1,3);
                if effHeightTopFloorVal > 0
                    effHeightTopFloorVal = (effHeightTopFloorVal+max(abs(diff(zvec))))/2;
                else
                    effHeightTopFloorVal = max(abs(diff(zvec)));
                end
                descritizedRoofElementsX = [descritizedRoofElementsX;xvec];
                descritizedRoofElementsY = [descritizedRoofElementsY;yvec];
                descritizedRoofElementsZ = [descritizedRoofElementsZ;zvec];
                descritizedRoofElementsAngle = [descritizedRoofElementsAngle;side2AngleDeg];
                descritizedRoofElementsConn = [descritizedRoofElementsConn;[nA,nR]];
                descritizedRoofElementsNormal = [descritizedRoofElementsNormal;[posX2,posY2]];
            end
            effHeightTopFloor(i,1) = nA;
            effHeightTopFloor(i,2) = nR;
            effHeightTopFloor(i,3) = effHeightTopFloorVal;
        end

        chkDescritizedRoofElementsX = descritizedRoofElementsX;
        chkDescritizedRoofElementsY = descritizedRoofElementsY;
        % chkDescritizedRoofElementsZ = descritizedRoofElementsZ;

        for i = 1:numTopFloorRoom
            nA = listTopFloorRoom(i,1);
            nR = listTopFloorRoom(i,2);
            topFloorRoomShape = NameValueArgs.Building.("apartment"+nA).("room"+nR).floorPlan;
            % Inclined plane intersection vertices
            intersectVert1 = inclSide1Coord.intersect(topFloorRoomShape);
            intersectVert2 = inclSide2Coord.intersect(topFloorRoomShape);
            vertRoom1 = intersectVert1.Vertices;
            vertRoom2 = intersectVert2.Vertices;
            if size(vertRoom1,1) > 0
                for j = 1:size(vertRoom1,1)
                    if j == size(vertRoom1,1)
                        roomCoordChk = vertRoom1([j,1],:);
                    else
                        roomCoordChk = vertRoom1(j:j+1,:);
                    end
                    otherSide1 = [patchInclRoofXmat(3,1),patchInclRoofYmat(3,1);patchInclRoofXmat(3,3),patchInclRoofYmat(3,3)];
                    [result,X,Y,Z] = partitionVerticalSectionInclinedRoof(roomCoordChk,otherSide1,roofZmin,...
                        chkDescritizedRoofElementsX,chkDescritizedRoofElementsY,...
                        descritizedRoofElementsX,descritizedRoofElementsY,descritizedRoofElementsZ,NameValueArgs.Tol);
                    if result
                        descritizedRoofElementsX = [descritizedRoofElementsX;X];
                        descritizedRoofElementsY = [descritizedRoofElementsY;Y];
                        descritizedRoofElementsZ = [descritizedRoofElementsZ;Z];
                        descritizedRoofElementsAngle = [descritizedRoofElementsAngle;90];
                        descritizedRoofElementsConn = [descritizedRoofElementsConn;[nA,nR]];
                        descritizedRoofElementsNormal = [descritizedRoofElementsNormal;[posX3,posY3]];
                    end
                    % 
                    otherSide2 = [patchInclRoofXmat(4,1),patchInclRoofYmat(4,1);patchInclRoofXmat(4,3),patchInclRoofYmat(4,3)];
                    [result,X,Y,Z] = partitionVerticalSectionInclinedRoof(roomCoordChk,otherSide2,roofZmin,...
                        chkDescritizedRoofElementsX,chkDescritizedRoofElementsY,...
                        descritizedRoofElementsX,descritizedRoofElementsY,descritizedRoofElementsZ,NameValueArgs.Tol);
                    if result
                        descritizedRoofElementsX = [descritizedRoofElementsX;X];
                        descritizedRoofElementsY = [descritizedRoofElementsY;Y];
                        descritizedRoofElementsZ = [descritizedRoofElementsZ;Z];
                        descritizedRoofElementsAngle = [descritizedRoofElementsAngle;90];
                        descritizedRoofElementsConn = [descritizedRoofElementsConn;[nA,nR]];
                        descritizedRoofElementsNormal = [descritizedRoofElementsNormal;[posX4,posY4]];
                    end
                end
            end
            if size(vertRoom2,1) > 0
                for j = 1:size(vertRoom2,1)
                    if j == size(vertRoom2,1)
                        roomCoordChk = vertRoom2([j,1],:);
                    else
                        roomCoordChk = vertRoom2(j:j+1,:);
                    end
                    otherSide1 = [patchInclRoofXmat(3,1),patchInclRoofYmat(3,1);patchInclRoofXmat(3,3),patchInclRoofYmat(3,3)];
                    [result,X,Y,Z] = partitionVerticalSectionInclinedRoof(roomCoordChk,otherSide1,roofZmin,...
                        chkDescritizedRoofElementsX,chkDescritizedRoofElementsY,...
                        descritizedRoofElementsX,descritizedRoofElementsY,descritizedRoofElementsZ,NameValueArgs.Tol);
                    if result
                        descritizedRoofElementsX = [descritizedRoofElementsX;X];
                        descritizedRoofElementsY = [descritizedRoofElementsY;Y];
                        descritizedRoofElementsZ = [descritizedRoofElementsZ;Z];
                        descritizedRoofElementsAngle = [descritizedRoofElementsAngle;90];
                        descritizedRoofElementsConn = [descritizedRoofElementsConn;[nA,nR]];
                        descritizedRoofElementsNormal = [descritizedRoofElementsNormal;[posX3,posY3]];
                    end
                    %
                    otherSide2 = [patchInclRoofXmat(4,1),patchInclRoofYmat(4,1);patchInclRoofXmat(4,3),patchInclRoofYmat(4,3)];
                    [result,X,Y,Z] = partitionVerticalSectionInclinedRoof(roomCoordChk,otherSide2,roofZmin,...
                        chkDescritizedRoofElementsX,chkDescritizedRoofElementsY,...
                        descritizedRoofElementsX,descritizedRoofElementsY,descritizedRoofElementsZ,NameValueArgs.Tol);
                    if result
                        descritizedRoofElementsX = [descritizedRoofElementsX;X];
                        descritizedRoofElementsY = [descritizedRoofElementsY;Y];
                        descritizedRoofElementsZ = [descritizedRoofElementsZ;Z];
                        descritizedRoofElementsAngle = [descritizedRoofElementsAngle;90];
                        descritizedRoofElementsConn = [descritizedRoofElementsConn;[nA,nR]];
                        descritizedRoofElementsNormal = [descritizedRoofElementsNormal;[posX4,posY4]];
                    end
                end
            end
        end

        descritizedRoofElementsLen = sqrt(diff(descritizedRoofElementsX').^2+diff(descritizedRoofElementsY').^2+diff(descritizedRoofElementsZ').^2);
        % Some elements in above matrix might be zero if the roof element
        % is triangular and the 4th point for patch is a duplicate. Then,
        % the area calculation needs to be done with caution.
        areaVal = zeros(size(descritizedRoofElementsLen,2),1);
        for i = 1:size(descritizedRoofElementsLen,2)
            sideLen = unique(descritizedRoofElementsLen(:,i));
            sideLen = sideLen(sideLen>1e-6);
            areaVal(i,1) = sideLen(1,1)*sideLen(2,1);
        end
        updatedBldg.apartment1.room1.geometry.dim.inclinedRoof.roofPanelArea = areaVal;
        updatedBldg.apartment1.room1.geometry.dim.inclinedRoof.unitVecNormal = descritizedRoofElementsNormal;
        updatedBldg.apartment1.room1.geometry.dim.inclinedRoof.roofAngleDegrees = descritizedRoofElementsAngle;
        updatedBldg.apartment1.room1.geometry.dim.inclinedRoof.roofRoomConnectivity = descritizedRoofElementsConn;
        updatedBldg.apartment1.room1.geometry.dim.inclinedRoof.inclX = descritizedRoofElementsX;
        updatedBldg.apartment1.room1.geometry.dim.inclinedRoof.inclY = descritizedRoofElementsY;
        updatedBldg.apartment1.room1.geometry.dim.inclinedRoof.inclZ = descritizedRoofElementsZ;
        updatedBldg.apartment1.room1.geometry.dim.inclinedRoof.topFloorAdditionalHt = effHeightTopFloor;
        disp(strcat("Inclined roof angles = ",num2str(side1AngleDeg)," degrees and ",num2str(side2AngleDeg)," degrees, respectively."))
    else
        disp("Could not create inclined roof.");
        disp("*** Inclined roof are supported only with buildings having a net rectangular floorplan.");
        disp("Default flat roofs retained in the building.");
    end
end