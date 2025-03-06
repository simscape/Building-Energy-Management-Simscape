function plotHeatCoolingRequirementAnalysisOutput(NameValueArgs)
% Function to plot HVAC requirement results.

% Copyright 2024 - 2025 The MathWorks, Inc.

    arguments
        NameValueArgs.SimlogData {mustBeNonempty}
        NameValueArgs.Duration (1,:) datetime {mustBeNonempty}
        NameValueArgs.PlotXAxisParts (1,1) {mustBeNonnegative} = 0
        NameValueArgs.EnergyEntireBuilding {mustBeNonnegative} = false
        NameValueArgs.PlotUnit string {mustBeMember(NameValueArgs.PlotUnit,["BTU per Hour","Watts"])} = "BTU per Hour"
    end

    simStats.scopeData = NameValueArgs.SimlogData.BuildingModelScopeData.extractTimetable;
    simStats.roomTemp  = NameValueArgs.SimlogData.simlog.Building.roomTemp.series.values;
    simStats.wallTemp  = NameValueArgs.SimlogData.simlog.Building.wallTemp.series.values;
    simStats.init      = NameValueArgs.SimlogData.getSimulationMetadata.TimingInfo.InitializationElapsedWallTime;
    simStats.runt      = NameValueArgs.SimlogData.getSimulationMetadata.TimingInfo.ExecutionElapsedWallTime;
    simStats.tert      = NameValueArgs.SimlogData.getSimulationMetadata.TimingInfo.TerminationElapsedWallTime;
    simStats.tott      = NameValueArgs.SimlogData.getSimulationMetadata.TimingInfo.TotalElapsedWallTime;
    % Heating Requirement
    heating_per_hr   = abs(simStats.scopeData.("Btu/hr (per room)")(2:end,2));
    if strcmp(NameValueArgs.PlotUnit,"BTU per Hour"), heating_per_hr = heating_per_hr/3.41;end
    heating_mean     = mean(heating_per_hr);
    heating_ops_mean = mean(heating_per_hr(abs(heating_per_hr)>0));
    % Cooling Requirement
    cooling_per_hr   = abs(simStats.scopeData.("Btu/hr (per room)")(2:end,1));
    if strcmp(NameValueArgs.PlotUnit,"BTU per Hour"), cooling_per_hr = cooling_per_hr/3.41;end
    cooling_mean     = mean(cooling_per_hr);
    cooling_ops_mean = mean(cooling_per_hr(abs(cooling_per_hr)>0));
    timeValues       = NameValueArgs.SimlogData.simlog.Ambient.A.T.series.time;

    if NameValueArgs.EnergyEntireBuilding
        nRooms = size(simStats.roomTemp,2);
    else
        nRooms = 1;
    end

    figure('Name','Energy Requirement');
    bar(["Heating - mean over whole period",...
         "Heating - mean over operational period",...
         "Cooling - mean over whole period",...
         "Cooling - mean over operational period"],...
         [heating_mean,heating_ops_mean,cooling_mean,cooling_ops_mean]*nRooms);
    if NameValueArgs.EnergyEntireBuilding
        ylabel(strcat(NameValueArgs.PlotUnit," for Building")); 
    else
        ylabel(strcat(NameValueArgs.PlotUnit," per Room")); 
    end
    title('Avg. Energy Requirement');

    figure('Name','Energy Requirement per Hour');
    bar(timeValues(2:end),[heating_per_hr,cooling_per_hr]*nRooms);
    legend('Heating','Cooling'); 
    title('Hourly Energy Requirement');
    xlabel('Time (s)');
    if NameValueArgs.EnergyEntireBuilding
        ylabel(strcat(NameValueArgs.PlotUnit," for Building")); 
    else
        ylabel(strcat(NameValueArgs.PlotUnit," per Room")); 
    end

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