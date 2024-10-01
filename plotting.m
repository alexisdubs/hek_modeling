
object = dataProcessing('..\mick_data\data_clean.xlsx');
dataPlotting(object)
dataPlottingAll(object)



function dataPlotting(obj)
    % plot things on subplots 
    % just plot mean and std dev
    % input is dataProcessing object
    time = 0:obj.numTimepoints-1;
    figure
    for i = 1:obj.numVar
        subplot(2,3,i)
        stdDev = sqrt(obj.varAll{i});
        errorbar(time, obj.data(i,:), stdDev, Marker=".", MarkerSize=10, LineStyle='none')
        title(strcat(obj.varNames{i},' [', obj.units.(obj.varNames{i}), ']'))
    end
end

function dataPlottingAll(obj)
    % plot things on subplots
    % plot all datapoints
    % input is dataProcessing object
    time = 0:obj.numTimepoints-1;
    figure
    for i = 1:obj.numVar
        subplot(2,3,i)
        plot(time, obj.dataAll{i}', Marker=".", MarkerSize=10, LineStyle='none', Color='#0072BD')
        title(strcat(obj.varNames{i},' [', obj.units.(obj.varNames{i}), ']'))
    end
end