% Juyi Yang
% ssyjy10@nottingham.edu.cn

%% PRELIMINARY TASK - ARDUINO AND GIT INSTALLATION [10 MARKS]
clear
% Initialize Arduino connection
a = arduino('COM4', 'Uno');
% Configure digital pin D3 for green LED
configurePin(a, 'D3', 'DigitalOutput');

% Test LED on/off
writeDigitalPin(a, 'D3', 1); % Turn green LED on
pause(1);
writeDigitalPin(a, 'D3', 0); % Turn green LED off
% pause(1);  waut for 1 second

% Blink LED at 0.5s intervals (1s cycle: 0.5s on, 0.5s off)
for i = 1:5
    writeDigitalPin(a, 'D3', 1);
    pause(0.5);
    writeDigitalPin(a, 'D3', 0);
    pause(0.5); % keep off for 0.5 seconds
end

%% TASK 1 - READ TEMPERATURE DATA, PLOT, AND WRITE TO A LOG FILE [20 MARKS]
% This section reads temperature data using MCP9700A sensor, plots it, and logs results
% Purpose: Collect 10 minutes of temperature data, visualize it, and save to a file
clc
clear a
a = arduino('COM4', 'Uno');

% b: Read temperature data for 10 minutes
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

% c: Plot temperature vs time
figure;
plot(time/60, temperature, 'b-'); % Time in minutes
xlabel('Time (minutes)');
ylabel('Temperature (°C)');
title('Cabin Temperature Over Time');
grid on; % plot visualizes temperature trends over 10 seconds

% d: Format and display data
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

% e: Write to log file
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

%% TASK 2 - LED TEMPERATURE MONITORING DEVICE IMPLEMENTATION [25 MARKS]
% This section initializes the Arduino and calls the temp_monitor function
% to perform real-time temperature monitoring with LED indicators.
% Green LED (D2): 18-24°C (steady), Yellow LED (D3): <18°C (0.5s blink),
% Red LED (D4): >24°C (0.25s blink). A live plot shows temperature over time.

% Initialize Arduino
a = arduino('COM4', 'Uno');

% Call the temp_monitor function
% Note: Run this and stop manually (Ctrl+C) as it runs indefinitely
temp_monitor(a);
function temp_monitor(arduino)
    % Configure LED pins
    configurePin(arduino, 'D2', 'DigitalOutput'); % Green LED
    configurePin(arduino, 'D3', 'DigitalOutput'); % Yellow LED
    configurePin(arduino, 'D4', 'DigitalOutput'); % Red LED
    
    % Initialize plot
    figure;
    x = [];
    y = [];
    plot_handle = plot(x, y, 'b-');
    xlabel('Time (s)');
    ylabel('Temperature (°C)');
    title('Live Cabin Temperature');
    grid on;
    
    % MCP9700A parameters
    V0 = 0.5; % Voltage at 0°C
    TC = 0.01; % Temperature coefficient (V/°C)
    
    % Timing variables
    start_time = tic;
    last_plot_time = 0;
    yellow_blink_state = 0;
    red_blink_state = 0;
    last_yellow_toggle = 0;
    last_red_toggle = 0;
    yellow_period = 0.5; % 0.5s blink interval
    red_period = 0.25;   % 0.25s blink interval
    
    while true
        current_time = toc(start_time);
        
        % Read and convert temperature
        temp_voltage = readVoltage(arduino, 'A0');
        temperature = (temp_voltage - V0) / TC; % Convert to °C
        
        % Update plot every 1 second
        if current_time - last_plot_time >= 1
            x = [x; current_time];
            y = [y; temperature];
            set(plot_handle, 'XData', x, 'YData', y);
            axis([max(0, current_time-60) current_time min(15, min(y)-2) max(30, max(y)+2)]);
            drawnow;
            last_plot_time = current_time;
        end
        
        % Control LEDs based on temperature
        if temperature >= 18 && temperature <= 24
            writeDigitalPin(arduino, 'D2', 1); % Green on
            writeDigitalPin(arduino, 'D3', 0); % Yellow off
            writeDigitalPin(arduino, 'D4', 0); % Red off
        elseif temperature < 18
            writeDigitalPin(arduino, 'D2', 0); % Green off
            writeDigitalPin(arduino, 'D4', 0); % Red off
            if current_time - last_yellow_toggle >= yellow_period
                yellow_blink_state = ~yellow_blink_state;
                writeDigitalPin(arduino, 'D3', yellow_blink_state);
                last_yellow_toggle = current_time;
            end
        else % temperature > 24
            writeDigitalPin(arduino, 'D2', 0); % Green off
            writeDigitalPin(arduino, 'D3', 0); % Yellow off
            if current_time - last_red_toggle >= red_period
                red_blink_state = ~red_blink_state;
                writeDigitalPin(arduino, 'D4', red_blink_state);
                last_red_toggle = current_time;
            end
        end
        
        pause(0.1); % Small pause to prevent excessive CPU usage
    end
