% read dataset
dataset = readmatrix('2025_003_3d_updated');

% extract data

 % time in milli seconds
t_milli = dataset(:, 1);
 % time in seconds
t_s = t_milli / 1000;
% reference Position (theta_ref) [in rad]
ref_pos = dataset(:, 2);   
% measured Position (theta_meas, Rate Integrator Output) [rad]
meas_pos = dataset(:, 3);         
% actual Actuator Current [A]
act_current = dataset(:, 4);  
% proportional gain
Kp = dataset(:, 5);
% derivative gain
Kd = dataset(:, 6);
% integral gain
ki = dataset(:,7);

% calc angular position error
% angular Position Error (mean_pos - ref_pos) [rad]
error_pos = meas_pos - ref_pos;       

% plot 1 
% Time History of Reference and Measured Angular Position
figure();
plot(t_s, ref_pos, 'LineWidth', 2, 'DisplayName', 'Reference Position','LineStyle','--');
hold on;
plot(t_s, meas_pos, 'LineWidth', 2, 'DisplayName', 'Measured Position', 'LineStyle','-.');
xlabel('Time [s]');
ylabel('Angular Position [rad]');
title('Tracking of Reference Position vs. Measured Position)');
legend('Measured Position', 'Reference Position', 'best');
grid on;

% Plot 2
% Time History of Angular Position Error
figure();
plot(t_s, error_pos, 'LineWidth', 2);
xlabel('Time [s]');
ylabel('Angular Position Error [rad]');
title('Time History of Angular Position Error');
grid on;

% Plot 3 (Control Evaluation)
% Time History of Applied Actuator Current
figure();
plot(t_s, act_current, 'LineWidth', 2, 'Color', 'r', 'LineStyle','-');
xlabel('Time [s]');
ylabel('Actuator Current [A]');
title('Time History of Applied Actuator Current (Applied Reaction Wheel Torque)');
grid on;


% Plot 4 (tracking the error of angular position w.r.t reference position)
figure();
scatter(ref_pos, pos_error, 10, 'filled');
xlabel('Reference Position [rad]');
ylabel('Angular Position Error [rad]');
title('Tracking Angular Position Error vs. Reference Position');
xlim ([-0.05 0.55]);
grid on;