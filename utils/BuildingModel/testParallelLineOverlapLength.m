% Find parallel line overlap length rquired for find room-to-room wall
% overlap.

% Copyright 2024 The MathWorks, Inc.

function overlapValue = testParallelLineOverlapLength(wallCoord,testCoord,tolr)
    overlapValue = 0;
    x1 = wallCoord(1,1);y1 = wallCoord(1,2);
    x2 = wallCoord(2,1);y2 = wallCoord(2,2);
    a1 = testCoord(1,1);b1 = testCoord(1,2);
    a2 = testCoord(2,1);b2 = testCoord(2,2);

    wallLength = sqrt(sum(wallCoord(:,1).^2) + sum(wallCoord(:,2).^2));
    
    overlappingPts = 0;
    if ismembertol([x1,x2,y1,y2],[a1,a2,b1,b2],tolr) 
        overlappingPts = 1;
        overlapValue = wallLength;
    end

    if ismembertol([x2,x1,y2,y1],[a1,a2,b1,b2],tolr) 
        overlappingPts = 1;
        overlapValue = wallLength;
    end

    if overlappingPts == 0
        isa1b1BetweenXY = isPointBetween([a1,b1],[x1,y1],[x2,y2],tolr);
        isa2b2BetweenXY = isPointBetween([a2,b2],[x1,y1],[x2,y2],tolr);
        isx1y1BetweenAB = isPointBetween([x1,y1],[a1,b1],[a2,b2],tolr);
        isx2y2BetweenAB = isPointBetween([x2,y2],[a1,b1],[a2,b2],tolr);
        if isa1b1BetweenXY==1 && isa2b2BetweenXY==1
            % Both (ab) points between (xy) points
            overlapValue = sqrt((x1-x2)^2+(y1-y2)^2)/sqrt((a1-a2)^2+(b1-b2)^2);
        elseif isx1y1BetweenAB==1 && isx2y2BetweenAB==1
            % Both (xy) points between (ab) points
            overlapValue = 1;
        elseif isa1b1BetweenXY==1 && isa2b2BetweenXY~=1
            if isx1y1BetweenAB
                overlapValue = sqrt((x1-a1)^2+(y1-b1)^2)/sqrt((x1-x2)^2+(y1-y2)^2);
            else % isx2y2BetweenAB
                overlapValue = sqrt((x2-a1)^2+(y2-b1)^2)/sqrt((x1-x2)^2+(y1-y2)^2);
            end
        elseif isa1b1BetweenXY~=1 && isa2b2BetweenXY==1
            if isx1y1BetweenAB
                overlapValue = sqrt((x1-a2)^2+(y1-b2)^2)/sqrt((x1-x2)^2+(y1-y2)^2);
            else % isx2y2BetweenAB
                overlapValue = sqrt((x2-a2)^2+(y2-b2)^2)/sqrt((x1-x2)^2+(y1-y2)^2);
            end
        elseif isx1y1BetweenAB==1 && isx2y2BetweenAB~=1
            if isa1b1BetweenXY
                overlapValue = sqrt((a1-x1)^2+(b1-y1)^2)/sqrt((x1-x2)^2+(y1-y2)^2);
            else % isa2b2BetweenXY
                overlapValue = sqrt((a2-x1)^2+(b2-y1)^2)/sqrt((x1-x2)^2+(y1-y2)^2);
            end
        elseif isx1y1BetweenAB~=1 && isx2y2BetweenAB==1
            if isa1b1BetweenXY
                overlapValue = sqrt((a1-x2)^2+(b1-y2)^2)/sqrt((x1-x2)^2+(y1-y2)^2);
            else % isa2b2BetweenXY
                overlapValue = sqrt((a2-x2)^2+(b2-y2)^2)/sqrt((x1-x2)^2+(y1-y2)^2);
            end
        else
            overlapValue = 0;
        end
    end

    % overlapValue = max(0,min(1,overlapValue));
    if overlapValue < tolr
        overlapValue = 0;
    end
end