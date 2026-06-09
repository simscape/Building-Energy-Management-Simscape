function modelApt = flipApartmentUnit(NameValueArgs)
% Function to flip an apartment about a specified axis.
% Returns the vertex, length, width, and angle values for each room in
% the flipped figure without creating the rooms.
%
% Axis "x": flip about the vertical line x = AxisValue
% Axis "y": flip about the horizontal line y = AxisValue
%
% The output parameters can be passed directly to addRoomToFloorPlan /
% addNewRoomToFloorPlan to create the flipped rooms.
%

% Copyright 2026 The MathWorks, Inc.

    arguments
        NameValueArgs.Apartment struct {mustBeNonempty}
        NameValueArgs.Axis string {mustBeMember(NameValueArgs.Axis,["x","y"])}
        NameValueArgs.AxisValue (1,1) simscape.Value {mustBeNonempty}
        NameValueArgs.Tol (1,1) {mustBeNonnegative, mustBeLessThan(NameValueArgs.Tol,100)} = 0.01
    end

    flippedApt = [];
    numRooms = length(fieldnames(NameValueArgs.Apartment));
    for i = 1:numRooms
        roomData = flipFloorPlan(Axis=NameValueArgs.Axis,...
                                      AxisValue=NameValueArgs.AxisValue,...
                                      FloorPlan=NameValueArgs.Apartment.("room"+num2str(i)));
        flippedApt = addRoomToFloorPlan(FloorPlan=flippedApt,...
                                        Length=roomData.length,...
                                        Width=roomData.width,...
                                        Vertex=roomData.vertex,...
                                        Angle=roomData.theta,...
                                        NewRoom=roomData.name);
    end
    modelApt = defineSingleApartmentUnit(Apartment=flippedApt,...
                                         Tol=NameValueArgs.Tol);
end
