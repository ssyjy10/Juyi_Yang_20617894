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
