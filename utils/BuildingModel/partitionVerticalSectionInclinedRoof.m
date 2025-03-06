function [operationSuccess,descritizedRoofElementsXnew,descritizedRoofElementsYnew,descritizedRoofElementsZnew] = ...
    partitionVerticalSectionInclinedRoof(chkRoomVertices,roofSide,roofZmin,...
    chkDescritizedRoofElementsX,chkDescritizedRoofElementsY,...
    descritizedRoofElementsX,descritizedRoofElementsY,descritizedRoofElementsZ,tol)
% Function to partition inclined sloping roofs to a building and connect each partitioned element to a room.

% Copyright 2025 The MathWorks, Inc.    
    
    operationSuccess = false;
    descritizedRoofElementsXnew = [];
    descritizedRoofElementsYnew = [];
    descritizedRoofElementsZnew = [];
    [m1,c1] = slopeOfLineThroughTwoPoint(chkRoomVertices,tol);
    [m2,c2] = slopeOfLineThroughTwoPoint(roofSide,tol);
    [val,valVert] = testParallelLineOverlapLength(roofSide,chkRoomVertices,tol);

    possibleVertices = false;
    if ismembertol(m1,m2,tol) && ismembertol(c1,c2,tol) && val > 0
        possibleVertices = true;
    end
    
    if possibleVertices
        [r1,c1] = find(and(chkDescritizedRoofElementsX==valVert(1,1),chkDescritizedRoofElementsY==valVert(1,2)));
        [r2,c2] = find(and(chkDescritizedRoofElementsX==valVert(2,1),chkDescritizedRoofElementsY==valVert(2,2)));
        if ~isempty(r1) && ~isempty(r2) && ~isempty(c1) && ~isempty(c2)
            lenR1 = size(r1,1);
            lenR2 = size(r2,1);
            for k1 = 1:lenR1
                for k2 = 1:lenR2
                    r1v = r1(k1,1);
                    c1v = c1(k1,1);
                    r2v = r2(k2,1);
                    c2v = c2(k2,1);
                    [chk,~] = testParallelLineOverlapLength(roofSide,[descritizedRoofElementsX(r2v,c2v),descritizedRoofElementsY(r2v,c2v);descritizedRoofElementsX(r1v,c1v),descritizedRoofElementsY(r1v,c1v)],tol);
                    if chk > 0
                        operationSuccess = true;
                        descritizedRoofElementsXnew = [valVert(1,1),valVert(2,1),descritizedRoofElementsX(r2v,c2v),descritizedRoofElementsX(r1v,c1v)];
                        descritizedRoofElementsYnew = [valVert(1,2),valVert(2,2),descritizedRoofElementsY(r2v,c2v),descritizedRoofElementsY(r1v,c1v)];
                        descritizedRoofElementsZnew = [roofZmin,roofZmin,descritizedRoofElementsZ(r2v,c2v),descritizedRoofElementsZ(r1v,c1v)];
                    end
                end
            end
        end
    end
end

