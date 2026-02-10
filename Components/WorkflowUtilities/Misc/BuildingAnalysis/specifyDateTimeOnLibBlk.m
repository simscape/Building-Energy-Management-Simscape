function specifyDateTimeOnLibBlk(NameValueArgs)
% Specify datetime on library block
%
% Copyright 2025 The MathWorks, Inc.

    arguments
        NameValueArgs.StartTime datetime {mustBeNonempty}
        NameValueArgs.EndTime datetime {mustBeNonempty}
        NameValueArgs.CustomLibBlkPath string {mustBeNonempty}
        NameValueArgs.CustomLibBlkName string {mustBeNonempty}
    end

    nHours = hours(NameValueArgs.EndTime-NameValueArgs.StartTime);
    nDays = ceil(nHours/24)+1;
    set_param(NameValueArgs.CustomLibBlkPath,"startYear",num2str(year(NameValueArgs.StartTime)));
    set_param(NameValueArgs.CustomLibBlkPath,"startMonth",num2str(month(NameValueArgs.StartTime)));
    set_param(NameValueArgs.CustomLibBlkPath,"startDay",num2str(day(NameValueArgs.StartTime)));
    set_param(NameValueArgs.CustomLibBlkPath,"startHr",num2str(hour(NameValueArgs.StartTime)));
    
    
    if NameValueArgs.CustomLibBlkName == "TemperatureSource_lib"
        set_param(NameValueArgs.CustomLibBlkPath,"numDaysData",num2str(nDays));
    else
        % "SolarRadiationOnSurface_lib", "SolarRadiationAtLocation_lib", "ExternalWall_lib"
        set_param(NameValueArgs.CustomLibBlkPath,"numHrsData",num2str(nHours));
    end
end