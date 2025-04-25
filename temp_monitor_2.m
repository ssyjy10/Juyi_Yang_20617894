% Juyi Yang
% ssyjy10@nottingham.edu.cn
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