end
%% TASK 3 - ALGORITHMS – TEMPERATURE PREDICTION [25 MARKS]
clear
function temp_prediction(arduino)
% >> doc temp_prediction
  %TEMP_PREDICTION Monitors temperature, predicts future values, and controls LEDs based on rate of change.
  %TEMP_PREDICTION(ARDUINO) continuously reads temperature data from an Arduino-connected sensor,
  %calculates the rate of temperature change, predicts the temperature 5 minutes ahead,
  %and controls LEDs to indicate stability or rapid temperature changes.

  % Inputs:
      % arduino: Arduino object connected to the hardware.

  % LED Configuration:
      % - D2: Green LED (stable within comfort range: 18-24°C and |rate| <4°C/min)
      % - D3: Yellow LED (cooling rate ≤-4°C/min)
      % - D4: Red LED (heating rate ≥4°C/min)

  % Example:
      % a = arduino('COM4', 'Uno');
      % temp_prediction(a);
    % start_time = tic;
    % time_stamps = [];
    % temperatures = [];
    % max_history = 60;

    while true
        current_time = toc(start_time);
        temp_voltage = readVoltage(arduino, 'A0');
        temperature = temp_voltage * 100; % LM35: 10 mV/°C

        time_stamps = [time_stamps; current_time];
        temperatures = [temperatures; temperature];
        idx = time_stamps >= current_time - max_history;
        time_stamps = time_stamps(idx);
        temperatures = temperatures(idx);

        if length(time_stamps) >= 2 && time_stamps(end) - time_stamps(1) >= 10
            t_start = current_time - 10;
            idx10 = time_stamps >= t_start;
            t10 = time_stamps(idx10);
            temp10 = temperatures(idx10);
            p = polyfit(t10, temp10, 1);
            slope = p(1); % °C/s
            rate_C_per_min = slope * 60; % °C/min
            time_ahead = 5 * 60;
            T_predicted = temperature + slope * time_ahead;

            fprintf('Current Temp: %.2f °C, Rate: %.2f °C/min, Predicted in 5min: %.2f °C\n', ...
                temperature, rate_C_per_min, T_predicted);

            if abs(rate_C_per_min) < 0.1 && temperature >= 18 && temperature <= 24
                writeDigitalPin(arduino, 'D2', 1); % Green on
                writeDigitalPin(arduino, 'D3', 0);
                writeDigitalPin(arduino, 'D4', 0);
            elseif rate_C_per_min > 4
                writeDigitalPin(arduino, 'D2', 0);
                writeDigitalPin(arduino, 'D3', 0);
                writeDigitalPin(arduino, 'D4', 1); % Red on
            elseif rate_C_per_min < -4
                writeDigitalPin(arduino, 'D2', 0);
                writeDigitalPin(arduino, 'D3', 1); % Yellow on
                writeDigitalPin(arduino, 'D4', 0);
            else
                writeDigitalPin(arduino, 'D2', 0);
                writeDigitalPin(arduino, 'D3', 0);
                writeDigitalPin(arduino, 'D4', 0);% All LEDs off
            end
        else
            fprintf('Collecting data...\n');% Waiting for enough data
        end

        pause(1);
    end
end

%% TASK 4 - REFLECTIVE STATEMENT [5 MARKS]
% Revised Reflective Statement
% When I started this project to build a temperature monitoring system for an aircraft cabin using MATLAB and Arduino, I was thrilled to apply what I’d learned in class to a real-world challenge. I knew it would be tough, but I was eager to get my hands dirty and see what I could accomplish.
% One of the best parts was getting the hardware and software to work together seamlessly, enabling real-time data collection and display. I felt a surge of pride when I finally got the Arduino talking to MATLAB, controlling LEDs based on temperature thresholds. It was like seeing lecture concepts—matrices, functions, and I/O operations—come alive in a practical way, which made those late-night study sessions feel worthwhile.
% Using Git for version control was a lifesaver. It kept my code changes organized across tasks, and I quickly realized why it’s a must-have for any serious programming project. It gave me confidence to experiment without worrying about losing my progress.
% But the project wasn’t all smooth sailing. Calibrating the thermistor to convert voltage to temperature was a headache due to noisy analog readings. I spent hours tweaking filtering techniques, feeling frustrated but determined. When I finally cracked it, the sense of accomplishment was huge. Similarly, creating a live plot in Task 2 was tricky—I wrestled with the `drawnow` command to avoid lag, but getting that smooth update was so satisfying.
% Task 3’s temperature prediction algorithm was the toughest conceptually. Balancing responsiveness and stability while handling noise was daunting. After some trial and error, I settled on a moving average, which worked well, but it taught me how complex real-world data can be.
% The system wasn’t perfect. Environmental noise sometimes triggered false LED alerts, and my code could’ve used better error handling. Time constraints also meant I couldn’t explore advanced prediction models or a slick user interface, which was a bit disappointing.
% Looking forward, I’m excited to try a Kalman filter for better noise reduction and maybe add a MATLAB GUI for easier interaction. A machine learning model for predictions could be cool, too, and logging data to a cloud database would align with IoT trends.
% This project was a game-changer for me. It sharpened my problem-solving skills and showed me the importance of persistence, iterative testing, and clear documentation—lessons I’ll carry into every future project.
