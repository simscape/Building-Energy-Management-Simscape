function plotData = monthlyAveragedHeatingRequirement(NameValueArgs)
% Function to plot monthly averaged results.

% Copyright 2025 The MathWorks, Inc.

    arguments
        NameValueArgs.ResultSummary struct {mustBeNonempty}
        NameValueArgs.PlotType string {mustBeMember(NameValueArgs.PlotType,["Heating Requirements","Cooling Requirements","Heating and Cooling Requirements"])} = "Heating and Cooling Requirements"
        NameValueArgs.PlotOption string {mustBeMember(NameValueArgs.PlotOption,["Watt","BTU per Hr"])} = "Watt"
    end
    
    OneWattToBtuPerHr = 3.412141633;

    placeOfInterest = fieldnames(NameValueArgs.ResultSummary);
    
    if strcmp(NameValueArgs.PlotType,"Heating Requirements") || strcmp(NameValueArgs.PlotType,"Heating and Cooling Requirements")
        monthlyAvgHeating = cell(size(placeOfInterest,1),1);
        plotTitleHeating = "Building Heating Requirement for Different Places";
        figure("Name",plotTitleHeating);
        legendStr = strings(size(placeOfInterest,1),1);
        count = 0; 
        for i = 1:size(placeOfInterest,1)
            if isfield(NameValueArgs.ResultSummary.(placeOfInterest{i,1}),"results") && ...
               isfield(NameValueArgs.ResultSummary.(placeOfInterest{i,1}),"dateTimeVector")
                count = count+1;
                legendStr(count,1) = placeOfInterest{i,1};
                Q = NameValueArgs.ResultSummary.(placeOfInterest{i,1}).results;
                tm = NameValueArgs.ResultSummary.(placeOfInterest{i,1}).dateTimeVector;
                Qheating = Q.*(Q>0);
                Qh = sum(Qheating,2)';
                if strcmp(NameValueArgs.PlotOption,"BTU per Hr"), Qh = OneWattToBtuPerHr.*Qh; end
                
                monthlyAvgHeating{i,1} = getMonthlyAveragedData(DateTimeVec=tm,Data=Qh,Plot=false);
                plot(monthlyAvgHeating{i,1}.Time,monthlyAvgHeating{i,1}.data);hold on;
            end
        end
        hold off;
        legend(legendStr(1:count)');
        if strcmp(NameValueArgs.PlotOption,"BTU per Hr")
            ylabel("Heating Requirement [BTU / hr]");
        else
            ylabel("Heating Requirement [W]");
        end
        title(plotTitleHeating);
        plotData.monthlyAvgHeating = monthlyAvgHeating;
    end

    if strcmp(NameValueArgs.PlotType,"Cooling Requirements") || strcmp(NameValueArgs.PlotType,"Heating and Cooling Requirements")
        % monthlyAvgHeating = cell(size(placeOfInterest,1),1);
        monthlyAvgCooling = cell(size(placeOfInterest,1),1);
        plotTitleCooling = "Building Cooling Requirement for Different Places";
        figure("Name",plotTitleCooling);
        legendStr = strings(size(placeOfInterest,1),1);
        count = 0;
        for i = 1:size(placeOfInterest,1)
            if isfield(NameValueArgs.ResultSummary.(placeOfInterest{i,1}),"results") && ...
               isfield(NameValueArgs.ResultSummary.(placeOfInterest{i,1}),"dateTimeVector")
                count = count+1;
                legendStr(count,1) = placeOfInterest{i,1};
                Q = NameValueArgs.ResultSummary.(placeOfInterest{i,1}).results;
                tm = NameValueArgs.ResultSummary.(placeOfInterest{i,1}).dateTimeVector;
                Qcooling = Q.*(Q<0);
                Qc = -sum(Qcooling,2)';
                if strcmp(NameValueArgs.PlotOption,"BTU per Hr"), Qc = OneWattToBtuPerHr.*Qc; end
                monthlyAvgCooling{i,1} = getMonthlyAveragedData(DateTimeVec=tm,Data=Qc,Plot=false);
                plot(monthlyAvgCooling{i,1}.Time,monthlyAvgCooling{i,1}.data);hold on;
            end
        end
        hold off;
        legend(legendStr(1:count)');
        if strcmp(NameValueArgs.PlotOption,"BTU per Hr")
            ylabel("Cooling Requirement [BTU / hr]");
        else
            ylabel("Cooling Requirement [W]");
        end
        title(plotTitleCooling);
        plotData.monthlyAvgCooling = monthlyAvgCooling;
    end
end