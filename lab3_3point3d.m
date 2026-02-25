clc; clear all; close all;
% changed to matrix cause didn’t know how to use table

% import our data
data = readmatrix('2025_003_3d_updated');
data = data(2:length(data), :);     % Getting rid of first line

time = data(:, 1) .* 1e-3; % convert to secs
time = time - time(1);	% Center the data so it starts @ 0s

thetaRef = data(:,2);
thetaMeas = data(:,3);
settleBand = 0.05;
settleTime = 1.5;
maxOvershoot = 0.10;
finalVal = norm(thetaRef)

% lines for limits
upperBand = finalVal * (1 + settleBand)
lowerBand = finalVal * (1 - settleBand)
overshootLine = finalVal * (1 + maxOvershoot);

% plot
figure;
plot(time, thetaRef, 'r', 'LineWidth', 1.5, "Color", "Blue");
hold on;
plot(time, thetaMeas, 'LineWidth', 1.5, "Color", "Red")

% add guide lines
yline(upperBand, '--g', '+5%', 'LabelHorizontalAlignment', 'right');
yline(lowerBand, '--g', '-5%', 'LabelHorizontalAlignment', 'right');
yline(overshootLine, '--b', '+10% Overshoot', 'LabelHorizontalAlignment', 'left');
xline(settleTime, '--m', '1.5 s', 'LabelHorizontalAlignment', 'center');
xlabel('Time (s)');
ylabel('Theta (rad)')
title('Test Feedback Gains')
legend('Reference','Measured','Location','best');
grid on;
