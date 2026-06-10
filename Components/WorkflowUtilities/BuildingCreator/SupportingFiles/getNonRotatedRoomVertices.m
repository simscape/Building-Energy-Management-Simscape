function roomJvert = getNonRotatedRoomVertices(NameValueArgs)
% Find building room vertices, non-rotated
% 
% Copyright 2025 The MathWorks, Inc.

    arguments
        NameValueArgs.Apartment struct {mustBeNonempty}
        NameValueArgs.NumberApartment (1,1) {mustBeNonnegative}
        NameValueArgs.NumberRoom (1,1) {mustBeNonnegative}
    end

    tht = NameValueArgs.Apartment.("apartment"+NameValueArgs.NumberApartment).("room"+NameValueArgs.NumberRoom).geometry.dim.theta;
    if NameValueArgs.Apartment.("apartment"+NameValueArgs.NumberApartment).("room"+NameValueArgs.NumberRoom).geometry.dim.floorPlanRotation == 0
        len = NameValueArgs.Apartment.("apartment"+NameValueArgs.NumberApartment).("room"+NameValueArgs.NumberRoom).geometry.dim.length;
        wid = NameValueArgs.Apartment.("apartment"+NameValueArgs.NumberApartment).("room"+NameValueArgs.NumberRoom).geometry.dim.width;
        vrt = NameValueArgs.Apartment.("apartment"+NameValueArgs.NumberApartment).("room"+NameValueArgs.NumberRoom).geometry.dim.vertex;
        roomModel = addNewRoomToFloorPlan(vrt,wid,len,tht,"Temp");
        roomJvert = roomModel.floorPlan.Vertices;
    else
        % Entire floor plan might have been rotated and hence this step
        % (and not re-creating vertices as when tht is zero). The rotation
        % vertex and the room vertex may not necessarily be the same.
        roomJvert = NameValueArgs.Apartment.("apartment"+NameValueArgs.NumberApartment).("room"+NameValueArgs.NumberRoom).floorPlan.rotate(360-tht).Vertices;
    end
end