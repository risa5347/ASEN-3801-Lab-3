%% design_PD_gains.m
% Design PD gains K1 and K2 for spacecraft pointing (ASEN lab)
% Requirements: 5% settling time < 1.5 s, overshoot < 10%
% Uses uploaded file named like "2025_003_3d_updated*"
clear; close all; clc;

%% 1) Try to locate/load the uploaded data file
fname_list = dir('2025_003_3d_updated');
I = []; file_used = '';
if ~isempty(fname_list)
    % pick first matching file
    fname = fname_list(1).name;
    file_used = fname;
    fprintf('Found file: %s\n', fname);
    [~,~,ext] = fileparts(fname);
    try
        switch lower(ext)
            case '.mat'
                data = load(fname);
                % attempt common variable names
                candidates = {'I','I_sc','Is','I_spacecraft','I_sc_measured','I_meas','I_sc_kgm2'};
                for k=1:length(candidates)
                    name = candidates{k};
                    if isfield(data,name)
                        I = data.(name);
                        fprintf('Using variable "%s" from %s as I (kg*m^2).\n', name, fname);
                        break;
                    end
                end
                % if still empty, try to find any scalar variable that looks like inertia
                if isempty(I)
                    vars = fieldnames(data);
                    for k=1:length(vars)
                        val = data.(vars{k});
                        if isscalar(val) && isnumeric(val)
                            % Heuristic: inertia typically ~1e-4..1e1 ; we won't filter too strictly
                            I = val;
                            fprintf('No named inertia found; using scalar variable "%s" from file as I.\n', vars{k});
                            break;
                        end
                    end
                end
            case {'.csv','.txt'}
                T = readtable(fname);
                % look for column names
                colNames = T.Properties.VariableNames;
                candidates = {'I','I_sc','I_meas','I_spacecraft','I_kgm2','moment_of_inertia','MOI'};
                found = false;
                for k=1:length(candidates)
                    if any(strcmpi(colNames,candidates{k}))
                        I = T{:,candidates{k}};
                        if isvector(I), I = I(1); end
                        fprintf('Using column "%s" from %s as I (kg*m^2).\n', candidates{k}, fname);
                        found = true; break;
                    end
                end
                if ~found
                    % try numeric columns: take first scalar entry from first numeric column
                    numericCols = varfun(@isnumeric, T, 'OutputFormat','uniform');
                    if any(numericCols)
                        cidx = find(numericCols,1,'first');
                        col = T{:,cidx};
                        if isvector(col)
                            I = col(1);
                            fprintf('No inertia column found; using first numeric column value as I.\n');
                        end
                    end
                end
            otherwise
                fprintf('Unknown extension "%s". Will prompt for I if not found.\n', ext);
        end
    catch ME
        warning('Error loading file: %s\nWill prompt for I. Error: %s', fname, ME.message);
        I = [];
    end
else
    fprintf('No file named "2025_003_3d_updated*" found in current folder.\n');
end

%% 2) If I not found, prompt the user (safe fallback)
if isempty(I)
    fprintf(['Could not automatically find I (moment of inertia) in the file.\n'...
             'Please enter measured spacecraft moment of inertia I (in kg*m^2).\n']);
    I = input('I (kg*m^2) = ');
    if isempty(I) || ~isnumeric(I) || I<=0
        error('Valid positive I required to proceed.');
    end
else
    % If I was read as an array, make it scalar by taking mean
    if ~isscalar(I)
        I = mean(I(:));
        fprintf('Using mean value I = %.6g kg*m^2\n', I);
    end
end

%% 3) Design specs -> compute required damping ratio and natural frequency
Mp_req = 0.10;     % maximum overshoot (10%)
ts_req = 1.5;      % settling time (5%) < 1.5 s

% Closed-form for zeta from percent overshoot
% Mp = exp(-pi*zeta / sqrt(1-zeta^2))  => zeta = -ln(Mp)/sqrt(pi^2 + ln(Mp)^2)
zeta_min = -log(Mp_req) / sqrt(pi^2 + (log(Mp_req))^2);

