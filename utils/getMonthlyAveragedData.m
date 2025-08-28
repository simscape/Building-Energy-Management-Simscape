function monthlyAvg = getMonthlyAveragedData(NameValueArgs)
% Function to plot monthly averaged results.

% Copyright 2025 The MathWorks, Inc.

    arguments
        NameValueArgs.DateTimeVec datetime {mustBeNonempty}
        NameValueArgs.Data (1,:) {mustBeNonempty}
        NameValueArgs.Plot {mustBeNonempty} = false
        NameValueArgs.DisplayData {mustBeNonempty} = false
        NameValueArgs.PlotName string {mustBeNonempty} = "data"
    end

    if length(NameValueArgs.Data) == length(NameValueArgs.DateTimeVec)
        data = NameValueArgs.Data(2:end)';
        time = NameValueArgs.DateTimeVec(2:end)';
        tbl = timetable(data,RowTimes=time);
        monthlyAvg = retime(tbl,'monthly','mean');
        if NameValueArgs.Plot
            plotName = strcat("Monthly Average Results (",NameValueArgs.PlotName,")");
            figure("Name",plotName);
            plot(monthlyAvg.Time,monthlyAvg.data);
            title(plotName);
            xlabel("Time");ylabel(NameValueArgs.PlotName);
        end
        if NameValueArgs.DisplayData
            disp(monthlyAvg);
        end
    else
        monthlyAvg = [];
        disp("*** DateTimeVec and Data must be of same length");
    end
end