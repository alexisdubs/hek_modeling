classdef dataProcessing < handle
%Class to read in and process data

properties
    path
    dataAll
    variances
    varAll
    cov
    varNames
    numVar
    numTimepoints
    data
    units = struct('cells', 'cells/mL', 'particles', 'particles/mL', 'glucose', 'g/L',...
        'lactate', 'g/L', 'ammonium', 'mM', 'glutamate', 'mM', 'glutamine', 'mM');
end

methods
    function obj = dataProcessing(filepath)
        %Construct an instance of this class
        %   input is filepath to file with data
        % read in the data at this filepath, calculate the means,
        % calculate the variances
        obj.path = filepath;
        obj.readData();
        obj.calcMeans();
        obj.calcVar();
        obj.setCov();
    end

    function obj = readData(obj)
        %read in data
        filePath = obj.path;
        % Get the names of all sheets in the Excel file
        [~, sheetNames] = xlsfinfo(filePath);  % Returns the sheet names
        
        % store number and name of variables
        numVar = numel(sheetNames);
        varNames = sheetNames;

        % Initialize an empty cell array to hold the data
        dataCell = cell(numVar, 1);
        
        % Loop through each sheet and read the data
        for i = 1:numVar
            % Read data from each sheet into a table
            sheetData = readtable(filePath, 'Sheet', sheetNames{i});
            
            % convert to array and place in cell array
            dataCell{i} = table2array(sheetData);
        end
        
        % assign data to object property data
        obj.dataAll = dataCell;
        obj.numVar = numVar;
        obj.varNames = varNames;
        obj.numTimepoints = size(dataCell{1},2);
    end

    function obj = calcVar(obj)
        % calculate the variance for the data
        variances = zeros(obj.numVar,1);
        varAll = cell(obj.numVar, 1);
        % loop through each data array
        for i = 1:obj.numVar
            dataTemp = obj.dataAll{i};
            % calculate variance of each column
            varAll{i} = var(dataTemp, 'omitmissing');
            % calculate number of samples in each column - 1
            numSamples = sum(~isnan(dataTemp))-1;
            % calculated weighted average of the variance (based on
            % number of samples in each datapoint
            variances(i) = (numSamples*varAll{i}')/sum(numSamples);
        end
        obj.variances = variances;
        obj.varAll = varAll;
    end

    function obj = setCov(obj)
        % place the variances of each variable in a covariance matrix
        covariance = zeros(obj.numVar);
        for i = 1:obj.numVar
            covariance(i,i) = obj.variances(i);
        end
        obj.cov = covariance;
    end
    
    function obj = calcMeans(obj)
        % calculate the mean of each variable at each timepoint and put
        % it all in one array
        % each row is a variable, each column is a timepoint
        dataMean = zeros(obj.numVar, obj.numTimepoints);
        for i = 1:obj.numVar
            dataMean(i,:) = mean(obj.dataAll{i}, 'omitmissing');
        end
        obj.data = dataMean;
    end



end
end