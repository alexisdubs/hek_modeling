clear; close all

%% Data processing
num_var = 3;
num_sample = 8;

% read in data
data_raw = cell(num_var,1);

data_raw{1} = readtable('..\paganini_data\vcd.csv'); % cells/mL
data_raw{1}{:,2} = data_raw{1}{:,2}./1e6; % 1e6 cells/mL
data_raw{2} = readtable('..\paganini_data\glucose.csv'); % mM
data_raw{3} = readtable('..\paganini_data\lactate.csv'); % mM
% data_raw{3} = readtable('paganini_data\evs.csv'); % AU

% calculate the variances for each data point
var_all = cell(num_var,1);
mid = cell(num_var,1);
var = zeros(num_var,1);
for i=1:num_var
    j=0:(num_sample-1);
    % mean
    mid{i} = data_raw{i}{3*j+1,2};
    % std dev high
    high = data_raw{i}{3*j+2,2};
    % std dev low
    low = data_raw{i}{3*j+3,2};
    % calculate std dev
    stddev = (high - low)./2;
    % square to get variance
    var_all{i} = stddev.^2;
    % take average of variance
    var(i) = mean(var_all{i});
end

% put in covariance matrix
cov = diag(var);

% put all the data in one matrix
data = zeros(num_sample,num_var);
for i = 1:num_sample
    for j = 1:num_var
        data(i,j) = mid{j}(i);
    end
end

% calculate time
times = zeros(num_sample, num_var);
for i=1:num_var
    for j=1:num_sample
        % avg 3 times for each data point
        times(j, i) = max([0, mean(data_raw{i}{3*j-2:3*j, 1})]);
    end
end
% average time from each variable
data_time = mean(times, 2);

%% Parameter Fitting

% ranges for parameters
bounds.mu = [0.02 0.04];
bounds.k = [1e-3 25];
bounds.y = [1e-3 0.05];
%bounds.m = [0 0];
lb = [bounds.mu(1) bounds.k(1) bounds.k(1) bounds.y(1) bounds.y(1)];
ub = [bounds.mu(2) bounds.k(2) bounds.k(2) bounds.y(2) bounds.y(2)];
%lb = [0.02 1e-3 1e-3];
%ub = [0.04 25 0.5];

% create array of guesses
num_param = 5;
num_guess = 3;
total_guesses = num_guess^num_param;
guesses = zeros(num_guess, num_param);
for i = 1:num_param
    guesses(:,i) = linspace(lb(i), ub(i), num_guess);
end

% initialize results arrays
fvals = zeros(num_guess, num_guess, num_guess);
count = 0;
param_fit_log = cell(num_guess, num_guess, num_guess);

% set up problem
problem.solver = 'fmincon';
problem.options = optimoptions('fmincon', StepTolerance=eps, Display='none');
problem.objective = @(params) obj_fun(data_time, data, cov, params, @cell_model_noP);
problem.lb = log(lb);
problem.ub = log(ub);

% solve problem for each of the initial guesses
for i = 1:num_guess
    for j = 1:num_guess
        for k = 1:num_guess
            param_guess = log([guesses(i,1), guesses(j, 2), guesses(k, 3)]);
            problem.x0 = param_guess;
            [param_fit_log{i, j, k}, fvals(i, j, k)] = fmincon(problem);
            count = count+1;
            if mod(count, num_guess) == 0
                fprintf('Iteration %d of %d\n', count, total_guesses)
            end
        end
    end
end

% find parameters that correspond to smallest objective function eval
fvals_stack = fvals(:);
param_fit_log_stack = param_fit_log(:);
[~, index] = min(fvals_stack);
params_log_opt = param_fit_log_stack{index};
params_opt = exp(params_log_opt)
% plot objective function values
figure
bar(sort(fvals_stack))
ylabel('Objective Function Value')

% plot
% solve model
tspan = [0, num_sample-1]; %days
tspan = 24*tspan; %hours
[t, y] = ode23(@(t,x) cell_model(t, x, params_log_opt), tspan, data(1,:));
colors = [0 0.4470 0.7410;
        0.8500 0.3250 0.0980];
titles = {'VCD (1e6 cells/mL)', 'Glucose (mM)'};
figure
for i=1:num_var
    subplot(2,1,i)
    plot(t./24, y(:,i), Color=colors(i,:))
    hold on
    plot(data_time, data(:,i), LineStyle="none", Marker=".", MarkerSize=10, Color=colors(i,:))
    ylabel(titles{i})
    xlabel('Days')
end

%% Functions
function out = obj_fun(t, y, cov, params, model)
% run ode  
y0 = y(1,:);
tspan = t; %days
tspan = 24*tspan; %hours

try
    warning('off', 'all')
    %options = odeset(Events=@events);
    options = odeset('NonNegative', 1:length(y0));
    [~,y_pred] = ode15s(@(t,x) model(t, x, params), tspan, y0, options);
    warning('on', 'all')
    out = 0;
    for i = 2:(size(y,1)-1)
        residual = y(i,:) - y_pred(i,:);
        out = out + residual*(eye(size(y,2))/cov)*residual';
    end
catch exception
    % disp(['Ojective Function Error: ', exception.message])
    % return infinity if something went wrong with simulation
    out = 1e2;
end

    function [value, isterminal, direction] = events(t, y)
    % Event function to stop integration when any state is non-positive
    value = y; % Detect when y crosses zero
    isterminal = 1; % Stop the integration
    direction = -1; % Negative direction only
    end

end