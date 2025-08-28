# Building Energy Management System with Simscape

[![View Building Energy Management System with Simscape on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://mathworks.com/matlabcentral/fileexchange/175604-building-energy-management-system-with-simscape)

[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=simscape/Building-Energy-Management-Simscape)
 
 
<table>
  <tr>
    <td class="text-column" width=1200>This project uses Simscape&trade; libraries to model a building, add solar radiation load to it, 
simulate for HVAC  requirements, and setup the model for Building Energy Management System (BEMS) simulations. The project includes 
basic functionalities to evaluate and size HVAC concepts such as radiators and underfloor heating or cooling. You can use these models 
as a starting point to design BEMS software. The project Workflow uses two Simscape Model files that leverage one or more of the following 
Simscape custom Components: Building, Ambient, Operational Data, and EN14511 datasheet based Heat Pump.
    </td>
  </tr>
</table>

<table>
  <tr>
    <td class="text-column" width=1200></td>
  </tr>
</table>

<hr color="gray" size="10">

## Create Building Models Quickly and Analyze Solar Loading.
<table>
  <tr>
    <td class="text-column" width=1200>In this section, you will learn how to create buildings, add solar load to it, and setup analysis models. 
There are three different approaches to choose from. You can choose to create your own building by using utilities provided in this project (1), 
using libraries provided in this project (2), or importing your Building Information Model BIM into Simscape (3).
    </td>
  </tr>
</table>

<table>
  <tr>
    <td class="image-column" width=400><img src="Overview/Images/createBuildingREADME.gif" alt="Create Building1"></td>
    <td class="image-column" width=400><img src="Overview/Images/houseAnimationREADME.gif" alt="Create Building1"></td>
    <td class="text-column" width=25></td>
    <td class="text-column" width=375>(1) Create a multi-storied building and integrate solar load at any location and building orientation. Design more energy efficient buildings by changing windows and walls size, thickness, material and surface properties like reflectivity and absorptivity.</td>
  </tr>
  <tr>
    <td class="image-column" width=400><img src="Overview/Images/BuildingCustomComponentLibrary.png" alt="Create Building2"></td>
    <td class="image-column" width=400><img src="Workflow/DetailedHouseModel/DetailedHouseModelSnapshot.png" alt="Create Building2"></td>
    <td class="text-column" width=25></td>
    <td class="text-column" width=375>(2) Learn how to use building library components listed under Simscape Custom Components in the Simulink Library Browser. Use the library elements to build a simple one room house that is divided or discretized into (3,2,2) parts in the (x,y,z) direction.</td>
  </tr>
  <tr>
    <td class="image-column" width=400><img src="Overview/Images/imgBuildingFiveRectRoomREADME.png" alt="Create Building2"></td>
    <td class="image-column" width=400><img src="Overview/Images/importBIMintoSimscape.png" alt="Create Building2"></td>
    <td class="text-column" width=25></td>
    <td class="text-column" width=375>(3) Learn how to extract geometry data from BIM model, create a Simscape building model, and add operational, environmental parameters to it for HVAC requirement analysis.</td>
  </tr>
</table>
 
<table>
  <tr>
    <td class="text-column" width=1200></td>
  </tr>
</table>

<hr color="gray" size="10">

## Analyze Building HVAC Requirements Across Different Seasons, Geography.
<table>
  <tr>
    <td class="text-column" width=375>Evaluate the impact on energy consumption from operational parameters linked to time of the day. Example operational parameters include number of occupants at a given day and time, additional electrical loads, and switching on/off the HVAC system. Visualize your results in 3D.</td>
    <td class="text-column" width=25></td>
    <td class="image-column" width=400><img src="Overview/Images/requirementAnalysisCanvas.png" alt="Building Heat Load Analysis"></td>
    <td class="image-column" width=400><img src="Overview/Images/houseHeatLoadREADME.gif" alt="Building Heat Load Analysis"></td>
  </tr>
</table>
 
<table>
  <tr>
    <td class="text-column" width=1200></td>
  </tr>
</table>

<hr color="gray" size="10">

## Model Heat Pump, Detailed HVAC, and Building Energy Management System.
<table>
  <tr>
    <td class="image-column" width=400><img src="Overview/Images/buildingAnimationREADME.gif" alt="HVAC Requirement Analysis"></td>
    <td class="image-column" width=400><img src="Overview/Images/simulateBuildingEnergyMgmtModel.png" alt="Tune Controller"></td>
    <td class="text-column" width=25></td>
    <td class="text-column" width=375>Evaluate performance under loading conditions for the heat pumps. Design your controllers for physical conditions. Evaluate HVAC concepts such as a radiator and underfloor piping.</td>
  </tr>
</table>

<table>
  <tr>
    <td class="text-column" width=1200></td>
  </tr>
</table>
 
<hr color="gray" size="10">

## To Get Started 
* Clone the project repository.
* Open BuildingEnergyManagement.prj to get started with the project. 
* Requires MATLAB&reg; release R2025a or newer.
 

Copyright 2024 - 2025 The MathWorks, Inc.
