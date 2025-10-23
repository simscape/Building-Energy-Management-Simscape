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
            roomVert = str2num(tblDataWindowVent.("Overlap Vertices")(idVec(j,1),1));
            roomVert = [roomVert(1,1:2);roomVert(1,3:4)];
            for k = 1:nWinCAD
                % Convert to SI units
                wallWithUnits = NameValueArgs.WallData.("window"+k).wallOrientation(1:2,1:2);
                wallVert = value(wallWithUnits,"m");
                %
                [mw,cw] = slopeOfLineThroughTwoPoint([wallVert(1,:);wallVert(2,:)],NameValueArgs.Tol);
                [mr,cr] = slopeOfLineThroughTwoPoint(roomVert,NameValueArgs.Tol);
                if ismembertol(mw,mr,NameValueArgs.Tol) && ismembertol(cr,cw,NameValueArgs.Tol)
                    [wallFracVal,~] = testParallelLineOverlapLength(wallVert,roomVert,NameValueArgs.Tol);
                    if wallFracVal > 0
                        tblDataWindowVent.("Window (0-1)")(idVec(j,1),1) = tblDataWindowVent.("Window (0-1)")(idVec(j,1),1) + NameValueArgs.WallData.("window"+k).openingFrac;
                    end
                end
            end
        end
    end
end