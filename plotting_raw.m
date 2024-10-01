
object = dataProcessing_raw('..\mick_data\cell_dens.xlsx', '..\mick_data\particles.xlsx', '..\mick_data\metabolize_subset.xlsx');
dataPlotting(object)


function dataPlotting(obj)
% plot each metabolite on it's own plot but make each n have it's own 
    time = 0:obj.numTimepoints-1;
    colors = {"#0072BD", "#D95319", "#EDB120"};
    for i  = 1:obj.numVar
        subplot(2,3,i)
        hold on
        for j = 1:obj.n
            plot(time, obj.dataAll{j,i}, Marker=".", MarkerSize=20, LineStyle='none', Color=colors{j})
        end
        title(strcat(obj.varNames{i},' [', obj.units.(obj.varNames{i}), ']'))
    end
end


