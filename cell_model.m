function dxdt = cell_model(t, x, params_log)
% cell culture model
% t - time
% x - differential states
% u - inputs
% params - model parameters

% unpack states
X = x(1);
gluc = x(2);
lac = x(3);

% unpack parameters
params = exp(params_log);
mu_max = params(1);
ks = params(2:3);
y = params(4:5);
m = params(6:7);

% model
qs = zeros(2,1);
mu = mu_max * gluc/(ks(1)+gluc) * lac/(ks(2) +lac);
for i = 1:2
    qs(i) = -mu/y(i) - m(i);
end

dXdt = mu*X;
dglucdt = -qs(1)*X;
dlacdt = -qs(2)*X;

dxdt = [dXdt; dglucdt; dlacdt];
end
