% Juyi Yang
% ssyjy10@nottingham.edu.cn
function temp_prediction(arduino)
% TEMP_PREDICTION Monitors temperature, predicts future values, and controls LEDs based on rate of change.
% TEMP_PREDICTION(ARDUINO) continuously reads temperature data from an Arduino-connected sensor,
% calculates the rate of temperature change, predicts the temperature 5 minutes ahead,
% and controls LEDs to indicate stability or rapid temperature changes.

% Inputs:
%   arduino: Arduino object connected to the hardware.

% LED Configuration:
%   - D2: Green LED (stable within comfort range: 18-24°C and |rate| <4°C/min)
%   - D3: Yellow LED (cooling rate ≤-4°C/min)
%   - D4: Red LED (heating rate ≥4°C/min)

% Example:
%   a = arduino('COM4', 'Uno');
%   temp_prediction(a);

% Initialize variables
start_time = tic; % Initialize timer
time_stamps = [];
temperatures = [];
max_history = 60;

while true
    current_time = toc(start_time); % Get elapsed time
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
            writeDigitalPin(arduino, 'D4', 0); % All LEDs off
        end
    else
        fprintf('Collecting data...\n'); % Waiting for enough data
    end

    pause(1);
end
end