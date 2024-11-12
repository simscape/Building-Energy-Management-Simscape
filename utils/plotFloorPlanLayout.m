function plotFloorPlanLayout(NameValueArgs)
% Function to plot floorplans.

% Copyright 2024 The MathWorks, Inc.

   arguments
        NameValueArgs.PlotData struct {mustBeNonempty}
        NameValueArgs.Type (1,1) string {mustBeMember(NameValueArgs.Type,["room","floorplan","apartment"])}
    end

    if strcmp(NameValueArgs.Type,"room")
        numRooms = length(NameValueArgs.PlotData);
        for i = 1:numRooms
            plot(NameValueArgs.PlotData(1,i).floorPlan);hold on;
            [x,y] = NameValueArgs.PlotData(1,i).floorPlan.centroid;
            text(x,y,NameValueArgs.PlotData(1,i).name);
        end
        title('Single Apartment Unit Floor Plan');
    elseif strcmp(NameValueArgs.Type,"floorplan")
        numApartments = numel(fieldnames(NameValueArgs.PlotData));
        for i = 1:numApartments
            numRooms = numel(fieldnames(NameValueArgs.PlotData.("apartment"+num2str(i))));
            for j = 1:numRooms
                plot(NameValueArgs.PlotData.("apartment"+num2str(i)).("room"+num2str(j)).floorPlan);hold on;
                [x,y] = NameValueArgs.PlotData.("apartment"+num2str(i)).("room"+num2str(j)).floorPlan.centroid;
                text(x,y,NameValueArgs.PlotData.("apartment"+num2str(i)).("room"+num2str(j)).name);
            end
        end
        title(strcat('Apartment # 1-',num2str(numApartments)));
    elseif strcmp(NameValueArgs.Type,"apartment")
        numRooms = numel(fieldnames(NameValueArgs.PlotData));
        for i = 1:numRooms
            plot(NameValueArgs.PlotData.("room"+num2str(i)).floorPlan);hold on;
            [x,y] = NameValueArgs.PlotData.("room"+num2str(i)).floorPlan.centroid;
            text(x,y,NameValueArgs.PlotData.("room"+num2str(i)).name);
        end
        title("Apartment")
    else
        disp("Check Option specified --- choose from room, apartment, or floorplan")
    end
    hold off
    axis equal;xlabel('East');ylabel('North');
    grid("on"); 
end