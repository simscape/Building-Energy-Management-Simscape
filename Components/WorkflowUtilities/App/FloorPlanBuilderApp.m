classdef FloorPlanBuilderApp < matlab.apps.AppBase
% FloorPlanBuilderApp - Interactive Building Floor Plan Designer
%
% This app provides a graphical interface for designing building floor
% plans by drawing, naming, and organizing rectangular rooms into
% apartments. The output is a MATLAB Live Script containing calls to
% addRoomToFloorPlan, defineSingleApartmentUnit, defineBuildingFloorPlan,
% and plotFloorPlanLayout.
%
% Workflow:
%   1. Select length units (meters or feet) - locked after first room
%   2. Draw rooms by clicking and dragging on the plot
%   3. Name each room using the Name field and Apply button
%   4. Optionally edit/resize rooms using the Edit button
%   5. Group current rooms into an apartment via Create Apt
%   6. Optionally flip an existing apartment to create a mirror copy
%   6b. Optionally copy/move/rotate an existing apartment
%   7. Repeat steps 2-6 for additional apartments
%   8. Specify output filename and click Save to generate Live Script
%
% The generated Live Script uses:
%   - addRoomToFloorPlan       : adds rooms to a floor plan struct
%   - defineSingleApartmentUnit: validates and creates apartment unit
%   - flipApartmentUnit        : mirrors apartment about an axis
%   - copyMoveRotateForNewApartment : copies apartment with move/rotation
%   - defineBuildingFloorPlan  : combines apartments into a floor plan
%   - plotFloorPlanLayout      : plots the complete floor plan
%
% Copyright 2024 - 2026 The MathWorks, Inc.

    %% UI Component Properties
    properties (Access = public)
        % Main window
        UIFigure            matlab.ui.Figure

        % Tab structure
        TabGroup            matlab.ui.container.TabGroup
        FloorPlanTab        matlab.ui.container.Tab

        % Layout containers
        GridLayout          matlab.ui.container.GridLayout
        LeftPanel           matlab.ui.container.Panel
        RightPanel          matlab.ui.container.Panel

        % Left panel controls - Unit selection
        InstructionsLabel   matlab.ui.control.Label
        UnitDropDown        matlab.ui.control.DropDown
        ResetAllButton      matlab.ui.control.Button

        % Left panel controls - Room naming
        NameLabel           matlab.ui.control.Label
        NameEditField       matlab.ui.control.EditField
        ApplyNameButton     matlab.ui.control.Button

        % Left panel controls - Room list
        RectangleListLabel  matlab.ui.control.Label
        RectangleListBox    matlab.ui.control.ListBox

        % Left panel controls - Room actions
        DeleteButton        matlab.ui.control.Button
        TolLabel            matlab.ui.control.Label
        TolField            matlab.ui.control.NumericEditField
        AdjustButton        matlab.ui.control.Button
        EditButton          matlab.ui.control.Button
        ConfirmEditButton   matlab.ui.control.Button
        CreateAptButton     matlab.ui.control.Button

        % Left panel controls - Flip apartment
        FlipInfoLabel       matlab.ui.control.Label
        FlipSourceDropDown  matlab.ui.control.DropDown
        FlipAxisDropDown    matlab.ui.control.DropDown
        FlipValueField      matlab.ui.control.NumericEditField
        FlipAptButton       matlab.ui.control.Button

        % Left panel controls - Copy/Move/Rotate apartment
        CMRInfoLabel        matlab.ui.control.Label
        CMRSourceDropDown   matlab.ui.control.DropDown
        CMRXOffsetField     matlab.ui.control.NumericEditField
        CMRYOffsetField     matlab.ui.control.NumericEditField
        CMRAngleField       matlab.ui.control.NumericEditField
        CMRRoomField        matlab.ui.control.EditField
        CMRButton           matlab.ui.control.Button

        % Left panel controls - Apartment list and actions
        ApartmentListLabel  matlab.ui.control.Label
        ApartmentListBox    matlab.ui.control.ListBox
        AdjustAptButton     matlab.ui.control.Button
        EditAptButton       matlab.ui.control.Button
        ConfirmAptButton    matlab.ui.control.Button
        DeleteAptButton     matlab.ui.control.Button

        % Left panel controls - Save
        SaveInfoLabel       matlab.ui.control.Label
        FilenameLabel       matlab.ui.control.Label
        FilenameEditField   matlab.ui.control.EditField
        SaveFloorPlanButton matlab.ui.control.Button

        % Right panel controls
        ZoomInButton        matlab.ui.control.Button
        ZoomOutButton       matlab.ui.control.Button
        ResetViewButton     matlab.ui.control.Button
        OutlineButton       matlab.ui.control.Button
        UIAxes              matlab.ui.control.UIAxes
    end

    %% Internal State Properties
    properties (Access = private)
        % Room data: struct array with fields VertexX, VertexY, Width,
        % Height, Rotation, Name.
        %   VertexX/VertexY : bottom-left corner coordinates (display units)
        %   Width           : X-extent (East-West direction)
        %   Height          : Y-extent (North-South direction)
        %   Rotation        : angle in degrees
        %   Name            : room identifier string
        Rectangles

        % Auto-incrementing counter for default room naming (Rect_1, etc.)
        RectCount

        % Auto-incrementing counter for apartment naming (Apartment1, etc.)
        AptCount

        % Cell array of apartment structs. Each cell contains:
        %   .name     - string, e.g. 'Apartment1'
        %   .unitStr  - 'm' or 'ft'
        %   .rooms    - struct array (same format as Rectangles)
        %   .flipData - [] for drawn apartments, or struct with:
        %               .sourceApt  (string: source apartment name)
        %               .axis       ('x' or 'y')
        %               .axisValue  (numeric, in display units)
        %   .cmrData  - [] for drawn apartments, or struct with:
        %               .sourceApt  (string: source apartment name)
        %               .xOffset, .yOffset (numeric, in display units)
        %               .rotAngle   (degrees)
        %               .rotRoom    (string: room name for rotation center)
        Apartments

        % True once units are locked (after first room is drawn)
        UnitsLocked

        % Drawing state
        IsDrawing           % True while user is dragging to draw a room
        DrawStart           % [x, y] starting point of current drag
        TempRect            % Handle to temporary patch during drawing

        % Room edit mode state
        IsEditing           % True while a room is being edited via ROI
        EditIndex           % Index into Rectangles of room being edited
        EditHandle          % images.roi.Rectangle handle
        EditLabels          % Array of text handles for dimension labels
        EditListener        % Listener for 'MovingROI' event
        AxesLimitsListener  % Listeners for XLim/YLim changes (grid update)

        % Apartment edit mode state
        IsEditingApt        % True while an apartment's rooms are being edited
        EditAptIndex        % Index into Apartments of the apartment being edited

        % Outline overlay state
        OutlineVisible      % True when merged outline is shown on the plot
        OutlineHandle       % Line handle for the outline overlay
    end

    %% ===================================================================
    %  UNIT UTILITIES
    %  ===================================================================
    methods (Access = private)

        function units = getDisplayUnitName(app)
            % getDisplayUnitName - Return human-readable unit name
            %   Returns 'meters' or 'feet' for axis labels and messages.
            if strcmp(app.UnitDropDown.Value, 'Meters')
                units = 'meters';
            else
                units = 'feet';
            end
        end

        function unitStr = getUnitCode(app)
            % getUnitCode - Return simscape.Value unit code
            %   Returns 'm' or 'ft' for use with simscape.Value().
            if strcmp(app.UnitDropDown.Value, 'Meters')
                unitStr = 'm';
            else
                unitStr = 'ft';
            end
        end

        function factor = getMetersToDisplayFactor(app)
            % getMetersToDisplayFactor - Conversion factor from meters to display units
            %   addRoomToFloorPlan stores geometry in meters internally.
            %   This factor converts those values back to the app's display units.
            if strcmp(app.getUnitCode(), 'ft')
                factor = 1 / 0.3048;
            else
                factor = 1;
            end
        end

    end

    %% ===================================================================
    %  LIST AND STATE MANAGEMENT
    %  ===================================================================
    methods (Access = private)

        function updateRectangleList(app)
            % updateRectangleList - Sync the room listbox with current Rectangles data
            %   Also enables/disables Adjust button based on room count.
            if isempty(app.Rectangles)
                app.RectangleListBox.Items = {};
                app.RectangleListBox.ItemsData = [];
                app.AdjustButton.Enable = 'off';
                app.TolLabel.Enable = 'off';
                app.TolField.Enable = 'off';
            else
                names = {app.Rectangles.Name};
                app.RectangleListBox.Items = names;
                app.RectangleListBox.ItemsData = 1:numel(names);
                if numel(app.Rectangles) >= 2
                    app.AdjustButton.Enable = 'on';
                    app.TolLabel.Enable = 'on';
                    app.TolField.Enable = 'on';
                else
                    app.AdjustButton.Enable = 'off';
                    app.TolLabel.Enable = 'off';
                    app.TolField.Enable = 'off';
                end
            end
        end

        function updateApartmentList(app)
            % updateApartmentList - Sync apartment listbox, flip, and CMR source dropdowns
            %   Also shows/hides the Adjust Apt button (requires 2+ apartments).
            if isempty(app.Apartments)
                app.ApartmentListBox.Items = {};
                app.ApartmentListBox.ItemsData = [];
                app.FlipSourceDropDown.Items = {};
                app.FlipAptButton.Enable = 'off';
                app.CMRSourceDropDown.Items = {};
                app.CMRButton.Enable = 'off';
                app.AdjustAptButton.Visible = 'off';
                app.OutlineButton.Enable = 'off';
                app.OutlineVisible = false;
            else
                names = cellfun(@(a) a.name, app.Apartments, 'UniformOutput', false);
                app.ApartmentListBox.Items = names;
                app.ApartmentListBox.ItemsData = 1:numel(names);
                app.FlipSourceDropDown.Items = names;
                app.FlipAptButton.Enable = 'on';
                app.CMRSourceDropDown.Items = names;
                app.CMRButton.Enable = 'on';
                app.OutlineButton.Enable = 'on';
                if numel(app.Apartments) >= 2
                    app.AdjustAptButton.Visible = 'on';
                else
                    app.AdjustAptButton.Visible = 'off';
                end
            end
        end

        function idx = getSelectedRoomIndex(app)
            % getSelectedRoomIndex - Return the currently selected room index, or []
            idx = app.RectangleListBox.Value;
            if isempty(idx)
                idx = [];
            end
        end

        function setControlsEnabled(app, state)
            % setControlsEnabled - Enable/disable controls during room ROI edit mode
            %   state: 'on' or 'off'
            %   The unit dropdown stays disabled if units are already locked.
            %   ConfirmEdit and ConfirmApt buttons are NOT affected (managed separately).
            app.ApplyNameButton.Enable = state;
            app.DeleteButton.Enable = state;
            app.NameEditField.Enable = state;
            app.RectangleListBox.Enable = state;
            app.CreateAptButton.Enable = state;
            if strcmp(state, 'on') && numel(app.Rectangles) >= 2
                app.AdjustButton.Enable = 'on';
                app.TolLabel.Enable = 'on';
                app.TolField.Enable = 'on';
            else
                app.AdjustButton.Enable = state;
                app.TolLabel.Enable = state;
                app.TolField.Enable = state;
            end
            app.ApartmentListBox.Enable = state;
            app.EditAptButton.Enable = state;
            app.DeleteAptButton.Enable = state;
            app.FlipSourceDropDown.Enable = state;
            app.FlipAxisDropDown.Enable = state;
            app.FlipValueField.Enable = state;
            app.CMRSourceDropDown.Enable = state;
            app.CMRXOffsetField.Enable = state;
            app.CMRYOffsetField.Enable = state;
            app.CMRAngleField.Enable = state;
            app.CMRRoomField.Enable = state;
            app.FilenameEditField.Enable = state;
            app.SaveFloorPlanButton.Enable = state;
            app.ZoomInButton.Enable = state;
            app.ZoomOutButton.Enable = state;
            app.ResetViewButton.Enable = state;
            app.ResetAllButton.Enable = state;
            if strcmp(state, 'on') && ~isempty(app.Apartments)
                app.OutlineButton.Enable = 'on';
            else
                app.OutlineButton.Enable = state;
            end
            if ~app.UnitsLocked
                app.UnitDropDown.Enable = state;
            end
            if ~isempty(app.Apartments)
                app.FlipAptButton.Enable = state;
                app.CMRButton.Enable = state;
            end
        end

        function clearCurrentRooms(app)
            % clearCurrentRooms - Clear active rooms and refresh plot
            %   Apartment rooms remain visible. Used after creating an apartment.
            app.Rectangles = [];
            app.RectCount = 0;
            app.updateRectangleList();
            app.NameEditField.Value = '';
            app.drawAllRectangles();
            app.fitViewToContent();
        end

        function setAptEditModeControls(app, state)
            % setAptEditModeControls - Enable or disable apartment-level controls
            %   Used when entering/exiting apartment edit mode. Controls that
            %   belong to the apartment-level workflow are disabled while the
            %   user is editing individual rooms within an apartment.
            %   state: 'on' or 'off'
            app.CreateAptButton.Enable = state;
            app.DeleteAptButton.Enable = state;
            app.ApartmentListBox.Enable = state;
            app.FlipSourceDropDown.Enable = state;
            app.FlipAxisDropDown.Enable = state;
            app.FlipValueField.Enable = state;
            app.CMRSourceDropDown.Enable = state;
            app.CMRXOffsetField.Enable = state;
            app.CMRYOffsetField.Enable = state;
            app.CMRAngleField.Enable = state;
            app.CMRRoomField.Enable = state;
            app.FilenameEditField.Enable = state;
            app.SaveFloorPlanButton.Enable = state;
            app.ResetAllButton.Enable = state;

            if strcmp(state, 'on')
                % Restore conditional enables
                if ~isempty(app.Apartments)
                    app.FlipAptButton.Enable = 'on';
                    app.CMRButton.Enable = 'on';
                else
                    app.FlipAptButton.Enable = 'off';
                    app.CMRButton.Enable = 'off';
                end
                if numel(app.Apartments) >= 2
                    app.AdjustAptButton.Visible = 'on';
                else
                    app.AdjustAptButton.Visible = 'off';
                end
                if ~isempty(strtrim(app.FilenameEditField.Value))
                    app.SaveFloorPlanButton.Enable = 'on';
                else
                    app.SaveFloorPlanButton.Enable = 'off';
                end
            else
                app.FlipAptButton.Enable = 'off';
                app.CMRButton.Enable = 'off';
                app.AdjustAptButton.Visible = 'off';
            end
        end

    end

    %% ===================================================================
    %  GEOMETRY AND PLOTTING UTILITIES
    %  ===================================================================
    methods (Access = private)

        function overlap = hasOverlappingRooms(app)
            % hasOverlappingRooms - Check if active rooms overlap each other
            %   or overlap rooms from existing apartments.
            %   Wrapper around roomsOverlapExisting using app.Rectangles.
            overlap = app.roomsOverlapExisting(app.Rectangles);
        end

        function overlap = roomsOverlapExisting(app, rooms, skipAptIdx, skipSelfCheck)
            % roomsOverlapExisting - Check if given rooms overlap each other
            %   or any rooms from existing apartments.
            %   Returns true if any pair has a non-negligible intersection
            %   area (> 1e-6).
            %
            %   Input:
            %     rooms         - struct array in app format
            %     skipAptIdx    - apartment index to skip, or [] for none
            %                     (used when editing an apartment)
            %     skipSelfCheck - (optional) logical, default false. When true,
            %                     skips internal overlap check among the given
            %                     rooms. Use this when rooms were already validated
            %                     by defineSingleApartmentUnit (rounding during
            %                     extraction can introduce sub-pixel overlaps
            %                     between touching rooms).
            if nargin < 3
                if app.IsEditingApt
                    skipAptIdx = app.EditAptIndex;
                else
                    skipAptIdx = [];
                end
            end
            if nargin < 4
                skipSelfCheck = false;
            end

            overlap = false;
            if isempty(rooms)
                return;
            end

            roomStructs = app.buildRoomStructs(rooms);

            % Check rooms against each other (unless skipped)
            if ~skipSelfCheck
                for j = 1:numel(roomStructs)-1
                    for k = j+1:numel(roomStructs)
                        intPoly = intersect(roomStructs(j).floorPlan, roomStructs(k).floorPlan);
                        if intPoly.area > 1e-6
                            overlap = true;
                            return;
                        end
                    end
                end
            end

            % Check rooms against all saved apartment rooms
            for a = 1:numel(app.Apartments)
                if ~isempty(skipAptIdx) && a == skipAptIdx
                    continue;
                end
                aptRoomStructs = app.buildRoomStructs(app.Apartments{a}.rooms);
                for j = 1:numel(roomStructs)
                    for k = 1:numel(aptRoomStructs)
                        intPoly = intersect(roomStructs(j).floorPlan, aptRoomStructs(k).floorPlan);
                        if intPoly.area > 1e-6
                            overlap = true;
                            return;
                        end
                    end
                end
            end
        end

        function corners = getRotatedCorners(~, r)
            % getRotatedCorners - Compute 4 corners of a rotated rectangle
            %   Rotation is about the vertex (bottom-left corner), matching
            %   the construction in addNewRoomToFloorPlan.
            %   Input:  r - struct with VertexX, VertexY, Width, Height, Rotation
            %   Output: 2x4 matrix [x1 x2 x3 x4; y1 y2 y3 y4]
            %           Order: bottom-left, bottom-right, top-right, top-left

            % Local corners relative to vertex (before rotation)
            localX = [0, r.Width, r.Width, 0];
            localY = [0, 0, r.Height, r.Height];

            % Rotate about vertex
            theta = deg2rad(r.Rotation);
            R = [cos(theta), -sin(theta); sin(theta), cos(theta)];
            pts = R * [localX; localY];

            % Translate to absolute position
            corners = pts + [r.VertexX; r.VertexY];
        end

        function roomStructs = buildRoomStructs(~, rooms)
            % buildRoomStructs - Convert app room data to polyshape structs
            %   Calls addNewRoomToFloorPlan to create structs with .floorPlan
            %   (polyshape), .name, .geometry fields. This is the same
            %   representation that plotFloorPlanLayout renders.
            %
            %   Values are passed in the app's display units directly (no
            %   simscape.Value conversion) so polyshape coordinates match
            %   the axes display.
            %
            %   Input:  rooms - struct array (app format: VertexX, VertexY,
            %           Width, Height, Rotation, Name)
            %   Output: roomStructs - struct array with .floorPlan polyshape
            roomStructs = [];
            for i = 1:numel(rooms)
                r = rooms(i);
                roomModel = addNewRoomToFloorPlan( ...
                    [r.VertexX, r.VertexY], r.Width, r.Height, r.Rotation, r.Name);
                roomStructs = [roomStructs, roomModel]; %#ok<AGROW>
            end
        end

        function aptStruct = buildSimscapeApartment(app, rooms)
            % buildSimscapeApartment - Build a validated apartment struct via
            %   addRoomToFloorPlan + defineSingleApartmentUnit.
            %   Used for flip operations that require the full Simscape pipeline.
            %
            %   Input:  rooms - struct array (app format)
            %   Output: aptStruct - apartment struct from defineSingleApartmentUnit,
            %           or [] if rooms overlap
            unitStr = app.getUnitCode();
            floorPlan = [];
            for i = 1:numel(rooms)
                r = rooms(i);
                floorPlan = addRoomToFloorPlan(FloorPlan=floorPlan, ...
                    NewRoom=r.Name, ...
                    Vertex=simscape.Value([r.VertexX, r.VertexY], unitStr), ...
                    Length=simscape.Value(r.Height, unitStr), ...
                    Width=simscape.Value(r.Width, unitStr), ...
                    Angle=simscape.Value(r.Rotation, "deg"));
            end
            aptStruct = defineSingleApartmentUnit(Apartment=floorPlan, Tol=0.01);
        end

        function rooms = extractRoomsFromStruct(app, aptStruct)
            % extractRoomsFromStruct - Convert apartment struct back to app format
            %   The internal struct stores geometry in meters (due to
            %   addRoomToFloorPlan's conversion). This method converts
            %   values back to the app's display units.
            %
            %   Rounding: axis-aligned rooms (theta ~ 0 mod 90) use 1 decimal
            %   place for clean display. Rotated rooms use 12 decimal places to
            %   preserve geometric precision (especially contact adjustments)
            %   and avoid false overlaps when touching rooms are reconstructed
            %   as polyshapes.
            %
            %   Input:  aptStruct - struct from defineSingleApartmentUnit or
            %           flipApartmentUnit (fields: room1, room2, ...)
            %   Output: rooms - struct array in app format
            factor = app.getMetersToDisplayFactor();
            numRooms = numel(fieldnames(aptStruct));
            rooms = [];
            for i = 1:numRooms
                roomField = aptStruct.("room" + num2str(i));
                theta = roomField.geometry.dim.theta;

                % Use higher precision for rotated rooms to preserve contact
                if abs(mod(theta, 90)) < 1e-6
                    nDec = 1;
                else
                    nDec = 12;
                end

                newRect.Name = char(roomField.name);
                newRect.VertexX = round(roomField.geometry.dim.vertex(1) * factor, nDec);
                newRect.VertexY = round(roomField.geometry.dim.vertex(2) * factor, nDec);
                newRect.Width = round(roomField.geometry.dim.width * factor, nDec);
                newRect.Height = round(roomField.geometry.dim.length * factor, nDec);
                newRect.Rotation = round(theta, nDec);
                if isempty(rooms)
                    rooms = newRect;
                else
                    rooms(end+1) = newRect; %#ok<AGROW>
                end
            end
        end

    end

    %% ===================================================================
    %  PLOT RENDERING
    %  ===================================================================
    methods (Access = private)

        function drawAllRectangles(app)
            % drawAllRectangles - Redraw all rooms on the axes
            %   Uses polyshape-based rendering (consistent with plotFloorPlanLayout).
            %   Apartment rooms are drawn as dashed background; active rooms
            %   as solid foreground. The room under ROI edit is skipped.
            %   If the building outline toggle is active, redraws the outline.
            cla(app.UIAxes);
            hold(app.UIAxes, 'on');

            app.updateAxesLabels();
            app.plotApartmentRooms();
            app.plotActiveRooms();
            app.drawBuildingOutline();

            hold(app.UIAxes, 'off');
            app.configureGrid();
        end

        function updateAxesLabels(app)
            % updateAxesLabels - Set compass-style axis labels with units
            units = app.getDisplayUnitName();
            app.UIAxes.XLabel.String = ['\leftarrow West     (' units ')     East \rightarrow'];
            app.UIAxes.YLabel.String = ['\leftarrow South     (' units ')     North \rightarrow'];
            app.UIAxes.XLabel.FontSize = 20;
            app.UIAxes.YLabel.FontSize = 20;
        end

        function plotApartmentRooms(app)
            % plotApartmentRooms - Render all saved apartment rooms (background)
            %   Each apartment gets a unique color from a cycling palette.
            %   Rooms are drawn with dashed edges and low opacity.
            if isempty(app.Apartments)
                return;
            end

            palette = [0.6 0.6 0.6; ...
                       0.7 0.5 0.5; ...
                       0.5 0.7 0.5; ...
                       0.5 0.5 0.7; ...
                       0.7 0.7 0.5; ...
                       0.5 0.7 0.7; ...
                       0.7 0.5 0.7];

            for a = 1:numel(app.Apartments)
                % Skip the apartment currently being edited (its rooms are active)
                if app.IsEditingApt && a == app.EditAptIndex
                    continue;
                end

                apt = app.Apartments{a};
                roomStructs = app.buildRoomStructs(apt.rooms);
                cIdx = mod(a - 1, size(palette, 1)) + 1;
                faceColor = palette(cIdx, :);
                edgeColor = palette(cIdx, :) * 0.6;

                for i = 1:numel(roomStructs)
                    plot(app.UIAxes, roomStructs(i).floorPlan, ...
                        'FaceColor', faceColor, 'FaceAlpha', 0.15, ...
                        'EdgeColor', edgeColor, 'LineWidth', 1, ...
                        'LineStyle', '--');
                    [x, y] = centroid(roomStructs(i).floorPlan);
                    text(app.UIAxes, x, y, sprintf('%s\n%s', apt.name, roomStructs(i).name), ...
                        'HorizontalAlignment', 'center', ...
                        'FontSize', 8, 'Color', edgeColor, ...
                        'FontAngle', 'italic');
                end
            end
        end

        function plotActiveRooms(app)
            % plotActiveRooms - Render current (unsaved) rooms in the foreground
            %   Rooms are drawn solid with name labels and dimension annotations.
            %   The room under ROI edit is skipped.
            if isempty(app.Rectangles)
                return;
            end

            roomStructs = app.buildRoomStructs(app.Rectangles);
            for i = 1:numel(roomStructs)
                if app.IsEditing && i == app.EditIndex
                    continue;
                end

                plot(app.UIAxes, roomStructs(i).floorPlan, ...
                    'FaceColor', [0.3 0.6 0.9], 'FaceAlpha', 0.3, ...
                    'EdgeColor', [0 0.2 0.7], 'LineWidth', 1.5);
                [x, y] = centroid(roomStructs(i).floorPlan);
                text(app.UIAxes, x, y, roomStructs(i).name, ...
                    'HorizontalAlignment', 'center', ...
                    'FontWeight', 'bold', 'FontSize', 10);

                % Dimension annotations (vertex, width, height)
                corners = app.getRotatedCorners(app.Rectangles(i));
                app.drawDimensionLabels(app.Rectangles(i), corners);
            end
        end

        function drawBuildingOutline(app)
            % drawBuildingOutline - Overlay merged building outline if toggle is active
            %   Computes the union of all apartment room polyshapes and plots
            %   the outer boundary as a dotted black line (5 px width).
            %   Handles multi-region unions (NaN-separated vertex lists).
            %   Does nothing if OutlineVisible is false or no apartments exist.
            app.OutlineHandle = [];

            if ~app.OutlineVisible || isempty(app.Apartments)
                return;
            end

            % Collect all apartment room polyshapes into a single union
            mergedPoly = polyshape();
            for a = 1:numel(app.Apartments)
                apt = app.Apartments{a};
                roomStructs = app.buildRoomStructs(apt.rooms);
                for ri = 1:numel(roomStructs)
                    mergedPoly = union(mergedPoly, roomStructs(ri).floorPlan);
                end
            end

            if mergedPoly.NumRegions == 0
                return;
            end

            % Extract vertices (NaN-separated for multi-region polyshapes)
            % and close each region loop for proper line rendering
            verts = mergedPoly.Vertices;
            xv = verts(:,1);
            yv = verts(:,2);

            % Close each NaN-separated segment by appending its first point
            nanIdx = find(isnan(xv));
            segments = [0; nanIdx; numel(xv)+1];
            xClosed = [];
            yClosed = [];
            for s = 1:numel(segments)-1
                startIdx = segments(s) + 1;
                endIdx   = segments(s+1) - 1;
                if startIdx > endIdx
                    continue;
                end
                seg_x = xv(startIdx:endIdx);
                seg_y = yv(startIdx:endIdx);
                % Close the loop
                xClosed = [xClosed; seg_x; seg_x(1); NaN]; %#ok<AGROW>
                yClosed = [yClosed; seg_y; seg_y(1); NaN]; %#ok<AGROW>
            end

            app.OutlineHandle = plot(app.UIAxes, xClosed, yClosed, ...
                'Color', 'k', 'LineStyle', ':', 'LineWidth', 5);
        end

        function drawDimensionLabels(app, r, corners)
            % drawDimensionLabels - Annotate a room with vertex and dimension text
            %   - Bottom-left vertex coordinates (black, bold)
            %   - Width value along bottom edge (red)
            %   - Height value along left edge (green)

            % Vertex coordinates at bottom-left corner
            text(app.UIAxes, corners(1,1), corners(2,1), ...
                sprintf('(%.1f, %.1f)', corners(1,1), corners(2,1)), ...
                'HorizontalAlignment', 'right', ...
                'VerticalAlignment', 'top', ...
                'FontSize', 9, 'Color', [0 0 0], 'FontWeight', 'bold');

            % Width label at midpoint of bottom edge
            mx = (corners(1,1) + corners(1,2)) / 2;
            my = (corners(2,1) + corners(2,2)) / 2;
            text(app.UIAxes, mx, my, sprintf('%.1f', r.Width), ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'top', ...
                'FontSize', 9, 'Color', [0.8 0 0]);

            % Height label at midpoint of left edge
            mx2 = (corners(1,1) + corners(1,4)) / 2;
            my2 = (corners(2,1) + corners(2,4)) / 2;
            text(app.UIAxes, mx2, my2, sprintf('%.1f', r.Height), ...
                'HorizontalAlignment', 'right', ...
                'VerticalAlignment', 'middle', ...
                'FontSize', 9, 'Color', [0 0.6 0]);
        end

        function updateEditLabels(app)
            % updateEditLabels - Refresh dimension labels during interactive ROI edit
            %   Called by the MovingROI listener to keep annotations
            %   synchronized with the rectangle position and size.

            % Remove previous labels
            if ~isempty(app.EditLabels)
                delete(app.EditLabels(isvalid(app.EditLabels)));
                app.EditLabels = [];
            end

            if isempty(app.EditHandle) || ~isvalid(app.EditHandle)
                return;
            end

            % Build a temporary room struct from ROI state
            pos = app.EditHandle.Position;
            tempRoom.VertexX = pos(1);
            tempRoom.VertexY = pos(2);
            tempRoom.Width = pos(3);
            tempRoom.Height = pos(4);
            tempRoom.Rotation = app.EditHandle.RotationAngle;

            corners = app.getRotatedCorners(tempRoom);

            % Vertex label
            blX = round(corners(1,1), 1);
            blY = round(corners(2,1), 1);
            t1 = text(app.UIAxes, corners(1,1), corners(2,1), ...
                sprintf('(%.1f, %.1f)', blX, blY), ...
                'HorizontalAlignment', 'right', ...
                'VerticalAlignment', 'top', ...
                'FontSize', 9, 'Color', [0 0 0], 'FontWeight', 'bold');

            % Width label
            mx = (corners(1,1) + corners(1,2)) / 2;
            my = (corners(2,1) + corners(2,2)) / 2;
            t2 = text(app.UIAxes, mx, my, sprintf('%.1f', round(pos(3), 1)), ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'top', ...
                'FontSize', 9, 'Color', [0.8 0 0]);

            % Height label
            mx2 = (corners(1,1) + corners(1,4)) / 2;
            my2 = (corners(2,1) + corners(2,4)) / 2;
            t3 = text(app.UIAxes, mx2, my2, sprintf('%.1f', round(pos(4), 1)), ...
                'HorizontalAlignment', 'right', ...
                'VerticalAlignment', 'middle', ...
                'FontSize', 9, 'Color', [0 0.6 0]);

            app.EditLabels = [t1, t2, t3];
        end

        function configureGrid(app)
            % configureGrid - Configure major and minor grid lines
            %   Major grid at every 10 units, minor at every 2 units.
            %   Called automatically via AxesLimitsListener whenever the
            %   axes limits change (pan, zoom, draw, reset view).
            grid(app.UIAxes, 'on');
            app.UIAxes.XMinorGrid = 'on';
            app.UIAxes.YMinorGrid = 'on';

            % Current visible range
            xLim = app.UIAxes.XLim;
            yLim = app.UIAxes.YLim;

            % Major ticks at 10-unit intervals, covering visible range
            xStart = floor(xLim(1) / 10) * 10;
            xEnd   = ceil(xLim(2) / 10) * 10;
            yStart = floor(yLim(1) / 10) * 10;
            yEnd   = ceil(yLim(2) / 10) * 10;

            app.UIAxes.XTick = xStart : 10 : xEnd;
            app.UIAxes.YTick = yStart : 10 : yEnd;

            % Minor ticks at 2-unit intervals
            app.UIAxes.XAxis.MinorTickValues = floor(xLim(1)/2)*2 : 2 : ceil(xLim(2)/2)*2;
            app.UIAxes.YAxis.MinorTickValues = floor(yLim(1)/2)*2 : 2 : ceil(yLim(2)/2)*2;

            % Grid appearance
            app.UIAxes.GridAlpha = 0.3;
            app.UIAxes.MinorGridAlpha = 0.15;
            app.UIAxes.MinorGridLineStyle = ':';
        end

        function fitViewToContent(app)
            % fitViewToContent - Adjust axes limits to fit all visible rooms
            %   Includes both active rooms and apartment rooms with 10% padding.
            allX = [];
            allY = [];

            for i = 1:numel(app.Rectangles)
                corners = app.getRotatedCorners(app.Rectangles(i));
                allX = [allX, corners(1,:)]; %#ok<AGROW>
                allY = [allY, corners(2,:)]; %#ok<AGROW>
            end

            for a = 1:numel(app.Apartments)
                for i = 1:numel(app.Apartments{a}.rooms)
                    corners = app.getRotatedCorners(app.Apartments{a}.rooms(i));
                    allX = [allX, corners(1,:)]; %#ok<AGROW>
                    allY = [allY, corners(2,:)]; %#ok<AGROW>
                end
            end

            if isempty(allX)
                app.UIAxes.XLim = [0 100];
                app.UIAxes.YLim = [0 100];
            else
                xPad = max(0.1 * (max(allX) - min(allX)), 1);
                yPad = max(0.1 * (max(allY) - min(allY)), 1);
                app.UIAxes.XLim = [min(allX) - xPad, max(allX) + xPad];
                app.UIAxes.YLim = [min(allY) - yPad, max(allY) + yPad];
            end
            app.configureGrid();
        end

    end

    %% ===================================================================
    %  CODE GENERATION
    %  ===================================================================
    methods (Access = private)

        function codeLines = generateFloorPlanCode(app)
            % generateFloorPlanCode - Build MATLAB code for all apartments
            %   Generates a cell array of code lines that define each apartment
            %   using addRoomToFloorPlan/flipApartmentUnit, assemble them into
            %   a floor plan, and plot the result.
            codeLines = {};
            codeLines{end+1} = '%% Floor Plan - Auto-generated by FloorPlanBuilderApp';
            codeLines{end+1} = '';

            % Generate code for each apartment
            aptNames = cellfun(@(a) a.name, app.Apartments, 'UniformOutput', false);
            for a = 1:numel(app.Apartments)
                apt = app.Apartments{a};
                unitStr = apt.unitStr;
                codeLines{end+1} = sprintf('%%%% %s', apt.name); %#ok<AGROW>

                if isfield(apt, 'flipData') && ~isempty(apt.flipData) ...
                        && app.sourceExistsInList(apt.flipData.sourceApt, aptNames, a)
                    codeLines = app.generateFlipCode(codeLines, apt, unitStr);
                elseif isfield(apt, 'cmrData') && ~isempty(apt.cmrData) ...
                        && app.sourceExistsInList(apt.cmrData.sourceApt, aptNames, a)
                    codeLines = app.generateCMRCode(codeLines, apt, unitStr);
                else
                    codeLines = app.generateDrawnAptCode(codeLines, apt, a, unitStr);
                end
                codeLines{end+1} = ''; %#ok<AGROW>
            end

            % Floor plan assembly
            codeLines{end+1} = '%% Create Building Floor Plan';
            aptVarNames = cellfun(@(a) lower(a.name), app.Apartments, 'UniformOutput', false);
            codeLines{end+1} = sprintf('buildingFloorPlan = defineBuildingFloorPlan(Apartments={%s});', ...
                strjoin(aptVarNames, ', '));
            codeLines{end+1} = '';

            % Plot
            codeLines{end+1} = '%% Plot Floor Plan';
            codeLines{end+1} = 'figure;';
            codeLines{end+1} = 'plotFloorPlanLayout(PlotData=buildingFloorPlan, Type="floorplan");';
            codeLines{end+1} = '';
        end

        function codeLines = generateFlipCode(~, codeLines, apt, unitStr)
            % generateFlipCode - Generate flipApartmentUnit call for a flipped apartment
            fd = apt.flipData;
            codeLines{end+1} = sprintf('%s = flipApartmentUnit(Apartment=%s, ...', ...
                lower(apt.name), lower(fd.sourceApt));
            codeLines{end+1} = sprintf('    Axis="%s", ...', fd.axis);
            codeLines{end+1} = sprintf('    AxisValue=simscape.Value(%.1f, "%s"), ...', ...
                fd.axisValue, unitStr);
            codeLines{end+1} = '    Tol=0.01);';
        end

        function codeLines = generateCMRCode(~, codeLines, apt, unitStr)
            % generateCMRCode - Generate copyMoveRotateForNewApartment call
            cd = apt.cmrData;
            codeLines{end+1} = sprintf('%s = copyMoveRotateForNewApartment(Apartment=%s, ...', ...
                lower(apt.name), lower(cd.sourceApt));
            codeLines{end+1} = sprintf('    MoveDistance=simscape.Value([%.1f, %.1f], "%s"), ...', ...
                cd.xOffset, cd.yOffset, unitStr);
            codeLines{end+1} = sprintf('    RotationAngle=simscape.Value(%.1f, "deg"), ...', ...
                cd.rotAngle);
            if cd.rotAngle ~= 0 && ~isempty(cd.rotRoom)
                codeLines{end+1} = sprintf('    RotateAboutRoom="%s", ...', cd.rotRoom);
            else
                codeLines{end+1} = sprintf('    RotateAboutRoom="", ...');
            end
            codeLines{end+1} = '    Tol=0.01);';
        end

        function codeLines = generateDrawnAptCode(~, codeLines, apt, aptIdx, unitStr)
            % generateDrawnAptCode - Generate addRoomToFloorPlan calls for a drawn apartment
            rooms = apt.rooms;
            codeLines{end+1} = sprintf('oneAptUnit%d = [];', aptIdx);
            codeLines{end+1} = '';

            for i = 1:numel(rooms)
                r = rooms(i);
                codeLines{end+1} = sprintf('%% %s', r.Name); %#ok<AGROW>
                codeLines{end+1} = sprintf('oneAptUnit%d = addRoomToFloorPlan(FloorPlan=oneAptUnit%d, ...', aptIdx, aptIdx); %#ok<AGROW>
                codeLines{end+1} = sprintf('    NewRoom="%s", ...', r.Name); %#ok<AGROW>
                codeLines{end+1} = sprintf('    Vertex=simscape.Value([%.1f, %.1f], "%s"), ...', ...
                    r.VertexX, r.VertexY, unitStr); %#ok<AGROW>
                codeLines{end+1} = sprintf('    Length=simscape.Value(%.1f, "%s"), ...', r.Height, unitStr); %#ok<AGROW>
                codeLines{end+1} = sprintf('    Width=simscape.Value(%.1f, "%s"), ...', r.Width, unitStr); %#ok<AGROW>
                codeLines{end+1} = sprintf('    Angle=simscape.Value(%.1f, "deg"), ...', r.Rotation); %#ok<AGROW>
                codeLines{end+1} = '    Plot=true);'; %#ok<AGROW>
                codeLines{end+1} = ''; %#ok<AGROW>
            end

            codeLines{end+1} = sprintf('%s = defineSingleApartmentUnit(Apartment=oneAptUnit%d, ...', ...
                lower(apt.name), aptIdx);
            codeLines{end+1} = '    Tol=0.01);';
        end

        function exists = sourceExistsInList(~, sourceName, aptNames, currentIdx)
            % sourceExistsInList - Check if a source apartment exists and is
            %   defined before the current apartment in the code output.
            %   Returns true only if sourceName appears in aptNames at an
            %   index strictly less than currentIdx (i.e., it will already
            %   be defined in the generated script by the time it is referenced).
            exists = false;
            for i = 1:currentIdx-1
                if strcmp(aptNames{i}, sourceName)
                    exists = true;
                    return;
                end
            end
        end

    end

    %% ===================================================================
    %  CALLBACKS - Drawing
    %  ===================================================================
    methods (Access = private)

        function startupFcn(app)
            % startupFcn - Initialize state and configure axes on app launch
            app.Rectangles = [];
            app.RectCount = 0;
            app.AptCount = 0;
            app.Apartments = {};
            app.UnitsLocked = false;
            app.IsDrawing = false;
            app.TempRect = [];
            app.IsEditing = false;
            app.EditIndex = [];
            app.EditHandle = [];
            app.EditLabels = [];
            app.EditListener = [];
            app.IsEditingApt = false;
            app.EditAptIndex = [];
            app.OutlineVisible = false;
            app.OutlineHandle = [];

            app.UIAxes.XLim = [0 100];
            app.UIAxes.YLim = [0 100];
            axis(app.UIAxes, 'equal');
            app.updateAxesLabels();
            app.configureGrid();
        end

        function axesButtonDown(app, ~, ~)
            % axesButtonDown - Begin drawing a new room on mouse click
            if app.IsEditing
                return;
            end
            pt = app.UIAxes.CurrentPoint(1, 1:2);
            app.IsDrawing = true;
            app.DrawStart = pt;

            hold(app.UIAxes, 'on');
            app.TempRect = patch(app.UIAxes, pt(1), pt(2), ...
                [0.9 0.9 0.2], 'FaceAlpha', 0.2, ...
                'EdgeColor', [0.8 0.5 0], 'LineWidth', 1, ...
                'LineStyle', '--');
            hold(app.UIAxes, 'off');
        end

        function figureMouseMove(app, ~, ~)
            % figureMouseMove - Update temporary rectangle shape during drag
            if ~app.IsDrawing || isempty(app.TempRect)
                return;
            end

            pt = app.UIAxes.CurrentPoint(1, 1:2);
            x1 = app.DrawStart(1); y1 = app.DrawStart(2);
            x2 = pt(1); y2 = pt(2);

            xv = [min(x1,x2), max(x1,x2), max(x1,x2), min(x1,x2)];
            yv = [min(y1,y2), min(y1,y2), max(y1,y2), max(y1,y2)];

            if isvalid(app.TempRect)
                app.TempRect.XData = xv;
                app.TempRect.YData = yv;
            end
        end

        function figureMouseUp(app, ~, ~)
            % figureMouseUp - Finalize the drawn rectangle on mouse release
            if ~app.IsDrawing
                return;
            end
            app.IsDrawing = false;

            pt = app.UIAxes.CurrentPoint(1, 1:2);
            x1 = app.DrawStart(1); y1 = app.DrawStart(2);
            x2 = pt(1); y2 = pt(2);

            w = abs(x2 - x1);
            h = abs(y2 - y1);

            % Remove temporary rectangle
            if ~isempty(app.TempRect) && isvalid(app.TempRect)
                delete(app.TempRect);
                app.TempRect = [];
            end

            % Reject tiny rectangles (likely accidental clicks)
            if w < 0.5 || h < 0.5
                return;
            end

            % Create room struct (rounded to 1 decimal place)
            app.RectCount = app.RectCount + 1;
            newRect.Name = sprintf('Rect_%d', app.RectCount);
            newRect.VertexX = round(min(x1, x2), 1);
            newRect.VertexY = round(min(y1, y2), 1);
            newRect.Width = round(w, 1);
            newRect.Height = round(h, 1);
            newRect.Rotation = 0;

            if isempty(app.Rectangles)
                app.Rectangles = newRect;
            else
                app.Rectangles(end+1) = newRect;
            end

            % Lock units after the first room is drawn
            if ~app.UnitsLocked
                app.UnitsLocked = true;
                app.UnitDropDown.Enable = 'off';
            end

            app.updateRectangleList();
            app.RectangleListBox.Value = numel(app.Rectangles);
            app.NameEditField.Value = newRect.Name;
            app.drawAllRectangles();
        end

    end

    %% ===================================================================
    %  CALLBACKS - Room Management
    %  ===================================================================
    methods (Access = private)

        function listBoxValueChanged(app, ~, ~)
            % listBoxValueChanged - Show selected room's name in the edit field
            idx = app.getSelectedRoomIndex();
            if ~isempty(idx) && idx <= numel(app.Rectangles)
                app.NameEditField.Value = app.Rectangles(idx).Name;
            end
        end

        function applyNameButtonPushed(app, ~, ~)
            % applyNameButtonPushed - Rename the selected room
            idx = app.getSelectedRoomIndex();
            if isempty(idx) || idx > numel(app.Rectangles)
                errordlg('Select a room first.', 'No Selection', 'modal');
                return;
            end

            newName = strtrim(app.NameEditField.Value);
            if isempty(newName)
                errordlg('Name cannot be empty.', 'Invalid Name', 'modal');
                return;
            end

            app.Rectangles(idx).Name = newName;
            app.updateRectangleList();
            app.RectangleListBox.Value = idx;
            app.drawAllRectangles();
        end

        function deleteButtonPushed(app, ~, ~)
            % deleteButtonPushed - Remove the selected room from the list
            idx = app.getSelectedRoomIndex();
            if isempty(idx) || idx > numel(app.Rectangles)
                errordlg('Select a room first.', 'No Selection', 'modal');
                return;
            end

            app.Rectangles(idx) = [];
            app.updateRectangleList();

            if ~isempty(app.Rectangles)
                app.RectangleListBox.Value = 1;
                app.NameEditField.Value = app.Rectangles(1).Name;
            else
                app.NameEditField.Value = '';
            end
            app.drawAllRectangles();
        end

    end

    %% ===================================================================
    %  CALLBACKS - Edit Mode
    %  ===================================================================
    methods (Access = private)

        function editButtonPushed(app, ~, ~)
            % editButtonPushed - Enter interactive edit mode for the selected room
            %   Creates a draggable/resizable ROI rectangle. Other controls
            %   are disabled until the user confirms the edit.
            try
                idx = app.getSelectedRoomIndex();
                if isempty(idx) || idx > numel(app.Rectangles)
                    errordlg('Select a room first.', 'No Selection', 'modal');
                    return;
                end

                app.IsEditing = true;
                app.EditIndex = idx;
                r = app.Rectangles(idx);

                % Redraw without the selected room (ROI will render it)
                app.drawAllRectangles();

                % Create interactive ROI
                app.EditHandle = drawrectangle(app.UIAxes, ...
                    'Position', [r.VertexX, r.VertexY, r.Width, r.Height], ...
                    'RotationAngle', r.Rotation, ...
                    'Color', [1 0.5 0], ...
                    'FaceAlpha', 0.1, ...
                    'InteractionsAllowed', 'all');

                app.updateEditLabels();
                app.EditListener = addlistener(app.EditHandle, 'MovingROI', ...
                    @(~,~) app.updateEditLabels());

                % Lock UI: show confirm button, disable other controls
                app.ConfirmEditButton.Visible = 'on';
                app.EditButton.Visible = 'off';
                app.setControlsEnabled('off');
                app.UIAxes.ButtonDownFcn = '';
            catch ME
                errordlg(ME.message, 'Edit Error', 'modal');
            end
        end

        function confirmEditButtonPushed(app, ~, ~)
            % confirmEditButtonPushed - Accept ROI changes and exit edit mode
            try
                if ~app.IsEditing || isempty(app.EditHandle)
                    return;
                end

                % Commit ROI state back to data (rounded to 1 decimal)
                pos = app.EditHandle.Position;
                app.Rectangles(app.EditIndex).VertexX = round(pos(1), 1);
                app.Rectangles(app.EditIndex).VertexY = round(pos(2), 1);
                app.Rectangles(app.EditIndex).Width = round(pos(3), 1);
                app.Rectangles(app.EditIndex).Height = round(pos(4), 1);
                app.Rectangles(app.EditIndex).Rotation = round(app.EditHandle.RotationAngle, 1);

                % Clean up edit resources
                if ~isempty(app.EditLabels)
                    delete(app.EditLabels(isvalid(app.EditLabels)));
                    app.EditLabels = [];
                end
                if ~isempty(app.EditListener)
                    delete(app.EditListener);
                    app.EditListener = [];
                end
                delete(app.EditHandle);
                app.EditHandle = [];

                % Exit edit mode
                app.IsEditing = false;
                app.EditIndex = [];

                % Restore UI
                app.ConfirmEditButton.Visible = 'off';
                app.EditButton.Visible = 'on';
                app.setControlsEnabled('on');
                app.UIAxes.ButtonDownFcn = @app.axesButtonDown;

                % If in apartment edit mode, keep apartment-level controls disabled
                if app.IsEditingApt
                    app.setAptEditModeControls('off');
                    app.EditAptButton.Visible = 'off';
                end

                app.drawAllRectangles();
            catch ME
                errordlg(ME.message, 'Edit Error', 'modal');
            end
        end

        function adjustButtonPushed(app, ~, ~)
            % adjustButtonPushed - Auto-fix overlaps and gaps between rooms.
            %   Calls adjustRoomContact to correct minor drawing errors.
            %   Requires at least 2 rooms. Updates the room data and redraws.
            try
            if numel(app.Rectangles) < 2
                errordlg('At least 2 rooms are needed for adjustment.', 'Not Enough Rooms', 'modal');
                return;
            end

            % Show progress dialog while processing
            progDlg = uiprogressdlg(app.UIFigure, ...
                'Title', 'Adjusting Rooms', ...
                'Message', 'Fixing overlaps and gaps. Please wait...', ...
                'Indeterminate', 'on');

            % Build room struct array from current Rectangles (display units)
            roomStructs = app.buildRoomStructs(app.Rectangles);

            % Suppress adjustRoomContact warnings (shown as popup instead)
            warnIDs = {'adjustRoomContact:maxIterReached', ...
                       'adjustRoomContact:overlap', ...
                       'adjustRoomContact:negativeDimension', ...
                       'adjustRoomContact:roomNotFound'};
            cellfun(@(id) warning('off', id), warnIDs); %#ok<NOEFF>
            restoreWarnings = onCleanup(@() cellfun(@(id) warning('on', id), warnIDs)); %#ok<NASGU>

            lastwarn('');
            try
                adjustedRooms = adjustRoomContact( ...
                    Apartment=roomStructs, Tol=app.TolField.Value, MaxIter=10000, Plot=false);
            catch ME
                close(progDlg);
                errordlg(['Adjustment failed: ' ME.message ...
                     newline newline 'Try editing rooms manually or increasing tolerance.'], ...
                    'Adjust Error', 'modal');
                return;
            end

            close(progDlg);

            % Check if a warning was issued and show as popup
            [warnMsg, warnId] = lastwarn;
            if ~isempty(warnId) && contains(warnId, 'adjustRoomContact')
                warndlg(warnMsg, 'Adjustment Warning', 'modal');
            end

            % Verify no overlaps remain after adjustment
            nRooms = numel(adjustedRooms);
            for j = 1:nRooms-1
                for k = j+1:nRooms
                    intPoly = intersect(adjustedRooms(j).floorPlan, adjustedRooms(k).floorPlan);
                    if intPoly.area > 1e-6
                        errordlg(['Overlaps remain after adjustment. ' ...
                             'Rooms may need manual editing or a larger tolerance.'], ...
                            'Adjustment Incomplete', 'modal');
                        return;
                    end
                end
            end

            % Update app Rectangles with adjusted geometry from returned struct
            for i = 1:nRooms
                app.Rectangles(i).VertexX  = round(adjustedRooms(i).geometry.dim.vertex(1), 1);
                app.Rectangles(i).VertexY  = round(adjustedRooms(i).geometry.dim.vertex(2), 1);
                app.Rectangles(i).Width    = round(adjustedRooms(i).geometry.dim.width, 1);
                app.Rectangles(i).Height   = round(adjustedRooms(i).geometry.dim.length, 1);
                app.Rectangles(i).Rotation = round(adjustedRooms(i).geometry.dim.theta, 1);
            end

            % Redraw on the app axes with updated data
            app.drawAllRectangles();
            app.fitViewToContent();
            catch ME
                errordlg(ME.message, 'Adjust Error', 'modal');
            end
        end

    end

    %% ===================================================================
    %  CALLBACKS - Apartment Management
    %  ===================================================================
    methods (Access = private)

        function createAptButtonPushed(app, ~, ~)
            % createAptButtonPushed - Group current rooms into a new apartment
            try
                if isempty(app.Rectangles)
                    errordlg('No rooms defined. Draw at least one room before creating an apartment.', ...
                        'No Rooms', 'modal');
                    return;
                end

                % Check for overlapping rooms among active rooms
                roomStructs = app.buildRoomStructs(app.Rectangles);
                overlapMsg = '';
                for j = 1:numel(roomStructs)-1
                    for k = j+1:numel(roomStructs)
                        intPoly = intersect(roomStructs(j).floorPlan, roomStructs(k).floorPlan);
                        if intPoly.area > 1e-6
                            overlapMsg = ['Rooms have overlapping regions. Fix overlaps manually ' ...
                                 '(Edit Room or Adjust) before creating an apartment.'];
                            break;
                        end
                    end
                    if ~isempty(overlapMsg); break; end
                end

                % Check for overlap with existing apartment rooms
                if isempty(overlapMsg)
                    for a = 1:numel(app.Apartments)
                        aptRoomStructs = app.buildRoomStructs(app.Apartments{a}.rooms);
                        for j = 1:numel(roomStructs)
                            for k = 1:numel(aptRoomStructs)
                                intPoly = intersect(roomStructs(j).floorPlan, aptRoomStructs(k).floorPlan);
                                if intPoly.area > 1e-6
                                    overlapMsg = ['Rooms overlap with existing apartment "' ...
                                         app.Apartments{a}.name '". Fix overlaps before creating an apartment.'];
                                    break;
                                end
                            end
                            if ~isempty(overlapMsg); break; end
                        end
                        if ~isempty(overlapMsg); break; end
                    end
                end

                if ~isempty(overlapMsg)
                    errordlg(overlapMsg, 'Overlapping Rooms', 'modal');
                    return;
                end

                app.AptCount = app.AptCount + 1;
                aptName = sprintf('Apartment%d', app.AptCount);

                aptData.name = aptName;
                aptData.unitStr = app.getUnitCode();
                aptData.rooms = app.Rectangles;
                aptData.flipData = [];
                aptData.cmrData = [];

                app.Apartments{end+1} = aptData;
                app.updateApartmentList();
                app.ApartmentListBox.Value = numel(app.Apartments);
                app.clearCurrentRooms();

                uialert(app.UIFigure, ...
                    sprintf('"%s" created with %d room(s).\nDraw rooms for the next apartment or Save.', ...
                    aptName, numel(aptData.rooms)), ...
                    'Apartment Created', 'Icon', 'success');
            catch ME
                errordlg(ME.message, 'Error', 'modal');
            end
        end

        function editAptButtonPushed(app, ~, ~)
            % editAptButtonPushed - Load apartment rooms for editing
            %   Loads the selected apartment's rooms into the active room list
            %   so individual rooms can be edited, added, or deleted. Disables
            %   apartment-level controls until confirmed.
            try
                idx = app.ApartmentListBox.Value;
                if isempty(idx)
                    errordlg('Select an apartment first.', 'No Selection', 'modal');
                    return;
                end

                if ~isempty(app.Rectangles)
                    errordlg('Current rooms must be saved as an apartment or cleared before editing another apartment.', ...
                        'Rooms Exist', 'modal');
                    return;
                end

                % Enter apartment edit mode
                app.IsEditingApt = true;
                app.EditAptIndex = idx;

                % Load apartment rooms into active room list
                apt = app.Apartments{idx};
                app.Rectangles = apt.rooms;
                app.RectCount = numel(apt.rooms);
                app.updateRectangleList();
                if ~isempty(app.Rectangles)
                    app.RectangleListBox.Value = 1;
                    app.NameEditField.Value = app.Rectangles(1).Name;
                end

                % Update UI: show Confirm, hide Edit, disable apartment controls
                app.ConfirmAptButton.Visible = 'on';
                app.EditAptButton.Visible = 'off';
                app.setAptEditModeControls('off');

                app.drawAllRectangles();
            catch ME
                errordlg(ME.message, 'Edit Error', 'modal');
            end
        end

        function confirmAptEditButtonPushed(app, ~, ~)
            % confirmAptEditButtonPushed - Save edited rooms back to the apartment
            %   Updates the apartment's room data with the current active rooms
            %   and exits apartment edit mode.
            try
                if ~app.IsEditingApt
                    return;
                end

                if isempty(app.Rectangles)
                    errordlg('Apartment must have at least one room. Add rooms or delete the apartment instead.', ...
                        'No Rooms', 'modal');
                    return;
                end

                % Check for overlapping rooms before confirming
                if app.hasOverlappingRooms()
                    errordlg(['Rooms have overlapping regions. Fix overlaps manually ' ...
                         '(Edit Room or Adjust) before confirming.'], ...
                        'Overlapping Rooms', 'modal');
                    return;
                end

                % Update apartment data
                idx = app.EditAptIndex;
                editedName = app.Apartments{idx}.name;
                app.Apartments{idx}.rooms = app.Rectangles;
                app.Apartments{idx}.flipData = [];   % Edited apartment is no longer a flip copy
                app.Apartments{idx}.cmrData = [];    % Edited apartment is no longer a CMR copy

                % Convert any apartments that reference this one to standalone,
                % since the source geometry has changed and the flip/CMR call
                % would now produce different results than the stored rooms.
                app.clearDependentsOfSource(editedName);

                % Exit apartment edit mode
                app.IsEditingApt = false;
                app.EditAptIndex = [];

                % Clear active rooms
                app.Rectangles = [];
                app.RectCount = 0;
                app.updateRectangleList();
                app.NameEditField.Value = '';

                % Restore UI
                app.ConfirmAptButton.Visible = 'off';
                app.EditAptButton.Visible = 'on';
                app.setAptEditModeControls('on');

                app.updateApartmentList();
                app.drawAllRectangles();
                app.fitViewToContent();
            catch ME
                errordlg(ME.message, 'Error', 'modal');
            end
        end

        function deleteAptButtonPushed(app, ~, ~)
            % deleteAptButtonPushed - Remove the selected apartment
            %   Any remaining apartment that references the deleted one
            %   (via flipData or cmrData) is converted to a standalone
            %   "drawn" apartment so generated code remains valid.
            try
                idx = app.ApartmentListBox.Value;
                if isempty(idx)
                    errordlg('Select an apartment first.', 'No Selection', 'modal');
                    return;
                end

                deletedName = app.Apartments{idx}.name;

                % Remove the apartment
                app.Apartments(idx) = [];

                % Convert any dependent apartments to standalone (drawn) type
                app.clearDependentsOfSource(deletedName);

                app.updateApartmentList();

                if ~isempty(app.Apartments)
                    app.ApartmentListBox.Value = 1;
                end
                app.drawAllRectangles();
            catch ME
                errordlg(ME.message, 'Delete Apartment Error', 'modal');
            end
        end

        function clearDependentsOfSource(app, sourceName)
            % clearDependentsOfSource - Remove flip/CMR references to a deleted apartment
            %   Scans all remaining apartments. Any that reference sourceName
            %   via flipData or cmrData are converted to standalone (drawn)
            %   apartments. Their room geometry is preserved; only the
            %   code-generation path changes from a function call to explicit
            %   addRoomToFloorPlan statements.
            for i = 1:numel(app.Apartments)
                apt = app.Apartments{i};

                if isfield(apt, 'flipData') && ~isempty(apt.flipData) ...
                        && strcmp(apt.flipData.sourceApt, sourceName)
                    app.Apartments{i}.flipData = [];
                end

                if isfield(apt, 'cmrData') && ~isempty(apt.cmrData) ...
                        && strcmp(apt.cmrData.sourceApt, sourceName)
                    app.Apartments{i}.cmrData = [];
                end
            end
        end

        function adjustAptButtonPushed(app, ~, ~)
            % adjustAptButtonPushed - Move selected apartment to close smallest gap
            %   Finds the smallest axis-aligned gap between any room in the
            %   selected apartment and any room in another apartment, then
            %   translates the entire selected apartment to close it.
            try
                if numel(app.Apartments) < 2
                    errordlg('At least 2 apartments are needed for adjustment.', ...
                        'Not Enough Apartments', 'modal');
                    return;
                end

                selIdx = app.ApartmentListBox.Value;
                if isempty(selIdx)
                    errordlg('Select an apartment to adjust.', 'No Selection', 'modal');
                    return;
                end

                % Find smallest gap and corresponding shift
                shift = app.findSmallestAptGap(selIdx);

                if isempty(shift)
                    msgbox('No alignable gap found. Apartments may already be touching.', ...
                        'No Gap Found', 'help', 'modal');
                    return;
                end

                % Apply rigid-body translation to all rooms of selected apartment
                for i = 1:numel(app.Apartments{selIdx}.rooms)
                    app.Apartments{selIdx}.rooms(i).VertexX = ...
                        round(app.Apartments{selIdx}.rooms(i).VertexX + shift(1), 1);
                    app.Apartments{selIdx}.rooms(i).VertexY = ...
                        round(app.Apartments{selIdx}.rooms(i).VertexY + shift(2), 1);
                end

                % Geometry changed — invalidate derivation metadata
                app.Apartments{selIdx}.flipData = [];
                app.Apartments{selIdx}.cmrData = [];

                app.drawAllRectangles();
                app.fitViewToContent();
            catch ME
                errordlg(ME.message, 'Adjust Apartment Error', 'modal');
            end
        end

        function shift = findSmallestAptGap(app, selIdx)
            % findSmallestAptGap - Find smallest room-to-room gap for an apartment
            %   Compares each room in apartment selIdx against rooms in all
            %   other apartments. Returns the [dx, dy] shift needed to close
            %   the smallest gap, or [] if no gap is found.
            %
            %   Gap detection rules:
            %   - X gaps require approximate Y alignment (within Tol)
            %   - Y gaps require approximate X alignment (within Tol)
            %   This ensures only rooms that are actual neighbors are considered.

            selBBs = app.getRoomBoundingBoxes(app.Apartments{selIdx}.rooms);

            % Collect bounding boxes for all rooms in other apartments
            otherBBs = [];
            for a = 1:numel(app.Apartments)
                if a == selIdx
                    continue;
                end
                otherBBs = [otherBBs, app.getRoomBoundingBoxes(app.Apartments{a}.rooms)]; %#ok<AGROW>
            end

            if isempty(otherBBs)
                shift = [];
                return;
            end

            tol = app.TolField.Value;
            bestGap = inf;
            shift = [];

            for i = 1:numel(selBBs)
                sb = selBBs(i);
                for j = 1:numel(otherBBs)
                    ob = otherBBs(j);

                    % X gaps (rooms approximately aligned in Y)
                    yOverlap = min(sb.yMax, ob.yMax) - max(sb.yMin, ob.yMin);
                    if yOverlap > -tol
                        gapX = sb.xMin - ob.xMax;  % selected is right of other
                        if gapX > 0 && gapX < bestGap
                            bestGap = gapX;
                            shift = [-gapX, 0];
                        end
                        gapX = ob.xMin - sb.xMax;  % selected is left of other
                        if gapX > 0 && gapX < bestGap
                            bestGap = gapX;
                            shift = [gapX, 0];
                        end
                    end

                    % Y gaps (rooms approximately aligned in X)
                    xOverlap = min(sb.xMax, ob.xMax) - max(sb.xMin, ob.xMin);
                    if xOverlap > -tol
                        gapY = sb.yMin - ob.yMax;  % selected is above other
                        if gapY > 0 && gapY < bestGap
                            bestGap = gapY;
                            shift = [0, -gapY];
                        end
                        gapY = ob.yMin - sb.yMax;  % selected is below other
                        if gapY > 0 && gapY < bestGap
                            bestGap = gapY;
                            shift = [0, gapY];
                        end
                    end
                end
            end
        end

        function bbs = getRoomBoundingBoxes(app, rooms)
            % getRoomBoundingBoxes - Axis-aligned bounding box for each room
            %   Input:  rooms - struct array (app format)
            %   Output: bbs   - struct array with xMin, xMax, yMin, yMax
            bbs = struct('xMin', {}, 'xMax', {}, 'yMin', {}, 'yMax', {});
            for i = 1:numel(rooms)
                corners = app.getRotatedCorners(rooms(i));
                bbs(i).xMin = min(corners(1,:));
                bbs(i).xMax = max(corners(1,:));
                bbs(i).yMin = min(corners(2,:));
                bbs(i).yMax = max(corners(2,:));
            end
        end

        function flipAptButtonPushed(app, ~, ~)
            % flipAptButtonPushed - Mirror a source apartment to create a new one
            %   Builds the source via addRoomToFloorPlan, calls flipApartmentUnit,
            %   then extracts geometry back into app format (converting from
            %   meters to display units).
            try
                % Validate source selection
                sourceName = app.FlipSourceDropDown.Value;
                if isempty(sourceName)
                    errordlg('Select a source apartment to flip.', 'No Source', 'modal');
                    return;
                end

                % Find source apartment
                sourceIdx = find(cellfun(@(a) strcmp(a.name, sourceName), app.Apartments), 1);
                if isempty(sourceIdx)
                    errordlg('Source apartment not found.', 'Error', 'modal');
                    return;
                end

                sourceApt = app.Apartments{sourceIdx};
                axisChoice = app.FlipAxisDropDown.Value;
                axisValue = app.FlipValueField.Value;
                unitStr = app.getUnitCode();

                % Build source apartment struct and flip it
                srcAptStruct = app.buildSimscapeApartment(sourceApt.rooms);
                if isempty(srcAptStruct)
                    errordlg('Source apartment has overlapping rooms. Fix the source first.', ...
                        'Overlap Error', 'modal');
                    return;
                end

                flippedAptStruct = flipApartmentUnit( ...
                    Apartment=srcAptStruct, ...
                    Axis=axisChoice, ...
                    AxisValue=simscape.Value(axisValue, unitStr));

                if isempty(flippedAptStruct)
                    errordlg('Flipped apartment has overlapping rooms.', 'Flip Error', 'modal');
                    return;
                end

                % Extract room geometry and check overlap with existing apartments
                flippedRooms = app.extractRoomsFromStruct(flippedAptStruct);
                overlapDetected = app.roomsOverlapExisting(flippedRooms, [], true);
                if overlapDetected
                    errordlg(['Flipped apartment overlaps rooms from an existing apartment. ' ...
                         'Adjust the flip axis value to avoid overlap.'], ...
                        'Overlapping Rooms', 'modal');
                    return;
                end

                % Create new apartment
                app.AptCount = app.AptCount + 1;
                aptName = sprintf('Apartment%d', app.AptCount);

                aptData.name = aptName;
                aptData.unitStr = unitStr;
                aptData.rooms = flippedRooms;
                aptData.flipData.sourceApt = sourceName;
                aptData.flipData.axis = axisChoice;
                aptData.flipData.axisValue = axisValue;
                aptData.cmrData = [];

                app.Apartments{end+1} = aptData;
                app.updateApartmentList();
                app.ApartmentListBox.Value = numel(app.Apartments);
                app.drawAllRectangles();
                app.fitViewToContent();

                uialert(app.UIFigure, ...
                    sprintf('"%s" created by flipping "%s" about %s = %.1f.', ...
                    aptName, sourceName, axisChoice, axisValue), ...
                    'Flip Apartment Created', 'Icon', 'success');
            catch ME
                errordlg(ME.message, 'Flip Error', 'modal');
            end
        end

        function cmrSourceChanged(app, ~, ~)
            % cmrSourceChanged - Pre-fill room name field when CMR source apartment changes
            sourceName = app.CMRSourceDropDown.Value;
            if isempty(sourceName)
                app.CMRRoomField.Value = '';
                return;
            end
            sourceIdx = find(cellfun(@(a) strcmp(a.name, sourceName), app.Apartments), 1);
            if isempty(sourceIdx)
                app.CMRRoomField.Value = '';
                return;
            end
            roomNames = {app.Apartments{sourceIdx}.rooms.Name};
            app.CMRRoomField.Value = roomNames{1};
        end

        function cmrButtonPushed(app, ~, ~)
            % cmrButtonPushed - Copy, move, and/or rotate a source apartment
            %   Builds the source apartment struct, calls copyMoveRotateForNewApartment,
            %   then extracts geometry back into app format.
            try
                % Validate source selection
                sourceName = app.CMRSourceDropDown.Value;
                if isempty(sourceName)
                    errordlg('Select a source apartment.', 'No Source', 'modal');
                    return;
                end

                % Find source apartment
                sourceIdx = find(cellfun(@(a) strcmp(a.name, sourceName), app.Apartments), 1);
                if isempty(sourceIdx)
                    errordlg('Source apartment not found.', 'Error', 'modal');
                    return;
                end

                sourceApt = app.Apartments{sourceIdx};
                unitStr = app.getUnitCode();
                xOffset = app.CMRXOffsetField.Value;
                yOffset = app.CMRYOffsetField.Value;
                rotAngle = app.CMRAngleField.Value;
                rotRoom = strtrim(app.CMRRoomField.Value);

                % Validate rotation room if angle is non-zero
                if rotAngle ~= 0 && isempty(rotRoom)
                    errordlg('Select a room to rotate about when rotation angle is non-zero.', ...
                        'No Rotation Room', 'modal');
                    return;
                end

                % Build source apartment struct and apply copy/move/rotate
                srcAptStruct = app.buildSimscapeApartment(sourceApt.rooms);
                if isempty(srcAptStruct)
                    errordlg('Source apartment has overlapping rooms. Fix the source first.', ...
                        'Overlap Error', 'modal');
                    return;
                end

                if rotAngle == 0
                    rotRoom = '';  % Not used when angle is 0
                end

                newAptStruct = copyMoveRotateForNewApartment( ...
                    Apartment=srcAptStruct, ...
                    MoveDistance=simscape.Value([xOffset, yOffset], unitStr), ...
                    RotationAngle=simscape.Value(rotAngle, "deg"), ...
                    RotateAboutRoom=rotRoom, ...
                    Tol=0.01);

                if isempty(newAptStruct)
                    errordlg('Resulting apartment has overlapping rooms or invalid rotation room.', ...
                        'Copy/Move/Rotate Error', 'modal');
                    return;
                end

                % Extract room geometry and check overlap with existing apartments
                newRooms = app.extractRoomsFromStruct(newAptStruct);
                overlapDetected = app.roomsOverlapExisting(newRooms, [], true);
                if overlapDetected
                    errordlg(['Copied apartment overlaps rooms from an existing apartment. ' ...
                         'Adjust offset or rotation to avoid overlap.'], ...
                        'Overlapping Rooms', 'modal');
                    return;
                end

                % Create new apartment
                app.AptCount = app.AptCount + 1;
                aptName = sprintf('Apartment%d', app.AptCount);

                aptData.name = aptName;
                aptData.unitStr = unitStr;
                aptData.rooms = newRooms;
                aptData.flipData = [];
                aptData.cmrData.sourceApt = sourceName;
                aptData.cmrData.xOffset = xOffset;
                aptData.cmrData.yOffset = yOffset;
                aptData.cmrData.rotAngle = rotAngle;
                aptData.cmrData.rotRoom = rotRoom;

                app.Apartments{end+1} = aptData;
                app.updateApartmentList();
                app.ApartmentListBox.Value = numel(app.Apartments);
                app.drawAllRectangles();
                app.fitViewToContent();

                uialert(app.UIFigure, ...
                    sprintf('"%s" created by copy/move/rotate of "%s".', aptName, sourceName), ...
                    'Copy/Move/Rotate Created', 'Icon', 'success');
            catch ME
                errordlg(ME.message, 'Copy/Move/Rotate Error', 'modal');
            end
        end

    end

    %% ===================================================================
    %  CALLBACKS - View and Session Controls
    %  ===================================================================
    methods (Access = private)

        function unitChanged(app, ~, ~)
            % unitChanged - Refresh axis labels when units selection changes
            app.drawAllRectangles();
        end

        function filenameChanged(app, ~, ~)
            % filenameChanged - Enable Save button only when filename is non-empty
            if isempty(strtrim(app.FilenameEditField.Value))
                app.SaveFloorPlanButton.Enable = 'off';
            else
                app.SaveFloorPlanButton.Enable = 'on';
            end
        end

        function resetAllButtonPushed(app, ~, ~)
            % resetAllButtonPushed - Clear all data and start a fresh session
            app.Rectangles = [];
            app.RectCount = 0;
            app.AptCount = 0;
            app.Apartments = {};
            app.UnitsLocked = false;
            app.IsEditingApt = false;
            app.EditAptIndex = [];

            app.updateRectangleList();
            app.updateApartmentList();
            app.NameEditField.Value = '';
            app.FilenameEditField.Value = '';
            app.SaveFloorPlanButton.Enable = 'off';
            app.UnitDropDown.Enable = 'on';
            app.ConfirmAptButton.Visible = 'off';
            app.EditAptButton.Visible = 'on';
            app.CMRXOffsetField.Value = 0;
            app.CMRYOffsetField.Value = 0;
            app.CMRAngleField.Value = 0;
            app.CMRRoomField.Value = '';

            app.UIAxes.XLim = [0 100];
            app.UIAxes.YLim = [0 100];
            app.drawAllRectangles();
        end

        function zoomInButtonPushed(app, ~, ~)
            % zoomInButtonPushed - Reduce visible area by 25% toward center
            xLim = app.UIAxes.XLim;
            yLim = app.UIAxes.YLim;
            xCenter = mean(xLim);
            yCenter = mean(yLim);
            app.UIAxes.XLim = [xCenter - diff(xLim)*0.375, xCenter + diff(xLim)*0.375];
            app.UIAxes.YLim = [yCenter - diff(yLim)*0.375, yCenter + diff(yLim)*0.375];
            app.configureGrid();
        end

        function zoomOutButtonPushed(app, ~, ~)
            % zoomOutButtonPushed - Expand visible area by 25% from center
            xLim = app.UIAxes.XLim;
            yLim = app.UIAxes.YLim;
            xCenter = mean(xLim);
            yCenter = mean(yLim);
            app.UIAxes.XLim = [xCenter - diff(xLim)*0.625, xCenter + diff(xLim)*0.625];
            app.UIAxes.YLim = [yCenter - diff(yLim)*0.625, yCenter + diff(yLim)*0.625];
            app.configureGrid();
        end

        function resetViewButtonPushed(app, ~, ~)
            % resetViewButtonPushed - Fit all rooms in view
            app.fitViewToContent();
        end

        function outlineButtonPushed(app, ~, ~)
            % outlineButtonPushed - Toggle the merged building outline overlay
            %   Computes the union of all apartment room polyshapes and draws
            %   the outer boundary as a dotted black line. Toggling off removes
            %   the overlay; toggling on recomputes and redraws it.
            app.OutlineVisible = ~app.OutlineVisible;
            app.drawAllRectangles();
        end

        function saveFloorPlanButtonPushed(app, ~, ~)
            % saveFloorPlanButtonPushed - Generate and save a MATLAB Live Script
            %   Validates inputs, checks for existing file, writes code to .m,
            %   converts to .mlx. Prompts for a new name if file already exists.

            if isempty(app.Apartments)
                errordlg('No apartments created. Use "Create Apt" first.', ...
                    'No Apartments', 'modal');
                return;
            end

            baseName = strtrim(app.FilenameEditField.Value);
            if isempty(baseName)
                errordlg('Please specify a filename for the output script.', ...
                    'No Filename', 'modal');
                return;
            end
            [~, baseName, ~] = fileparts(baseName);

            if ~isempty(regexp(baseName, '[^a-zA-Z0-9_]', 'once'))
                errordlg('Filename must contain only letters, numbers, and underscores.', ...
                    'Invalid Filename', 'modal');
                return;
            end

            % Check if file already exists; prompt for new name if so
            baseName = app.resolveFilenameConflict(baseName);
            if isempty(baseName)
                msgbox('Save cancelled. No file was saved.', ...
                    'Save Cancelled', 'help', 'modal');
                return;
            end

            % Generate and write code
            codeLines = app.generateFloorPlanCode();
            tempMfile = fullfile(pwd, [baseName '_temp.m']);
            fid = fopen(tempMfile, 'w');
            if fid == -1
                errordlg(sprintf('Cannot write to folder:\n%s\nCheck write permissions.', pwd), ...
                    'File Error', 'modal');
                return;
            end
            for i = 1:numel(codeLines)
                fprintf(fid, '%s\n', codeLines{i});
            end
            fclose(fid);

            % Convert to Live Script (.mlx), fallback to .m
            scriptName = [baseName '.mlx'];
            scriptPath = fullfile(pwd, scriptName);
            try
                export(tempMfile, scriptPath);
                delete(tempMfile);
            catch
                scriptName = [baseName '.m'];
                scriptPath = fullfile(pwd, scriptName);
                movefile(tempMfile, scriptPath);
            end

            % Update the filename field with the final name used
            app.FilenameEditField.Value = baseName;

            uialert(app.UIFigure, ...
                sprintf('Floor plan saved as "%s" in:\n%s', scriptName, pwd), ...
                'Floor Plan Saved', 'Icon', 'success');
        end

        function baseName = resolveFilenameConflict(app, baseName)
            % resolveFilenameConflict - Check if file exists, prompt for new name
            %   Returns the resolved filename, or '' if user cancels.

            while true
                mlxPath = fullfile(pwd, [baseName '.mlx']);
                mPath   = fullfile(pwd, [baseName '.m']);

                if ~isfile(mlxPath) && ~isfile(mPath)
                    return;  % No conflict
                end

                % File exists — prompt user for a new name
                answer = inputdlg( ...
                    {sprintf('A file named "%s" already exists.\nEnter a new filename (or leave empty to cancel):', baseName)}, ...
                    'File Already Exists', [1 50], {''});

                % User pressed Cancel or closed the dialog
                if isempty(answer)
                    baseName = '';
                    return;
                end

                newName = strtrim(answer{1});

                % User left field empty — cancel
                if isempty(newName)
                    baseName = '';
                    return;
                end

                [~, newName, ~] = fileparts(newName);

                % Validate the new name
                if ~isempty(regexp(newName, '[^a-zA-Z0-9_]', 'once'))
                    errordlg('Filename must contain only letters, numbers, and underscores. Try again.', ...
                        'Invalid Filename', 'modal');
                    continue;
                end

                baseName = newName;
                % Loop back to check if new name also conflicts
            end
        end

    end

    %% ===================================================================
    %  UI COMPONENT CREATION
    %  ===================================================================
    methods (Access = private)

        function createComponents(app)
            % createComponents - Build all UI components programmatically
            app.createMainFigure();
            app.createLeftPanelControls();
            app.createRightPanelControls();
            app.UIFigure.Visible = 'on';
        end

        function createMainFigure(app)
            % createMainFigure - Create figure window, menu, tabs, and layout

            % Main figure
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1100 750];
            app.UIFigure.Name = 'Building Designer';
            app.UIFigure.WindowButtonMotionFcn = @app.figureMouseMove;
            app.UIFigure.WindowButtonUpFcn = @app.figureMouseUp;

            % Menu bar: Help > Documentation, App Help
            helpMenu = uimenu(app.UIFigure, 'Text', 'Help');
            uimenu(helpMenu, 'Text', 'Building Definition (Simscape)', ...
                'MenuSelectedFcn', @(~,~) web('DocumentationBuildingDefinitionSimscape.html'));
            uimenu(helpMenu, 'Text', 'FloorPlanBuilderApp Help', ...
                'MenuSelectedFcn', @(~,~) web('FloorPlanBuilderAppHelp.html'));

            % Tab group within a grid
            figGrid = uigridlayout(app.UIFigure, [1, 1]);
            figGrid.Padding = [5 5 5 5];
            app.TabGroup = uitabgroup(figGrid);
            app.TabGroup.Layout.Row = 1;
            app.TabGroup.Layout.Column = 1;
            app.FloorPlanTab = uitab(app.TabGroup, 'Title', 'Create Floor Plan');

            % Two-column layout: left controls, right drawing area
            app.GridLayout = uigridlayout(app.FloorPlanTab, [1, 2]);
            app.GridLayout.ColumnWidth = {310, '1x'};
        end

        function createLeftPanelControls(app)
            % createLeftPanelControls - Build controls panel (left side)

            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Title = 'Controls';
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            leftGrid = uigridlayout(app.LeftPanel, [21, 5]);
            leftGrid.RowHeight = {26, 26, 22, 28, '1x', 22, 28, 28, 28, 36, 28, 36, 28, 28, 22, '1x', 28, 28, 28, 36, 28};
            %  Rows: 1=header, 2=name, 3=rooms label,
            %  4=Delete, 5=listbox flex, 6=Tol field, 7=Adjust, 8=Edit/Confirm, 9=CreateApt,
            %  10=flip info, 11=flip controls, 12=CMR info, 13=CMR row1, 14=CMR row2,
            %  15=apt label, 16-19=apt list+btns, 20=save info, 21=filename+save
            leftGrid.RowSpacing = 3;
            leftGrid.ColumnWidth = {'2x', '2x', 45, '1x', 70};

            % --- Row 1: Instructions + Units + Reset All ---
            app.InstructionsLabel = uilabel(leftGrid);
            app.InstructionsLabel.Layout.Row = 1;
            app.InstructionsLabel.Layout.Column = [1 2];
            app.InstructionsLabel.Text = 'Draw rooms on plot';
            app.InstructionsLabel.FontWeight = 'bold';
            app.InstructionsLabel.FontColor = [0 0.4 0.1];

            app.UnitDropDown = uidropdown(leftGrid);
            app.UnitDropDown.Layout.Row = 1;
            app.UnitDropDown.Layout.Column = [3 4];
            app.UnitDropDown.Items = {'Meters', 'Feet'};
            app.UnitDropDown.Value = 'Meters';
            app.UnitDropDown.Tooltip = 'Length units for all dimensions (locked after first room is drawn)';
            app.UnitDropDown.ValueChangedFcn = @app.unitChanged;

            app.ResetAllButton = uibutton(leftGrid, 'push');
            app.ResetAllButton.Layout.Row = 1;
            app.ResetAllButton.Layout.Column = 5;
            app.ResetAllButton.Text = 'Reset All';
            app.ResetAllButton.FontColor = [0.6 0 0];
            app.ResetAllButton.Tooltip = 'Erase all rooms and apartments, unlock units, start fresh';
            app.ResetAllButton.ButtonPushedFcn = @app.resetAllButtonPushed;

            % --- Row 2: Name label + Name field + Apply ---
            app.NameLabel = uilabel(leftGrid);
            app.NameLabel.Layout.Row = 2;
            app.NameLabel.Layout.Column = 1;
            app.NameLabel.Text = 'Name:';

            app.NameEditField = uieditfield(leftGrid, 'text');
            app.NameEditField.Layout.Row = 2;
            app.NameEditField.Layout.Column = [2 4];
            app.NameEditField.Tooltip = 'Enter a name for the selected room, then click Apply';

            app.ApplyNameButton = uibutton(leftGrid, 'push');
            app.ApplyNameButton.Layout.Row = 2;
            app.ApplyNameButton.Layout.Column = 5;
            app.ApplyNameButton.Text = 'Apply';
            app.ApplyNameButton.Tooltip = 'Apply the name in the text field to the selected room';
            app.ApplyNameButton.ButtonPushedFcn = @app.applyNameButtonPushed;

            % --- Row 3: Rooms label ---
            app.RectangleListLabel = uilabel(leftGrid);
            app.RectangleListLabel.Layout.Row = 3;
            app.RectangleListLabel.Layout.Column = [1 5];
            app.RectangleListLabel.Text = 'Rooms (current apartment):';
            app.RectangleListLabel.FontWeight = 'bold';

            % --- Rows 4-9: Room listbox + action buttons in col 5 ---
            app.RectangleListBox = uilistbox(leftGrid);
            app.RectangleListBox.Layout.Row = [4 9];
            app.RectangleListBox.Layout.Column = [1 4];
            app.RectangleListBox.Items = {};
            app.RectangleListBox.Tooltip = 'Rooms being defined for the next apartment. Select to rename, edit, or delete.';
            app.RectangleListBox.ValueChangedFcn = @app.listBoxValueChanged;

            % --- Row 4: Delete room button (col 5, top-right of listbox) ---
            app.DeleteButton = uibutton(leftGrid, 'push');
            app.DeleteButton.Layout.Row = 4;
            app.DeleteButton.Layout.Column = 5;
            app.DeleteButton.Text = 'Delete';
            app.DeleteButton.FontColor = [0.8 0 0];
            app.DeleteButton.Tooltip = 'Remove the selected room permanently';
            app.DeleteButton.ButtonPushedFcn = @app.deleteButtonPushed;

            % --- Row 5-6: Tolerance label + field (col 5) ---
            app.TolLabel = uilabel(leftGrid);
            app.TolLabel.Layout.Row = 5;
            app.TolLabel.Layout.Column = 5;
            app.TolLabel.Text = 'Tol(%)';
            app.TolLabel.HorizontalAlignment = 'center';
            app.TolLabel.VerticalAlignment = 'bottom';
            app.TolLabel.FontSize = 10;
            app.TolLabel.FontColor = [0.4 0.2 0];
            app.TolLabel.Enable = 'off';

            app.TolField = uieditfield(leftGrid, 'numeric');
            app.TolField.Layout.Row = 6;
            app.TolField.Layout.Column = 5;
            app.TolField.Value = 2;
            app.TolField.Enable = 'off';
            app.TolField.Tooltip = 'Tolerance percentage for adjusting room contacts (overlap/gap threshold)';

            % --- Row 7: Adjust button (col 5) ---
            app.AdjustButton = uibutton(leftGrid, 'push');
            app.AdjustButton.Layout.Row = 7;
            app.AdjustButton.Layout.Column = 5;
            app.AdjustButton.Text = 'Adjust';
            app.AdjustButton.FontColor = [0.4 0.2 0];
            app.AdjustButton.FontWeight = 'bold';
            app.AdjustButton.Enable = 'off';
            app.AdjustButton.Tooltip = 'Auto-fix small overlaps and gaps between rooms (requires 2 or more rooms)';
            app.AdjustButton.ButtonPushedFcn = @app.adjustButtonPushed;

            % --- Row 8: Edit Room / Confirm button (col 5) ---
            app.EditButton = uibutton(leftGrid, 'push');
            app.EditButton.Layout.Row = 8;
            app.EditButton.Layout.Column = 5;
            app.EditButton.Text = 'Edit Room';
            app.EditButton.FontColor = [0 0.3 0.7];
            app.EditButton.Tooltip = 'Interactively move, resize, or rotate the selected room';
            app.EditButton.ButtonPushedFcn = @app.editButtonPushed;

            app.ConfirmEditButton = uibutton(leftGrid, 'push');
            app.ConfirmEditButton.Layout.Row = 8;
            app.ConfirmEditButton.Layout.Column = 5;
            app.ConfirmEditButton.Text = 'Confirm';
            app.ConfirmEditButton.FontColor = [0 0.6 0];
            app.ConfirmEditButton.FontWeight = 'bold';
            app.ConfirmEditButton.Tooltip = 'Accept current position/size and exit edit mode';
            app.ConfirmEditButton.ButtonPushedFcn = @app.confirmEditButtonPushed;
            app.ConfirmEditButton.Visible = 'off';

            % --- Row 9: Create Apt button (col 5) ---
            app.CreateAptButton = uibutton(leftGrid, 'push');
            app.CreateAptButton.Layout.Row = 9;
            app.CreateAptButton.Layout.Column = 5;
            app.CreateAptButton.Text = 'Create Apt';
            app.CreateAptButton.FontWeight = 'bold';
            app.CreateAptButton.FontColor = [0.1 0.1 0.6];
            app.CreateAptButton.Tooltip = 'Save all current rooms as a new apartment, then clear the room list';
            app.CreateAptButton.ButtonPushedFcn = @app.createAptButtonPushed;

            % --- Row 10: Flip info text ---
            app.FlipInfoLabel = uilabel(leftGrid);
            app.FlipInfoLabel.Layout.Row = 10;
            app.FlipInfoLabel.Layout.Column = [1 5];
            app.FlipInfoLabel.Text = 'Create a new apartment from a mirror copy of an existing one:';
            app.FlipInfoLabel.WordWrap = 'on';
            app.FlipInfoLabel.FontAngle = 'italic';
            app.FlipInfoLabel.FontColor = [0.3 0.3 0.3];

            % --- Row 11: Flip controls (Source + Axis + Value + Flip button) ---
            app.FlipSourceDropDown = uidropdown(leftGrid);
            app.FlipSourceDropDown.Layout.Row = 11;
            app.FlipSourceDropDown.Layout.Column = [1 2];
            app.FlipSourceDropDown.Items = {};
            app.FlipSourceDropDown.Tooltip = 'Select which apartment to mirror';

            app.FlipAxisDropDown = uidropdown(leftGrid);
            app.FlipAxisDropDown.Layout.Row = 11;
            app.FlipAxisDropDown.Layout.Column = 3;
            app.FlipAxisDropDown.Items = {'x', 'y'};
            app.FlipAxisDropDown.Value = 'x';
            app.FlipAxisDropDown.Tooltip = 'Axis of symmetry: x = vertical line, y = horizontal line';

            app.FlipValueField = uieditfield(leftGrid, 'numeric');
            app.FlipValueField.Layout.Row = 11;
            app.FlipValueField.Layout.Column = 4;
            app.FlipValueField.Value = 0;
            app.FlipValueField.Tooltip = 'Position of the mirror axis (in current length units)';

            app.FlipAptButton = uibutton(leftGrid, 'push');
            app.FlipAptButton.Layout.Row = 11;
            app.FlipAptButton.Layout.Column = 5;
            app.FlipAptButton.Text = 'Flip';
            app.FlipAptButton.FontWeight = 'bold';
            app.FlipAptButton.FontColor = [0.4 0.1 0.6];
            app.FlipAptButton.Enable = 'off';
            app.FlipAptButton.Tooltip = 'Mirror the source apartment about the axis to create a new apartment';
            app.FlipAptButton.ButtonPushedFcn = @app.flipAptButtonPushed;

            % --- Row 12: Copy/Move/Rotate info text ---
            app.CMRInfoLabel = uilabel(leftGrid);
            app.CMRInfoLabel.Layout.Row = 12;
            app.CMRInfoLabel.Layout.Column = [1 5];
            app.CMRInfoLabel.Text = 'Create a new apartment by copying, moving, and/or rotating an existing one:';
            app.CMRInfoLabel.WordWrap = 'on';
            app.CMRInfoLabel.FontAngle = 'italic';
            app.CMRInfoLabel.FontColor = [0.3 0.3 0.3];

            % --- Row 13: CMR controls row 1 (Source + X offset + Y offset) ---
            app.CMRSourceDropDown = uidropdown(leftGrid);
            app.CMRSourceDropDown.Layout.Row = 13;
            app.CMRSourceDropDown.Layout.Column = [1 2];
            app.CMRSourceDropDown.Items = {};
            app.CMRSourceDropDown.Tooltip = 'Select which apartment to copy/move/rotate';
            app.CMRSourceDropDown.ValueChangedFcn = @app.cmrSourceChanged;

            app.CMRXOffsetField = uieditfield(leftGrid, 'numeric');
            app.CMRXOffsetField.Layout.Row = 13;
            app.CMRXOffsetField.Layout.Column = 3;
            app.CMRXOffsetField.Value = 0;
            app.CMRXOffsetField.Tooltip = 'X offset (East-West move distance in current units)';

            app.CMRYOffsetField = uieditfield(leftGrid, 'numeric');
            app.CMRYOffsetField.Layout.Row = 13;
            app.CMRYOffsetField.Layout.Column = 4;
            app.CMRYOffsetField.Value = 0;
            app.CMRYOffsetField.Tooltip = 'Y offset (North-South move distance in current units)';

            app.CMRButton = uibutton(leftGrid, 'push');
            app.CMRButton.Layout.Row = 13;
            app.CMRButton.Layout.Column = 5;
            app.CMRButton.Text = 'Copy';
            app.CMRButton.FontWeight = 'bold';
            app.CMRButton.FontColor = [0.1 0.4 0.4];
            app.CMRButton.Enable = 'off';
            app.CMRButton.Tooltip = 'Copy the source apartment with specified move and rotation';
            app.CMRButton.ButtonPushedFcn = @app.cmrButtonPushed;

            % --- Row 14: CMR controls row 2 (Angle + Room field) ---
            app.CMRAngleField = uieditfield(leftGrid, 'numeric');
            app.CMRAngleField.Layout.Row = 14;
            app.CMRAngleField.Layout.Column = [1 2];
            app.CMRAngleField.Value = 0;
            app.CMRAngleField.Tooltip = 'Rotation angle in degrees (0 = no rotation)';

            app.CMRRoomField = uieditfield(leftGrid, 'text');
            app.CMRRoomField.Layout.Row = 14;
            app.CMRRoomField.Layout.Column = [3 5];
            app.CMRRoomField.Value = '';
            app.CMRRoomField.Tooltip = 'Room name whose vertex is the rotation center (required if angle is non-zero)';

            % --- Row 15: Apartments label ---
            app.ApartmentListLabel = uilabel(leftGrid);
            app.ApartmentListLabel.Layout.Row = 15;
            app.ApartmentListLabel.Layout.Column = [1 5];
            app.ApartmentListLabel.Text = 'Apartments (saved):';
            app.ApartmentListLabel.FontWeight = 'bold';

            % --- Rows 16-19: Apartment listbox + action buttons (col 5) ---
            app.ApartmentListBox = uilistbox(leftGrid);
            app.ApartmentListBox.Layout.Row = [16 19];
            app.ApartmentListBox.Layout.Column = [1 4];
            app.ApartmentListBox.Items = {};
            app.ApartmentListBox.Tooltip = 'Apartments that have been created. Select to edit, delete, or use as flip source.';

            app.AdjustAptButton = uibutton(leftGrid, 'push');
            app.AdjustAptButton.Layout.Row = 17;
            app.AdjustAptButton.Layout.Column = 5;
            app.AdjustAptButton.Text = 'Adjust';
            app.AdjustAptButton.FontWeight = 'bold';
            app.AdjustAptButton.FontColor = [0.4 0.2 0];
            app.AdjustAptButton.Visible = 'off';
            app.AdjustAptButton.Tooltip = 'Align walls of close rooms across all apartments';
            app.AdjustAptButton.ButtonPushedFcn = @app.adjustAptButtonPushed;

            app.EditAptButton = uibutton(leftGrid, 'push');
            app.EditAptButton.Layout.Row = 18;
            app.EditAptButton.Layout.Column = 5;
            app.EditAptButton.Text = 'Edit Apt';
            app.EditAptButton.FontColor = [0 0.3 0.7];
            app.EditAptButton.Tooltip = 'Load apartment rooms for editing (add, remove, resize rooms)';
            app.EditAptButton.ButtonPushedFcn = @app.editAptButtonPushed;

            app.ConfirmAptButton = uibutton(leftGrid, 'push');
            app.ConfirmAptButton.Layout.Row = 18;
            app.ConfirmAptButton.Layout.Column = 5;
            app.ConfirmAptButton.Text = 'Confirm';
            app.ConfirmAptButton.FontColor = [0 0.6 0];
            app.ConfirmAptButton.FontWeight = 'bold';
            app.ConfirmAptButton.Tooltip = 'Save edited rooms back to the apartment and exit edit mode';
            app.ConfirmAptButton.ButtonPushedFcn = @app.confirmAptEditButtonPushed;
            app.ConfirmAptButton.Visible = 'off';

            app.DeleteAptButton = uibutton(leftGrid, 'push');
            app.DeleteAptButton.Layout.Row = 19;
            app.DeleteAptButton.Layout.Column = 5;
            app.DeleteAptButton.Text = 'Delete';
            app.DeleteAptButton.FontColor = [0.8 0 0];
            app.DeleteAptButton.Tooltip = 'Remove the selected apartment and all its rooms permanently';
            app.DeleteAptButton.ButtonPushedFcn = @app.deleteAptButtonPushed;

            % --- Row 20: Save info text ---
            app.SaveInfoLabel = uilabel(leftGrid);
            app.SaveInfoLabel.Layout.Row = 20;
            app.SaveInfoLabel.Layout.Column = [1 5];
            app.SaveInfoLabel.Text = 'Save floor plan data as a Live Script. Enter filename and click Save.';
            app.SaveInfoLabel.WordWrap = 'on';
            app.SaveInfoLabel.FontAngle = 'italic';
            app.SaveInfoLabel.FontColor = [0.3 0.3 0.3];

            % --- Row 21: Filename + field + Save ---
            app.FilenameLabel = uilabel(leftGrid);
            app.FilenameLabel.Layout.Row = 21;
            app.FilenameLabel.Layout.Column = 1;
            app.FilenameLabel.Text = 'File:';

            app.FilenameEditField = uieditfield(leftGrid, 'text');
            app.FilenameEditField.Layout.Row = 21;
            app.FilenameEditField.Layout.Column = [2 4];
            app.FilenameEditField.Value = '';
            app.FilenameEditField.Tooltip = 'Output filename (no extension). Letters, numbers, and underscores only.';
            app.FilenameEditField.ValueChangedFcn = @app.filenameChanged;

            app.SaveFloorPlanButton = uibutton(leftGrid, 'push');
            app.SaveFloorPlanButton.Layout.Row = 21;
            app.SaveFloorPlanButton.Layout.Column = 5;
            app.SaveFloorPlanButton.Text = 'Save';
            app.SaveFloorPlanButton.FontWeight = 'bold';
            app.SaveFloorPlanButton.FontColor = [0.1 0.5 0.1];
            app.SaveFloorPlanButton.Enable = 'off';
            app.SaveFloorPlanButton.Tooltip = 'Generate a MATLAB Live Script with the complete floor plan definition';
            app.SaveFloorPlanButton.ButtonPushedFcn = @app.saveFloorPlanButtonPushed;
        end

        function createRightPanelControls(app)
            % createRightPanelControls - Build drawing area panel (right side)

            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Title = 'Drawing Area';
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            rightGrid = uigridlayout(app.RightPanel, [2, 4]);
            rightGrid.RowHeight = {30, '1x'};
            rightGrid.ColumnWidth = {'1x', '1x', '1x', '1x'};
            rightGrid.Padding = [5 5 5 5];

            % Zoom and view buttons
            app.ZoomInButton = uibutton(rightGrid, 'push');
            app.ZoomInButton.Layout.Row = 1;
            app.ZoomInButton.Layout.Column = 1;
            app.ZoomInButton.Text = 'Zoom In';
            app.ZoomInButton.Tooltip = 'Zoom in toward the center of the visible area';
            app.ZoomInButton.ButtonPushedFcn = @app.zoomInButtonPushed;

            app.ZoomOutButton = uibutton(rightGrid, 'push');
            app.ZoomOutButton.Layout.Row = 1;
            app.ZoomOutButton.Layout.Column = 2;
            app.ZoomOutButton.Text = 'Zoom Out';
            app.ZoomOutButton.Tooltip = 'Zoom out from the center of the visible area';
            app.ZoomOutButton.ButtonPushedFcn = @app.zoomOutButtonPushed;

            app.ResetViewButton = uibutton(rightGrid, 'push');
            app.ResetViewButton.Layout.Row = 1;
            app.ResetViewButton.Layout.Column = 3;
            app.ResetViewButton.Text = 'Reset View';
            app.ResetViewButton.Tooltip = 'Auto-fit view to show all rooms and apartments';
            app.ResetViewButton.ButtonPushedFcn = @app.resetViewButtonPushed;

            app.OutlineButton = uibutton(rightGrid, 'push');
            app.OutlineButton.Layout.Row = 1;
            app.OutlineButton.Layout.Column = 4;
            app.OutlineButton.Text = 'Outline';
            app.OutlineButton.Tooltip = 'Toggle merged building outline overlay';
            app.OutlineButton.Enable = 'off';
            app.OutlineButton.ButtonPushedFcn = @app.outlineButtonPushed;

            % Drawing axes
            app.UIAxes = uiaxes(rightGrid);
            app.UIAxes.Layout.Row = 2;
            app.UIAxes.Layout.Column = [1 4];
            app.UIAxes.ButtonDownFcn = @app.axesButtonDown;
            app.UIAxes.PickableParts = 'all';
            app.UIAxes.HitTest = 'on';

            % Listen for axes limit changes (pan, scroll-zoom) to update grid
            app.AxesLimitsListener = [ ...
                addlistener(app.UIAxes, 'XLim', 'PostSet', @(~,~) app.configureGrid()); ...
                addlistener(app.UIAxes, 'YLim', 'PostSet', @(~,~) app.configureGrid())];

        end

    end

    %% ===================================================================
    %  PUBLIC INTERFACE
    %  ===================================================================
    methods (Access = public)

        function app = FloorPlanBuilderApp
            % FloorPlanBuilderApp - Constructor
            %   Creates the app window, registers with MATLAB, runs startup.
            createComponents(app);
            registerApp(app, app.UIFigure);
            startupFcn(app);

            if nargout == 0
                clear app
            end
        end

        function delete(app)
            % delete - Clean up figure on app destruction
            delete(app.UIFigure);
        end

    end
end
