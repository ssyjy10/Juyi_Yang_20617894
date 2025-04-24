% Juyi Yang
% ssyjy10@nottingham.edu.cn

%% PRELIMINARY TASK - ARDUINO AND GIT INSTALLATION [10 MARKS]
clear
% Initialize Arduino connection
a = arduino('COM4', 'Uno');
% Configure digital pin D3 for green LED
configurePin(a, 'D3', 'DigitalOutput');

% Test LED on/off
writeDigitalPin(a, 'D3', 1); % Turn LED on
pause(1);
writeDigitalPin(a, 'D3', 0); % Turn LED off
pause(1);

% Blink LED at 0.5s intervals (1s cycle: 0.5s on, 0.5s off)
for i = 1:5
    writeDigitalPin(a, 'D3', 1);
    pause(0.5);
    writeDigitalPin(a, 'D3', 0);
    pause(0.5);
end

%% TASK 1 - READ TEMPERATURE DATA, PLOT, AND WRITE TO A LOG FILE [20 MARKS]
clc
clear a
a = arduino('COM4', 'Uno');
% Task 1a: Thermistor is connected to A0, 5V, GND (photo included in report)

% Task 1b: Read temperature data for 10 minutes
duration = 600; % 10 minutes in seconds
num_samples = duration; % One sample per second
time = (0:num_samples-1)'; % Time array in seconds
voltage = zeros(num_samples, 1); % Voltage array
temperature = zeros(num_samples, 1); % Temperature array

% MCP9700A parameters
V0 = 0.5; % Voltage at 0°C
TC = 0.01; % Temperature coefficient (V/°C)

% Read voltage and convert to temperature
for i = 1:num_samples
    voltage(i) = readVoltage(a, 'A0');
    temperature(i) = (voltage(i) - V0) / TC; % Convert to °C
    pause(1); % Wait 1 second
end

% Calculate statistics
min_temp = min(temperature);
max_temp = max(temperature);
avg_temp = mean(temperature);

% Task 1c: Plot temperature vs time
figure;
plot(time/60, temperature, 'b-'); % Time in minutes
xlabel('Time (minutes)');
ylabel('Temperature (°C)');
title('Cabin Temperature Over Time');
grid on;

% Task 1d: Format and display data
location = 'Aircraft Cabin';
current_date = datestr(now, 'dd/mm/yyyy');
fprintf('Cabin Temperature Log\n');
fprintf('Date: %s\n', current_date);
fprintf('Location: %s\n\n', location);
fprintf('Minute\tTemperature (°C)\n');
fprintf('------\t---------------\n');
for i = 1:10 % Display first 10 minutes
    fprintf('Minute %d\t%.2f\n\n', i-1, temperature(i*60));
end
fprintf('Statistics:\n');
fprintf('Minimum Temperature: %.2f °C\n', min_temp);
fprintf('Maximum Temperature: %.2f °C\n', max_temp);
fprintf('Average Temperature: %.2f °C\n', avg_temp);

% Task 1e: Write to log file
fileID = fopen('cabin_temperature.txt', 'w');
fprintf(fileID, 'Cabin Temperature Log\n');
fprintf(fileID, 'Date: %s\n', current_date);
fprintf(fileID, 'Location: %s\n\n', location);
fprintf(fileID, 'Minute\tTemperature (°C)\n');
fprintf(fileID, '------\t---------------\n');
for i = 1:10
    fprintf(fileID, 'Minute %d\t%.2f\n\n', i-1, temperature(i*60));
end
fprintf(fileID, 'Statistics:\n');
fprintf(fileID, 'Minimum Temperature: %.2f °C\n', min_temp);
fprintf(fileID, 'Maximum Temperature: %.2f °C\n', max_temp);
fprintf(fileID, 'Average Temperature: %.2f °C\n', avg_temp);
fclose(fileID);

% Verify file content
fileID = fopen('cabin_temperature.txt', 'r');
content = fread(fileID, '*char')';
fclose(fileID);
disp('File content verified:');
disp(content);

%% TASK 2 - LED TEMPERATURE MONITORING DEVICE IMPLEMENTATION [25 MARKS]
% Inputs:
%   a - Arduino object for communication
% Purpose: Continuously reads temperature from MCP9700A sensor, updates a live
% plot, and controls green (D3), yellow (D4), or red (D5) LEDs based on
% temperature range (18-24°C: green on, <18°C: yellow blink, >24°C: red blink).
% Usage: temp_monitor(a)
% Documentation: Run 'doc temp_monitor' for details.

