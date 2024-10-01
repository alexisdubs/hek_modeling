classdef dataProcessing_raw < handle
%Class to read in and process data

properties
    cellPath
    novaPath
    dataAll
    variances
    varAll
    cov
    varNames = {'cells', 'particles', 'glutamine', 'glucose', 'lactate', 'ammonium'}
    numVar
    numTimepoints
    data
    units = struct('cells', 'cells/mL', 'particles', 'particles/mL', 'glutamine', 'mM', ...
        'glucose', 'g/L', 'lactate', 'g/L', 'ammonium', 'mM');
    n
    cellData
    novaData
    particleData
    particlePath
end

methods
    function obj = dataProcessing_raw(cellPath, particlePath, novaPath)
        %Construct an instance of this class
        obj.cellPath = cellPath;
        obj.novaPath = novaPath;
        obj.particlePath = particlePath;
        obj.n = 3;
        obj.numTimepoints = 8;
        obj.numVar = 6;
        obj.readCellData();
        obj.readParticleData();
        obj.readNovaData();
        obj.combine();
    end
    
    function obj = combine(obj)
        %Combine the cell data and the nova data
        obj.dataAll = [obj.cellData, obj.particleData, obj.novaData(1:3,:)];
    end

    function obj = readParticleData(obj)
        %read in data
        filePath = obj.particlePath;
        % Get the names of all sheets in the Excel file
        [~, sheetNames] = xlsfinfo(filePath);  % Returns the sheet names

        % create cell array for data
        n = numel(sheetNames);

        particleData = cell(n,1);

        for i = 1:n
            sheetData = readmatrix(filePath, 'Sheet', sheetNames{i});
            particleData{i} = sheetData;
        end

        obj.particleData = particleData;
     end

    function obj = readCellData(obj)
        %read in data
        filePath = obj.cellPath;
        % Get the names of all sheets in the Excel file
        [~, sheetNames] = xlsfinfo(filePath);  % Returns the sheet names

        % create cell array for data
        n = numel(sheetNames);

        cellData = cell(n,1);

        for i = 1:n
            sheetData = readmatrix(filePath, 'Sheet', sheetNames{i});
            cellData{i} = sheetData;
        end

        obj.cellData = cellData;
     end

    function obj = readNovaData(obj)
        % read in data
        filePath = obj.novaPath;
        dataTable = readtable(filePath);
        
        % number of variables
        numVar = width(dataTable)-1;

        % create cell array to store everything
        data = cell(obj.n, numVar);
        data = cellfun(@(x) nan(0, obj.numTimepoints), data, UniformOutput=false);
        numRows = height(dataTable);
        for i = 1:numRows
            % Extract 'n' value
            n_match = regexp(dataTable{i,1}, 'day n(\d+)', 'tokens');
            n = str2double(n_match{1}{1});
            % Extract day value
            day_match = regexp(dataTable{i,1}, 'day (\d+)', 'tokens');
            day = str2double(day_match{1}{1});
            % place data for this row in correct spot in table
            for j = 1:numVar
                data{n, j}(end+1,day+1) = dataTable{i,j+1};
            end
        end
        % replace all 0s with nans
        for i = 1:obj.n
            for j = 1:numVar
                data{i,j}(data{i,j} == 0) = NaN;
            end
        end
        obj.novaData = data;

    end

end
end