function mdl = setParametersForBuildingCustomComponent(NameValueArgs)
% Function to set custom component parameters.

% Copyright 2024 The MathWorks, Inc.

    arguments
        NameValueArgs.Building struct {mustBeNonempty}
        NameValueArgs.BuildingNetworkData struct {mustBeNonempty}
        NameValueArgs.PhysicsTableData struct {mustBeNonempty}
        NameValueArgs.RoomModel string {mustBeNonempty}
    end

    if NameValueArgs.RoomModel == "roomPhysicsOptions.basicroom" || NameValueArgs.RoomModel == "roomPhysicsOptions.requirements"
        mdl = 'BuildingModelWithSolarLoad'; 
        load_system(mdl);
    else
        mdl = 'BuildingModelWithSolarLoadAndHVAC';
        load_system(mdl);
    end
    simRunTimeVal = min(length(NameValueArgs.Building.apartment1.room1.geometry.roof.sunlightFrac)*3600,NameValueArgs.PhysicsTableData.simRunTime);
    set_param(mdl,'StopTime',num2str(simRunTimeVal));
    msgForParamStatus = strcat(' % Parameterized on : ',string(datetime("now")));

    %% Set parameters common to all 5 different room fidelities
    set_param([mdl,'/Building'],'roomModelOption',NameValueArgs.RoomModel);
    set_param([mdl,'/Building'],'nAPts',strcat(num2str(NameValueArgs.BuildingNetworkData.nApt),msgForParamStatus));
    set_param([mdl,'/Building'],'nRooms',strcat(num2str(NameValueArgs.BuildingNetworkData.MaxRoom),msgForParamStatus));
    set_param([mdl,'/Building'],'roomVolMat',strcat(mat2str(NameValueArgs.BuildingNetworkData.roomVolMat),msgForParamStatus));
    set_param([mdl,'/Building'],'roomConnMat',strcat(mat2str(NameValueArgs.BuildingNetworkData.roomConnMat),msgForParamStatus));
    set_param([mdl,'/Building'],'floorConnMat',strcat(mat2str(NameValueArgs.BuildingNetworkData.floorConnMat),msgForParamStatus));
    set_param([mdl,'/Building'],'roomEnvConnMat',strcat(mat2str(NameValueArgs.BuildingNetworkData.roomEnvConnMat),msgForParamStatus));
    set_param([mdl,'/Building'],'roomEnvSolarRad',strcat(mat2str(NameValueArgs.BuildingNetworkData.roomEnvSolarRad),msgForParamStatus));
    set_param([mdl,'/Building'],'roofEnvConnMat',strcat(mat2str(NameValueArgs.BuildingNetworkData.roofEnvConnMat),msgForParamStatus));
    set_param([mdl,'/Building'],'roofEnvSolarRad',strcat(mat2str(NameValueArgs.BuildingNetworkData.roofEnvSolarRad),msgForParamStatus));
    set_param([mdl,'/Building'],'floorGroundConn',strcat(mat2str(NameValueArgs.BuildingNetworkData.floorRoomIDs),msgForParamStatus));
    set_param([mdl,'/Building'],'iniTemperature',strcat(num2str(NameValueArgs.PhysicsTableData.initialTemperature),msgForParamStatus));

    set_param([mdl,'/GroundThermalResistance'],'resistance',strcat(num2str(NameValueArgs.PhysicsTableData.groundThermalResistance),msgForParamStatus));

    set_param([mdl,'/Ambient'],'listOfDays',strcat('[',num2str(NameValueArgs.PhysicsTableData.listOfDays'),']',msgForParamStatus));
    set_param([mdl,'/Ambient'],'sunrise',strcat('[',num2str(NameValueArgs.PhysicsTableData.sunrise),']',msgForParamStatus));
    set_param([mdl,'/Ambient'],'sunset',strcat('[',num2str(NameValueArgs.PhysicsTableData.sunset),']',msgForParamStatus));
    set_param([mdl,'/Ambient'],'startTime',strcat(num2str(NameValueArgs.PhysicsTableData.simStartTime),msgForParamStatus));
    set_param([mdl,'/Ambient'],'avgDayTvec',strcat('[',num2str(NameValueArgs.PhysicsTableData.averageDayTvec),']',msgForParamStatus));
    set_param([mdl,'/Ambient'],'avgNightTvec',strcat('[',num2str(NameValueArgs.PhysicsTableData.averageNightTvec),']',msgForParamStatus));
    set_param([mdl,'/Ambient'],'pcDayTvar',strcat(num2str(NameValueArgs.PhysicsTableData.percentDayTvar),msgForParamStatus));
    set_param([mdl,'/Ambient'],'pcNightTvar',strcat(num2str(NameValueArgs.PhysicsTableData.percentNightTvar),msgForParamStatus));
    set_param([mdl,'/Ambient'],'cloudData','cloudCoverOptions.daily');
    set_param([mdl,'/Ambient'],'cloudCoverVal',strcat('[',num2str(zeros(1,length(NameValueArgs.PhysicsTableData.listOfDays))),']',msgForParamStatus));

    %% Set model specific parameters
    underFloorAreaMat = zeros(NameValueArgs.BuildingNetworkData.nApt,NameValueArgs.BuildingNetworkData.MaxRoom);
    radiatorAreaMat = zeros(NameValueArgs.BuildingNetworkData.nApt,NameValueArgs.BuildingNetworkData.MaxRoom);
    for i = 1:NameValueArgs.BuildingNetworkData.nApt
        for j = 1:NameValueArgs.BuildingNetworkData.MaxRoom
            underFloorAreaMat(i,j) = NameValueArgs.Building.("apartment"+num2str(i)).("room"+num2str(j)).floorPlan.area*...
                                     max(0,min(1,NameValueArgs.Building.("apartment"+num2str(i)).("room"+num2str(j)).physics.underfloor));
            maxLength = max(NameValueArgs.Building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim.width,...
                            NameValueArgs.Building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim.length);
            radiatorAreaMat(i,j) = maxLength*NameValueArgs.Building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim.height*...
                                   max(0,min(1,NameValueArgs.Building.("apartment"+num2str(i)).("room"+num2str(j)).physics.radiator));
        end
    end

    if NameValueArgs.RoomModel == "roomPhysicsOptions.basicroom" || NameValueArgs.RoomModel == "roomPhysicsOptions.requirements"
        if NameValueArgs.RoomModel == "roomPhysicsOptions.basicroom"
            set_param([mdl,'/Building'],'roomModelOption','roomPhysicsOptions.basicroom');
        else
            set_param([mdl,'/Building'],'roomModelOption','roomPhysicsOptions.requirements');
        end
        set_param([mdl,'/T<setPoint>'],'constant',strcat(num2str(NameValueArgs.PhysicsTableData.desiredTempSetPoint),msgForParamStatus));
        set_param([mdl,'/Control/NumRooms'],'constant',strcat('[',mat2str(ones(NameValueArgs.BuildingNetworkData.nApt,NameValueArgs.BuildingNetworkData.MaxRoom)),']',msgForParamStatus));
        set_param([mdl,'/Control/MeasurementDelay'],'y0',strcat(num2str(NameValueArgs.PhysicsTableData.initialTemperature),msgForParamStatus));
    elseif NameValueArgs.RoomModel == "roomPhysicsOptions.roomRadiatorUF"
        set_param([mdl,'/Building'],'roomModelOption','roomPhysicsOptions.roomRadiatorUF');
        set_param([mdl,'/T<setPoint>'],'value',strcat(num2str(NameValueArgs.PhysicsTableData.desiredTempSetPoint),msgForParamStatus));
        % Set operational parameters and room radiator plus UF piping details.
        set_param([mdl,'/Building'],'roomRadiatorArea',strcat(mat2str(radiatorAreaMat),msgForParamStatus));
        set_param([mdl,'/Building'],'roomUFPipingArea',strcat(mat2str(underFloorAreaMat),msgForParamStatus));
        set_param([mdl,'/OperationalData'],'opsParamBldg',strcat(mat2str(NameValueArgs.BuildingNetworkData.physTable),msgForParamStatus));
    elseif NameValueArgs.RoomModel == "roomPhysicsOptions.roomRadiator"
        set_param([mdl,'/Building'],'roomModelOption','roomPhysicsOptions.roomRadiator');
        set_param([mdl,'/T<setPoint>'],'value',strcat(num2str(NameValueArgs.PhysicsTableData.desiredTempSetPoint),msgForParamStatus));
        % Set operational parameters and room radiator piping details.
        set_param([mdl,'/Building'],'roomRadiatorArea',strcat(mat2str(radiatorAreaMat),msgForParamStatus));
        set_param([mdl,'/OperationalData'],'opsParamBldg',strcat(mat2str(NameValueArgs.BuildingNetworkData.physTable),msgForParamStatus));
    else % NameValueArgs.RoomModel == "roomPhysicsOptions.roomUF"
        set_param([mdl,'/Building'],'roomModelOption','roomPhysicsOptions.roomUF');
        set_param([mdl,'/T<setPoint>'],'value',strcat(num2str(NameValueArgs.PhysicsTableData.desiredTempSetPoint),msgForParamStatus));
        % Set operational parameters and room UF piping details.
        set_param([mdl,'/Building'],'roomUFPipingArea',strcat(mat2str(underFloorAreaMat),msgForParamStatus));
        set_param([mdl,'/OperationalData'],'opsParamBldg',strcat(mat2str(NameValueArgs.BuildingNetworkData.physTable),msgForParamStatus));
    end

    %% Print message for user
    disp(strcat('Parameterized Model :',mdl,'.slx'));
    disp(strcat("*** Simulation Time = ",num2str(simRunTimeVal/3600),"-hours"));
    disp(strcat('*** Model Parameterized for Time = ',num2str(length(NameValueArgs.Building.apartment1.room1.geometry.roof.sunlightFrac)),'-hours'));
    disp(strcat('*** Solver :',get_param(mdl,"SolverType"),' (',get_param(mdl,"SolverName"),')'));
    
    %% Save and close model
    save_system(mdl);
    close_system(mdl);
end