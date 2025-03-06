function plotTimeSeriesTempRoomWallAmbient(NameValueArgs)
% Function to plot wall/room temperatures from HVAC requirement analysis.

% Copyright 2024 - 2025 The MathWorks, Inc.

    arguments
        NameValueArgs.SimlogData {mustBeNonempty}
        NameValueArgs.Duration (1,:) datetime {mustBeNonempty}
        NameValueArgs.PlotXAxisParts (1,1) {mustBeNonnegative} = 0
    end
    % Plot ambient, room, and wall temperature profile
    figure('Name','Temperature Change with Time')
    plot(NameValueArgs.SimlogData.simlog.Ambient.A.T.series.time,NameValueArgs.SimlogData.simlog.Ambient.A.T.series.values,'ko--'); hold on;
    plot(NameValueArgs.SimlogData.simlog.Ambient.A.T.series.time,NameValueArgs.SimlogData.simlog.Building.roomTemp.series.values); hold on;
    plot(NameValueArgs.SimlogData.simlog.Ambient.A.T.series.time,NameValueArgs.SimlogData.simlog.Building.wallTemp.series.values,'.-'); hold off;
    title('Ambient, Room, and Wall Temperature Variation');
    xlabel('Time (s)');ylabel('Temperature [K]');
    
    if NameValueArgs.PlotXAxisParts <= 1
        dt = 3600;
    else
        delTime = max(3600,3600*length(NameValueArgs.Duration)/NameValueArgs.PlotXAxisParts);
        dt = delTime-mod(delTime,3600);
    end
    rangeTicks = 3600:dt:3600*length(NameValueArgs.Duration);
    rangeLabel = rangeTicks/3600;
    xticks(rangeTicks);
    xticklabels(string(NameValueArgs.Duration(1,rangeLabel)));
end