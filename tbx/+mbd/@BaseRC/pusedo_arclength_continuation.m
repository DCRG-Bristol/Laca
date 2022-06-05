function res = pusedo_arclength_continuation(obj,Ui,params,p_idx,p_lim,p_dir,arc_lim,arclength_ic,Nmax,...
    p_names,RunStability,StopOnStability)
%CONTINUATION Summary of this function goes here
%   Detailed explanation goes here
ps = zeros(1,Nmax);
ps(1) = params(p_idx);
N = size(Ui,1);
Us = zeros(N,Nmax);
res = struct();

% get initial position
ps(1) = params(p_idx);
obj.set_parameters(params);
[Us(:,1),deriv] = find_equilibrium(obj,Ui,0);
if sum(abs(deriv))>1e-3
    error('could not find initial equilibirum position')
end
res = save_res(obj,res,1,Us(:,1),params,p_names,RunStability);
res(1).Equilbrium =  sum(abs(deriv))<1e-3;
i = 2;
isError = false;
while i<=Nmax && all(params(p_idx)<p_lim(:,2)') && all(params(p_idx)>p_lim(:,1)')
    if i == 2
        grad =  [zeros(N,1);p_dir];
        arc = norm(grad);
        grad = grad./arc;
        arc = arclength_ic/2;
    else
        grad = [Us(:,i-1)-Us(:,i-2);ps(:,i-1)-ps(:,i-2)];
        arc = norm(grad);
        grad = grad./arc;
    end
    Niter = 1;
    arc = arc*2;
    deriv = inf;
    err = inf;
    new_arc = inf;
    while err > arc_lim(1)*0.3 || new_arc > arc_lim(2) || sum(abs(deriv))>1e-3
        if Niter > 100
            isError = true;
            break;
        elseif Niter > 1
            arc = max(arc*0.5,arc_lim(1));
            if new_arc <= arc_lim(1)
                isError = true;
                break;
            end
        end
        stepsize =  arc.*grad;
        ps(:,i) = ps(:,i-1) + stepsize(N+1:end);
        params(p_idx) = ps(:,i);
        obj.set_parameters(params);
        Ui = Us(:,i-1) + stepsize(1:N);
        [Us(:,i),deriv] = find_equilibrium(obj,Ui,0);
        grad = [Us(:,i)-Us(:,i-1);ps(:,i)-ps(:,i-1)];
        new_arc = norm(grad);
        err =  norm(Us(:,i) - Ui);
        Niter = Niter + 1;
    end   
    if isError
        res(i-1).isEnd = isError;
        break;
    end
    res = save_res(obj,res,i,Us(:,i),params,p_names,RunStability);
    res(i).Equilbrium =  sum(abs(deriv))<1e-3;
    res(i).isEnd = false;
    if RunStability && StopOnStability && ~res(i).Stable
        break
    end
    i = i+1;
end
end

function [U,deriv] = find_equilibrium(obj,Ui,t)
    [U,deriv] = obj.find_equilibrium(Ui,t);
end

% function [U,deriv] = find_equilibrium(obj,U,t)
% f = @(x)obj.deriv(t,x);
% n = numel(U);
% error = 1e-4;                           %tolerance
% newitr = 100;                           %maximum itration of Newton
% h = 1e-4;                               % acobian increment
% for i = 1:newitr                    %Newton for first point
%     deriv = f(U);
%     Jac = jac(f,deriv,U,h);
%     if norm(deriv) <= error, break; end
%     U = U-Jac\deriv;  %X for first point
% end
% end

function deriv = param_deriv(obj,Ui,params,p_idx)
    params(p_idx) = Ui(end-(nnz(p_idx)+1):end);
    obj.set_parameters(params);
    deriv = obj.deriv(0,Ui(1:end-nnz(p_idx)));
end

function Jac = jac(f,Fx,X,h)
n = numel(X);
Jac = zeros(numel(Fx),n);
for j = 1:n                             %jacobian
    Xh = X; Xh(j) = Xh(j)+h;
    Jac(:,j) = (feval(f,Xh)-Fx)/h;      %forward finite difference
end
end

function res = save_res(obj,res,i,U,params,p_names,RunStability)
    for j = 1:length(params)
        res(i).(p_names(j)) = params(j);
    end
    res(i).params = params;
    res(i).U = U;
    if RunStability
        evs = obj.get_stability(res(i).U,0);
        res(i).evs =  unique(complex(real(evs),abs(imag(evs))));
        res(i).Stable = ~any(real(evs)>1e-2);
    end
end

