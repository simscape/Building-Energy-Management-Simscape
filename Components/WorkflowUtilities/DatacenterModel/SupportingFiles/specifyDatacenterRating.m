function specifyDatacenterRating(NameValueArgs)
% Specify datacenter rating.
% 
% Copyright 2025 The MathWorks, Inc.

    arguments(Input)
        NameValueArgs.Datacenter struct
        NameValueArgs.RatingDatacenter (1,1) simscape.Value {simscape.mustBeCommensurateUnit(NameValueArgs.RatingDatacenter, "kW")} = simscape.Value(50, "kW")
        NameValueArgs.PowerSupplyEff (1,1) {mustBeBetween(NameValueArgs.PowerSupplyEff,0,100)} = 85
        NameValueArgs.ThermalRes (1,1) simscape.Value {simscape.mustBeCommensurateUnit(NameValueArgs.ThermalRes, "K/W")} = simscape.Value(1, "K/W")
        NameValueArgs.Diagnostics logical {mustBeNumericOrLogical} = false
    end

    desiredPower = value(NameValueArgs.RatingDatacenter,"W");
    percentPowerSupplyEff = 85;
    thermalResVal_KperW = value(NameValueArgs.ThermalRes,"K/W");
    datacenter = NameValueArgs.Datacenter;

    X = size(datacenter.Servers.Name,1);
    Y = size(datacenter.Servers.Name,2);
    numPDUmatrix = X*Y;
    
    PDUrating = str2double(get_param(datacenter.Servers.Name(1,1),"peakPowCPU"))*str2double(get_param(datacenter.Servers.Name(1,1),"numOfCPU")) + ...
        str2double(get_param(datacenter.Servers.Name(1,1),"peakPowMemory"))*str2double(get_param(datacenter.Servers.Name(1,1),"numOfMemory")) + ...
        str2double(get_param(datacenter.Servers.Name(1,1),"peakPowDisk"))*str2double(get_param(datacenter.Servers.Name(1,1),"numOfDisk")) + ...
        str2double(get_param(datacenter.Servers.Name(1,1),"peakPowPCIslot"))*str2double(get_param(datacenter.Servers.Name(1,1),"numOfPCIslot")) + ...
        str2double(get_param(datacenter.Servers.Name(1,1),"peakPowMotherboard"))*str2double(get_param(datacenter.Servers.Name(1,1),"numOfMotherboard")) + ...
        str2double(get_param(datacenter.Servers.Name(1,1),"peakPowFan"))*str2double(get_param(datacenter.Servers.Name(1,1),"numOfFan"));
    
    multFact = str2double(get_param(datacenter.Servers.Name(1,1),"ratioActualToNameplate"))/(percentPowerSupplyEff/100);
    
    n = round(desiredPower/(PDUrating*multFact*numPDUmatrix));
    if NameValueArgs.Diagnostics, disp(strcat("*** Number of servers per PDU = ",num2str(n))); end
    
    for i = 1:X
        for j = 1:Y
            set_param(datacenter.Servers.Name(i,j),"numCPUperServer",num2str(n));
            set_param(datacenter.Servers.Name(1,1),"powerSupplyEff",num2str(percentPowerSupplyEff))
        end
    end
    
    if datacenter.Datacenter.Type == "Electrical"
        allThermalRes = datacenter.ThermalRes.Name;
    else
        allThermalRes = [datacenter.WallThermalRes.Name;datacenter.ThermalRes.Name];
    end

    for i = 1:size(allThermalRes,1)
        set_param(allThermalRes(i,1),"resistance",num2str(thermalResVal_KperW));
    end
end