% Use slight margin on damping (optional)
zeta = zeta_min + 0.01; % small margin to be conservative

% 5% settling time approx ts = 3/(zeta*omega_n) -> omega_n > 3/(zeta*ts_req)
omega_n_min = 3/(zeta*ts_req); 
% The developer message used 3/(zeta*omega_n) for ts(5%) -> consistent.
% For a minimum design choose omega_n = omega_n_min (could add margin)
omega_n = omega_n_min;

% Compute K1 and K2 in terms of I
K1 = I * omega_n^2;                 % N*m / rad
K2 = 2 * zeta * omega_n * I;        % N*m / (rad/s)

% Poles
sigma = -zeta*omega_n;
omega_d = omega_n * sqrt(max(0,1-zeta^2));
p1 = sigma + 1i*omega_d;
p2 = sigma - 1i*omega_d;

%% 4) Display results (symbolic formula + numeric)
fprintf('\nDesign results (numeric):\n');
fprintf('Measured I = %.6g kg*m^2\n', I);
fprintf('Required max overshoot = %.1f%% -> min damping zeta_min = %.4f\n', Mp_req*100, zeta_min);
fprintf('Using zeta (with small margin) = %.4f\n', zeta);
fprintf('To meet ts(5%%) < %.2f s: chosen omega_n = %.4f rad/s (minimum).\n', ts_req, omega_n);
fprintf('Natural frequency omega_n = %.4f rad/s\n', omega_n);
fprintf('Damped freq omega_d = %.4f rad/s\n', omega_d);
fprintf('Closed-loop poles: p1 = %.4f %+.4fj, p2 = %.4f %+.4fj (rad/s)\n', real(p1), imag(p1), real(p2), imag(p2));
fprintf('Gains (numeric): K1 = I*omega_n^2 = %.6g N*m/rad\n', K1);
fprintf('              K2 = 2*zeta*omega_n*I = %.6g N*m/(rad/s)\n\n', K2);

% Also print formulas
fprintf('Symbolic formulas used:\n');
fprintf('  Characteristic: s^2 + (K2/I) s + (K1/I) = 0\n');
fprintf('  => omega_n = sqrt(K1/I),  zeta = K2/(2*I*omega_n)\n');
fprintf('  => K1 = I * omega_n^2,   K2 = 2 * zeta * omega_n * I\n\n');

%% 5) Plots: poles and step response of corresponding 2nd-order model
figure('Name','Poles in s-plane','NumberTitle','off');
plot(real(p1), imag(p1),'x','MarkerSize',10,'LineWidth',2); hold on;
plot(real(p2), imag(p2),'x','MarkerSize',10,'LineWidth',2);
plot([-5*omega_n 1],[0 0],'k:'); % real axis ref
xlabel('Real (rad/s)'); ylabel('Imag (rad/s)'); grid on;
title('Closed-loop poles'); legend('p1','p2');

% step response: model theta_ref -> theta (2nd-order TF)
sys = tf(omega_n^2, [1 2*zeta*omega_n omega_n^2]);
figure('Name','Step response (closed-loop 2nd-order)','NumberTitle','off');
step(sys, 0:0.001:5); % 0 to 5 seconds
title(sprintf('Step response: \\zeta=%.3f, \\omega_n=%.3f rad/s, ts(5%%)≈%.2fs', zeta, omega_n, 3/(zeta*omega_n)));
grid on;

%% 6) Quick check: compute theoretical Mp and ts(5%)
Mp_theor = exp(-pi*zeta/sqrt(1-zeta^2));
ts_theor = 3/(zeta*omega_n);
fprintf('Theoretical Mp = %.3f (%.2f%%), ts(5%%) = %.3f s\n', Mp_theor, Mp_theor*100, ts_theor);

%% 7) Save design results to file
out.name = 'PD_design_results.mat';
out.I = I; out.zeta = zeta; out.omega_n = omega_n;
out.K1 = K1; out.K2 = K2; out.poles = [p1 p2];
save(out.name,'-struct','out');
fprintf('Design results saved to %s\n', out.name);
