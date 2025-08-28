function tblDataWindowVent = updateWindowVentTableData(NameValueArgs)
% Function to update external wall opening data.

% Copyright 2025 The MathWorks, Inc.

    arguments
        NameValueArgs.FloorPlan struct {mustBeNonempty}
        NameValueArgs.TableData table {mustBeNonempty}
        NameValueArgs.WallData struct {mustBeNonempty}
        NameValueArgs.ModelDataUnit string {mustBeNonempty}
        NameValueArgs.Tol (1,1) {mustBeNonnegative} = 0.01
    end

    tblDataWindowVent = NameValueArgs.TableData;
    totPts = max(tblDataWindowVent.("From Point"));
    nWinCAD = length(fieldnames(NameValueArgs.WallData));
    for i = 1:totPts
        if i == totPts
            id1 = totPts;
            id2 = 1;
        else
            id1 = i;
            id2 = i+1;
        end
        idVec = find(and(tblDataWindowVent.("From Point")==id1,tblDataWindowVent.("To Point")==id2));
        for j = 1:size(idVec,1)
            roomInfo = str2num(tblDataWindowVent.("Wall Index")(idVec(j,1),1));
            roomVert = NameValueArgs.FloorPlan.("apartment"+roomInfo(1,1)).("room"+roomInfo(1,2)).floorPlan.Vertices;
            for k = 1:nWinCAD
                % Convert to SI units
                % wallVertOpening = NameValueArgs.WallData.("window"+k).wallOrientation(1:2,1:2);
                % wallWithUnits = simscape.Value(wallVertOpening,NameValueArgs.ModelDataUnit);
                wallWithUnits = NameValueArgs.WallData.("window"+k).wallOrientation(1:2,1:2);
                wallVert = value(wallWithUnits,"m");
                %
                [mw,cw] = slopeOfLineThroughTwoPoint([wallVert(1,:);wallVert(2,:)],NameValueArgs.Tol);
                for r = 1:size(roomVert,1)
                    if r == size(roomVert,1)
                        r1 = size(roomVert,1);
                        r2 = 1;
                    else
                        r1 = r;
                        r2 = r+1;
                    end
                    [mr,cr] = slopeOfLineThroughTwoPoint([roomVert(r1,:);roomVert(r2,:)],NameValueArgs.Tol);
                    if ismembertol(mw,mr,NameValueArgs.Tol) && ismembertol(cr,cw,NameValueArgs.Tol)
                        [wallFracVal,~] = testParallelLineOverlapLength([roomVert(r1,:);roomVert(r2,:)],wallVert,NameValueArgs.Tol);
                        if wallFracVal > 0
                            tblDataWindowVent.("Window (0-1)")(idVec(j,1),1) = tblDataWindowVent.("Window (0-1)")(idVec(j,1),1) + NameValueArgs.WallData.("window"+k).openingFrac;
                        end
                    end
                end
            end
        end
    end
end