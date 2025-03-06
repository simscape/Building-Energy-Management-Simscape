function occupancyRate = set24HourRoomOccupancyNumber(NameValueArgs)
% Function to specify 24hr room occupancy values.

% Copyright 2025 The MathWorks, Inc.

    arguments
        NameValueArgs.OccupancyNumbers (1,24) {mustBeInteger,mustBeNonnegative}
        NameValueArgs.Plot {mustBeNonempty} = false
    end
    occupancyRate = NameValueArgs.OccupancyNumbers;
    if NameValueArgs.Plot
        figure("Name","Home Occupancy Numbers");
        stairs(1:24,occupancyRate,LineWidth=1.5); title("Home Occupancy Numbers")
        xlabel("Hour of the Day"); ylabel("Number of Person");
        ylim([0,max(occupancyRate)+1]);xlim([0,24]);xticks(0:3:24);
    end
end