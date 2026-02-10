function datacenter = buildDatacenter(NameValueArgs)
% Build data center based on fidelity selection and number of PDU units.
% 
% For more details, see <a href="matlab:web('FunctionReferenceList.html')">Function Reference List</a>
% 
% Copyright 2025 - 2026 The MathWorks, Inc.

    arguments(Input)
        NameValueArgs.NumPDUunitsX (1,1) {mustBeGreaterThan(NameValueArgs.NumPDUunitsX,1)}
        NameValueArgs.NumPDUunitsY (1,1) {mustBeGreaterThan(NameValueArgs.NumPDUunitsY,1)}
        NameValueArgs.ModelName string {mustBeText}
        NameValueArgs.ModelOption string {mustBeMember(NameValueArgs.ModelOption,["Electrical","Thermal","Electrothermal"])}
        NameValueArgs.RatingDatacenter (1,1) simscape.Value {simscape.mustBeCommensurateUnit(NameValueArgs.RatingDatacenter, "kW")} = simscape.Value(50, "kW")
        NameValueArgs.PowerSupplyEff (1,1) {mustBeBetween(NameValueArgs.PowerSupplyEff,0,100)} = 85
        NameValueArgs.ThermalRes (1,1) simscape.Value {simscape.mustBeCommensurateUnit(NameValueArgs.ThermalRes, "K/W")} = simscape.Value(1, "K/W")
        NameValueArgs.Diagnostics logical {mustBeNumericOrLogical} = false
    end

    if bdIsLoaded(NameValueArgs.ModelName)
        datacenter = createDatacenter(NumPDUunitsX=NameValueArgs.NumPDUunitsX,...
                                      NumPDUunitsY=NameValueArgs.NumPDUunitsY,...
                                      ModelName=NameValueArgs.ModelName,...
                                      ModelOption=NameValueArgs.ModelOption,...
                                      Diagnostics=NameValueArgs.Diagnostics);
        if ~isempty(datacenter)
            specifyDatacenterRating(Datacenter=datacenter,...
                                    PowerSupplyEff=NameValueArgs.PowerSupplyEff,...
                                    Rating=NameValueArgs.RatingDatacenter,...
                                    ThermalRes=NameValueArgs.ThermalRes,...
                                    Diagnostics=NameValueArgs.Diagnostics);
        else
            disp("WARNING: Skipping datacenter parameterization.");
        end
    else
        disp(strcat("ERROR: Model '",NameValueArgs.ModelName,"' is not loaded or open."));
    end
end