function temp_monitor(a)
    % Initialize parameters
    V0 = 0.5; % MCP9700A voltage at 0°C
    TC = 0.01; % Temperature coefficient (V/°C)
    time = 0; % Current time in seconds
    temperatures = []; % Store temperature data
    times = []; % Store time data
    
    % Initialize live plot
    figure;
    h = plot(0, 0, 'b-');
    xlabel('Time (minutes)');
    ylabel('Temperature (°C)');
    title('Live Cabin Temperature');
    grid on;
    
    % Main loop
    while true
        % Read and convert temperature
        voltage = readVoltage(a, 'A0');
        temp = (voltage - V0) / TC;
        
        % Update data arrays
        time = time + 1;
        times = [times; time/60]; % Convert to minutes
        temperatures = [temperatures; temp];
        
        % Update plot
        set(h, 'XData', times, ' TrigYData', temperatures);
        xlim([max(0, time/60-10) time/60]); % Show last 10 minutes
        ylim([min(temperatures)-2 max(temperatures)+2]);
        drawnow;
        
        % Control LEDs based on temperature
        if temp >= 18 && temp <= 24
            % Green LED on
            writeDigitalPin(a, 'D3', 1);
            writeDigitalPin(a, 'D4', 0);
            writeDigitalPin(a, 'D5', 0);
        elseif temp < 18
            % Yellow LED blink at 0.5s intervals
            writeDigitalPin(a, 'D3', 0);
            writeDigitalPin(a, 'D4', 1);
            writeDigitalPin(a, 'D5', 0);
            pause(0.5);
            writeDigitalPin(a, 'D4', 0);
            pause(0.5);
        else % temp > 24
            % Red LED blink at 0.25s intervals
            writeDigitalPin(a, 'D3', 0);
            writeDigitalPin(a, 'D4', 0);
            writeDigitalPin(a, 'D5', 1);
            pause(0.25);
            writeDigitalPin(a, 'D5', 0);
            pause(0.25);
        end
    end
end
%% TASK 3 - ALGORITHMS – TEMPERATURE PREDICTION [25 MARKS]

function temp_prediction(a)
% TEMP_PREDICTION Monitors temperature and predicts future values.
%
%   TEMP_PREDICTION(A) uses the Arduino object A to read temperature from a
%   thermistor on pin A0, calculates the rate of change, predicts the
%   temperature in 5 minutes, and controls LEDs on D2 (green), D3 (yellow),
%   D4 (red). LEDs indicate:
%   - Green: rate between -4 and +4 °C/min
%   - Red: rate > +4 °C/min
%   - Yellow: rate < -4 °C/min

% Define pins
thermistor_pin='A0';
green_pin='D2';
yellow_pin='D3';
red_pin='D4';

% Configure LED pins
configurePin(a, green_pin, 'DigitalOutput');
configurePin(a, yellow_pin, 'DigitalOutput');
configurePin(a, red_pin, 'DigitalOutput');

% Initialize history
time_history=[];
temp_history=[];
N = 10; % points for rate calculation
start_time = tic;

while true
    % Read temperature
    voltage=readVoltage(a, thermistor_pin);
    current_temp=(voltage - 0.5) / 0.01;
    current_time=toc(start_time);
    
    % Append to history
    time_history=[time_history, current_time];
    temp_history=[temp_history, current_temp];
    
    % Calculate rate
    if length(time_history) >= 2
        idx=max(1, length(time_history)-N+1):length(time_history);
        p=polyfit(time_history(idx), temp_history(idx), 1);
        rate=p(1); % °C/s
        rate_min=rate*60; % °C/min
        temp_pred=current_temp+rate*300; % 5 min
        fprintf('Rate: %.4f °C/s, Current temperature: %.2f °C, Predicted in 5 min: %.2f °C\n', rate, current_temp, temp_pred);
        
        % Control LEDs
        if rate_min > 4
            writeDigitalPin(a, red_pin, 1);
            writeDigitalPin(a, green_pin, 0);
            writeDigitalPin(a, yellow_pin, 0);
        elseif rate_min<-4
            writeDigitalPin(a, yellow_pin, 1);
            writeDigitalPin(a, green_pin, 0);
            writeDigitalPin(a, red_pin, 0);
        else
            writeDigitalPin(a, green_pin, 1);
            writeDigitalPin(a, yellow_pin, 0);
            writeDigitalPin(a, red_pin, 0);
        end
    else
        writeDigitalPin(a, green_pin, 1);
        writeDigitalPin(a, yellow_pin, 0);
        writeDigitalPin(a, red_pin, 0);
    end
    
    pause(1);
end
end

%% TASK 4 - REFLECTIVE STATEMENT [5 MARKS]
%{
Write your 400-word reflective statement here, discussing:
- Challenges: e.g., timing LED blinks, noise in data.
- Strengths: e.g., robust plotting, clear LED indicators.
- Limitations: e.g., single sensor, simple prediction model.
- Improvements: e.g., multiple sensors, advanced algorithms.
%}

% Task 5: Commenting and Version Control
% Code is commented throughout. Ensure git commits for each task.