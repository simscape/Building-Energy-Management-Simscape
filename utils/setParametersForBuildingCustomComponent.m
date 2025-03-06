function mdl = setParametersForBuildingCustomComponent(NameValueArgs)
% Function to set custom component parameters.

% Copyright 2024 The MathWorks, Inc.

    arguments
        NameValueArgs.Building struct {mustBeNonempty}
        NameValueArgs.BuildingNetworkData struct {mustBeNonempty}
        NameValueArgs.RoomModel string {mustBeMember(NameValueArgs.RoomModel,["Thermal Load","Thermal Requirements","HVAC: Room Radiator Only","HVAC: Room Radiator with Underfloor Heating/Cooling","HVAC: Room Underfloor Heating/Cooling Only"])}
        NameValueArgs.Duration datetime {mustBeNonempty}
        NameValueArgs.ExternalHTC (1,1) simscape.Value {simscape.mustBeCommensurateUnit(NameValueArgs.ExternalHTC, "W/(K*m^2)")} = simscape.Value(5,"W/(K*m^2)")
        NameValueArgs.InternalHTC (1,1) simscape.Value {simscape.mustBeCommensurateUnit(NameValueArgs.InternalHTC, "W/(K*m^2)")} = simscape.Value(5,"W/(K*m^2)")
        NameValueArgs.BuildingMaterial (6,5) table {mustBeNonempty}
    end

    if NameValueArgs.RoomModel == "Thermal Load"
        enumNameString = "roomPhysicsOptions.basicroom";
    elseif NameValueArgs.RoomModel == "Thermal Requirements"
        enumNameString = "roomPhysicsOptions.requirements";
    elseif NameValueArgs.RoomModel == "HVAC: Room Radiator Only"
        enumNameString = "roomPhysicsOptions.roomRadiator";
    elseif NameValueArgs.RoomModel == "HVAC: Room Radiator with Underfloor Heating/Cooling"
        enumNameString = "roomPhysicsOptions.roomRadiatorUF";
    elseif NameValueArgs.RoomModel == "HVAC: Room Underfloor Heating/Cooling Only"
        enumNameString = "roomPhysicsOptions.roomUF";
    else
        enumNameString = "roomPhysicsOptions.requirements";
    end


    if enumNameString == "roomPhysicsOptions.basicroom" || enumNameString == "roomPhysicsOptions.requirements"
        mdl = 'BuildingModelWithSolarLoad'; 
        load_system(mdl);
    else
        mdl = 'BuildingModelWithSolarLoadAndHVAC';
        load_system(mdl);
    end
    simRunTimeVal = min(length(NameValueArgs.Building.apartment1.room1.geometry.roof.sunlightWattPerMeterSq)*3600,NameValueArgs.BuildingNetworkData.opsData.simRunTime);
    set_param(mdl,'StopTime',num2str(simRunTimeVal));
    msgForParamStatus = strcat(' % Parameterized on : ',string(datetime("now")));

    %% Set parameters common to all 5 different room fidelities
    set_param([mdl,'/Building'],'roomModelOption',enumNameString);
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
    set_param([mdl,'/Building'],'iniTemperature',strcat(num2str(NameValueArgs.BuildingNetworkData.opsData.initialTemperature),msgForParamStatus));

    set_param([mdl,'/GroundThermalResistance'],'resistance',strcat(num2str(NameValueArgs.BuildingNetworkData.opsData.groundThermalResistance),msgForParamStatus));

    set_param([mdl,'/Ambient'],'listOfDays',strcat('[',num2str(NameValueArgs.BuildingNetworkData.opsData.listOfDays'),']',msgForParamStatus));
    set_param([mdl,'/Ambient'],'sunrise',strcat('[',num2str(NameValueArgs.BuildingNetworkData.opsData.sunrise),']',msgForParamStatus));
    set_param([mdl,'/Ambient'],'sunset',strcat('[',num2str(NameValueArgs.BuildingNetworkData.opsData.sunset),']',msgForParamStatus));
    set_param([mdl,'/Ambient'],'startTime',strcat(num2str(NameValueArgs.BuildingNetworkData.opsData.simStartTime),msgForParamStatus));
    set_param([mdl,'/Ambient'],'avgDayTvec',strcat('[',num2str(NameValueArgs.BuildingNetworkData.opsData.averageDayTvec),']',msgForParamStatus));
    set_param([mdl,'/Ambient'],'avgNightTvec',strcat('[',num2str(NameValueArgs.BuildingNetworkData.opsData.averageNightTvec),']',msgForParamStatus));
    set_param([mdl,'/Ambient'],'pcDayTvar',strcat(num2str(NameValueArgs.BuildingNetworkData.opsData.percentDayTvar),msgForParamStatus));
    set_param([mdl,'/Ambient'],'pcNightTvar',strcat(num2str(NameValueArgs.BuildingNetworkData.opsData.percentNightTvar),msgForParamStatus));
    set_param([mdl,'/Ambient'],'cloudData','cloudCoverOptions.daily');
    set_param([mdl,'/Ambient'],'cloudCoverVal',strcat('[',num2str(zeros(1,length(NameValueArgs.BuildingNetworkData.opsData.listOfDays))),']',msgForParamStatus));

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

    if enumNameString == "roomPhysicsOptions.basicroom" || enumNameString == "roomPhysicsOptions.requirements"
        if enumNameString == "roomPhysicsOptions.basicroom"
            set_param([mdl,'/Building'],'roomModelOption','roomPhysicsOptions.basicroom');
        else
            set_param([mdl,'/Building'],'roomModelOption','roomPhysicsOptions.requirements');
        end
        set_param([mdl,'/T<setPoint>'],'constant',strcat(num2str(NameValueArgs.BuildingNetworkData.opsData.desiredTempSetPoint),msgForParamStatus));
        set_param([mdl,'/Control/NumRooms'],'constant',strcat('[',mat2str(ones(NameValueArgs.BuildingNetworkData.nApt,NameValueArgs.BuildingNetworkData.MaxRoom)),']',msgForParamStatus));
        set_param([mdl,'/Control/MeasurementDelay'],'y0',strcat(num2str(NameValueArgs.BuildingNetworkData.opsData.initialTemperature),msgForParamStatus));
        % Check if physics TABLE has been defined for requirement analysis
        set_param([mdl,'/Control/OperationalData'],'roomModelOption',enumNameString);
        if isfield(NameValueArgs.BuildingNetworkData,"physTable")
            % physics table has been defined
            set_param([mdl,'/Control/OperationalData'],'opsParamBldg',strcat(mat2str(NameValueArgs.BuildingNetworkData.physTable),msgForParamStatus));
            set_param([mdl,'/Control/OperationalData'],'heatPerOccupant',strcat(num2str(NameValueArgs.BuildingNetworkData.opsData.perPersonHeatLoadWatts),msgForParamStatus));
        else
            % no physics table, set default parameters
            physTableDefault = initializeRoomOperationalPhysicsData(Building=NameValueArgs.Building,Duration=NameValueArgs.Duration);
            set_param([mdl,'/Control/OperationalData'],'opsParamBldg',strcat(mat2str(table2array(physTableDefault(:,[2:4,6:9]))),msgForParamStatus));
            set_param([mdl,'/Control/OperationalData'],'heatPerOccupant',strcat(num2str(0),msgForParamStatus));
        end
    elseif enumNameString == "roomPhysicsOptions.roomRadiatorUF"
        set_param([mdl,'/Building'],'roomModelOption','roomPhysicsOptions.roomRadiatorUF');
        set_param([mdl,'/T<setPoint>'],'value',strcat(num2str(NameValueArgs.BuildingNetworkData.opsData.desiredTempSetPoint),msgForParamStatus));
        % Set operational parameters and room radiator plus UF piping details.
        set_param([mdl,'/Building'],'roomRadiatorArea',strcat(mat2str(radiatorAreaMat),msgForParamStatus));
        set_param([mdl,'/Building'],'roomUFPipingArea',strcat(mat2str(underFloorAreaMat),msgForParamStatus));
        set_param([mdl,'/OperationalData'],'opsParamBldg',strcat(mat2str(NameValueArgs.BuildingNetworkData.physTable),msgForParamStatus));
    elseif enumNameString == "roomPhysicsOptions.roomRadiator"
        set_param([mdl,'/Building'],'roomModelOption','roomPhysicsOptions.roomRadiator');
        set_param([mdl,'/T<setPoint>'],'value',strcat(num2str(NameValueArgs.BuildingNetworkData.opsData.desiredTempSetPoint),msgForParamStatus));
        % Set operational parameters and room radiator piping details.
        set_param([mdl,'/Building'],'roomRadiatorArea',strcat(mat2str(radiatorAreaMat),msgForParamStatus));
        set_param([mdl,'/OperationalData'],'opsParamBldg',strcat(mat2str(NameValueArgs.BuildingNetworkData.physTable),msgForParamStatus));
    else % enumNameString == "roomPhysicsOptions.roomUF"
        set_param([mdl,'/Building'],'roomModelOption','roomPhysicsOptions.roomUF');
        set_param([mdl,'/T<setPoint>'],'value',strcat(num2str(NameValueArgs.BuildingNetworkData.opsData.desiredTempSetPoint),msgForParamStatus));
        % Set operational parameters and room UF piping details.
        set_param([mdl,'/Building'],'roomUFPipingArea',strcat(mat2str(underFloorAreaMat),msgForParamStatus));
        set_param([mdl,'/OperationalData'],'opsParamBldg',strcat(mat2str(NameValueArgs.BuildingNetworkData.physTable),msgForParamStatus));
    end

    % In absence of user input, HTC values are set to a value of 5.
    set_param([mdl,'/Building'],'extToWallHTC',strcat(num2str(value(NameValueArgs.ExternalHTC,"W/(K*m^2)")),msgForParamStatus));
    set_param([mdl,'/Building'],'intToRoomHTC',strcat(num2str(value(NameValueArgs.InternalHTC,"W/(K*m^2)")),msgForParamStatus));
    % Set the (optional) building material properties. Property definition
    % is optional, but values must be set for simulations to run. Default
    % values are set in case of no user input for the name-value-pair.
    if ~isempty(NameValueArgs.BuildingMaterial)
        % Set user specified material properties
        tblMat = NameValueArgs.BuildingMaterial;
    else
        % Set default material properties
        tblMat = initializeBuildingMaterialProperties;
    end
    
    set_param([mdl,'/Building'],'wallPropValue','wallPhysicsOptions.allWallNotSame');

    set_param([mdl,'/Building'],'extWallMaterialDenVal',strcat(num2str(tblMat{"Density [kg/m^3]","ExternalWall"}),msgForParamStatus));
    set_param([mdl,'/Building'],'extWallMaterialCpVal',strcat(num2str(tblMat{"Heat Capacity [J/kg-K]","ExternalWall"}),msgForParamStatus));
    set_param([mdl,'/Building'],'extWallAbsorptivityVal',strcat(num2str(tblMat{"Absorptivity [-]","ExternalWall"}),msgForParamStatus));
    set_param([mdl,'/Building'],'extWallThermalKVal',strcat(num2str(tblMat{"Thermal Conductivity [W/K-m]","ExternalWall"}),msgForParamStatus));
    set_param([mdl,'/Building'],'extWallThicknessVal',strcat(num2str(tblMat{"Thickness [m]","ExternalWall"}),msgForParamStatus));
    
    set_param([mdl,'/Building'],'intWallMaterialDenVal',strcat(num2str(tblMat{"Density [kg/m^3]","InternalWall"}),msgForParamStatus));
    set_param([mdl,'/Building'],'intWallMaterialCpVal',strcat(num2str(tblMat{"Heat Capacity [J/kg-K]","InternalWall"}),msgForParamStatus));
    set_param([mdl,'/Building'],'intWallThermalKVal',strcat(num2str(tblMat{"Thermal Conductivity [W/K-m]","InternalWall"}),msgForParamStatus));
    set_param([mdl,'/Building'],'intWallThicknessVal',strcat(num2str(tblMat{"Thickness [m]","InternalWall"}),msgForParamStatus));
    
    set_param([mdl,'/Building'],'intFloorMaterialDenVal',strcat(num2str(tblMat{"Density [kg/m^3]","Floor"}),msgForParamStatus));
    set_param([mdl,'/Building'],'intFloorMaterialCpVal',strcat(num2str(tblMat{"Heat Capacity [J/kg-K]","Floor"}),msgForParamStatus));
    set_param([mdl,'/Building'],'intFloorThermalKVal',strcat(num2str(tblMat{"Thermal Conductivity [W/K-m]","Floor"}),msgForParamStatus));
    set_param([mdl,'/Building'],'intFloorThicknessVal',strcat(num2str(tblMat{"Thickness [m]","Floor"}),msgForParamStatus));
    
    set_param([mdl,'/Building'],'roofMaterialDenVal',strcat(num2str(tblMat{"Density [kg/m^3]","Roof"}),msgForParamStatus));
    set_param([mdl,'/Building'],'roofMaterialCpVal',strcat(num2str(tblMat{"Heat Capacity [J/kg-K]","Roof"}),msgForParamStatus));
    set_param([mdl,'/Building'],'roofAbsorptivityVal',strcat(num2str(tblMat{"Absorptivity [-]","Roof"}),msgForParamStatus));
    set_param([mdl,'/Building'],'roofThermalKVal',strcat(num2str(tblMat{"Thermal Conductivity [W/K-m]","Roof"}),msgForParamStatus));
    set_param([mdl,'/Building'],'roofThicknessVal',strcat(num2str(tblMat{"Thickness [m]","Roof"}),msgForParamStatus));

    set_param([mdl,'/Building'],'winMaterialDen',strcat(num2str(tblMat{"Density [kg/m^3]","Window"}),msgForParamStatus));
    set_param([mdl,'/Building'],'winMaterialCp',strcat(num2str(tblMat{"Heat Capacity [J/kg-K]","Window"}),msgForParamStatus));
    set_param([mdl,'/Building'],'winAbsorptivity',strcat(num2str(tblMat{"Absorptivity [-]","Window"}),msgForParamStatus));
    set_param([mdl,'/Building'],'winTransmissivity',strcat(num2str(tblMat{"Transmissivity [-]","Window"}),msgForParamStatus));
    set_param([mdl,'/Building'],'winThickness',strcat(num2str(tblMat{"Thickness [m]","Window"}),msgForParamStatus));
    set_param([mdl,'/Building'],'winThermalK',strcat(num2str(tblMat{"Thermal Conductivity [W/K-m]","Window"}),msgForParamStatus));

    %% Print message for user
    disp(strcat('Parameterized Model :',mdl,'.slx'));
    disp(strcat("*** Simulation Time = ",num2str(simRunTimeVal/3600),"-hours"));
    disp(strcat('*** Model Parameterized for Time = ',num2str(length(NameValueArgs.Building.apartment1.room1.geometry.roof.sunlightWattPerMeterSq)),'-hours'));
    disp(strcat('*** Solver :',get_param(mdl,"SolverType"),' (',get_param(mdl,"SolverName"),')'));
    
    %% Save and close model
    save_system(mdl);
    close_system(mdl);
end