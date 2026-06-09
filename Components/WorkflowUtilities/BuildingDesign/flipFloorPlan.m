function flippedRoomParams = flipFloorPlan(NameValueArgs)
% Function to flip a floor plan about a specified axis.
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
        NameValueArgs.FloorPlan struct {mustBeNonempty}
        NameValueArgs.Axis string {mustBeMember(NameValueArgs.Axis,["x","y"])}
        NameValueArgs.AxisValue (1,1) simscape.Value {simscape.mustBeCommensurateUnit(NameValueArgs.AxisValue, "m")}
    end

    floorPlan = NameValueArgs.FloorPlan;
    Axis = NameValueArgs.Axis;
    axisPos   = value(NameValueArgs.AxisValue, 'm');

    % Compute flipped parameters for each room.
    % A flip reverses polygon winding, so the new construction vertex
    % shifts to what was originally corner C3 (reflected), and the
    % rotation angle adjusts to preserve the flipped shape.
    flippedRoomParams = struct([]);
    for i = 1:numel(floorPlan)
        vx    = floorPlan(i).geometry.dim.vertex(1);
        vy    = floorPlan(i).geometry.dim.vertex(2);
        w     = floorPlan(i).geometry.dim.width;
        l     = floorPlan(i).geometry.dim.length;
        theta = floorPlan(i).geometry.dim.theta;

        if Axis == "x"
            % Flip about vertical line x = axisPos
            % New vertex corresponds to reflected C3 of original
            newVertex = [2*axisPos - vx + l*sind(theta), ...
                         vy + l*cosd(theta)];
            newTheta  = 180 - theta;
        else
            % Flip about horizontal line y = axisPos
            % New vertex corresponds to reflected C3 of original
            newVertex = [vx - l*sind(theta), ...
                         2*axisPos - vy - l*cosd(theta)];
            newTheta  = -theta;
        end

        flippedRoomParams(i).name   = floorPlan(i).name;
        flippedRoomParams(i).vertex = simscape.Value(newVertex, 'm');
        flippedRoomParams(i).length = simscape.Value(l, 'm');
        flippedRoomParams(i).width  = simscape.Value(w, 'm');
        flippedRoomParams(i).theta  = simscape.Value(newTheta, 'deg');
    end
end
