
%% ------------------------- Signal Generator 40 MHz ----------------------------------- %%
% Connect to the instrument
% ip = 'USB0::0xF4ED::0xEE3A::T0102C21090069::INSTR'; % Change with actual USB ID
% gen = TeledyneT3AFG(ip);
% gen.connect();
% 
% % Channel 1 configuration (Burst) for ultrasound transducers
% gen.setWaveform(1, 'SINE');
% gen.setFrequency(1, 40e6);       % 40 MHz
% gen.setAmplitude(1, 4);          % 4 Vpp
% gen.setPhase(1, 1);              % 1 degree
% gen.setOffset(1, 0);             % 0 V offset
% gen.setBurstCycles(1, 1);       % 1 cycles
% gen.setBurstPeriod(1, 0.02);     % 20 ms
% gen.setBurstSource(1, 'INT');    % Internal source
% %gen.outputOn(1);
% 
% % Channel 2 configuration (TTL trigger for RF switch)
% gen.setWaveform(2, 'PULSE');
% gen.setFrequency(2, 50);         % 50 Hz
% gen.setAmplitude(2, 5);          % 5 Vpp
% gen.setOffset(2, 2.5);           % 2.5 V offset
% gen.setPulseWidth(2, 3.6e-6);    % 3.6 µs
% gen.setRiseTime(2, 8.4e-9);      % 8.4 ns
% gen.setDelay(2, 0);              % 0 s delay
%% ------------------------- The Signal Generator with 100 MHz----------------------- %%
% Connect 
ip = 'USB0::0x1AB1::0x0647::DG5P272700184::0::INSTR'; 
gen = DG5000Pro(ip);
gen.connect();

%% Channel 1
gen.setWaveform(1, 'SINE');
gen.setImpedance(1, 50); 
gen.setFrequency(1, 25e6);       
gen.setAmplitude(1, 5);         
gen.setPhase(1, 0);              
gen.setOffset(1, 0);             

gen.setBurstState(1, 'ON');      
gen.setBurstCycles(1, 7);        % cycle
gen.setBurstPeriod(1, 0.02);  
gen.setDelay(1,3.2e-6);
gen.setBurstSource(1, 'INT');    % 'BUS' or 'INT' 
gen.alignPhase();

%% Channel 2
gen.setWaveform(2, 'SQUARE');
gen.setImpedance(1, 50); 
gen.setFrequency(2, 200e3);        
gen.setAmplitude(2, 5);          
gen.setOffset(2, 2.5);
gen.setBurstState(2, 'ON');      
gen.setBurstCycles(2, 1);        % 1 cycle
gen.setBurstPeriod(2, 0.02);  
gen.setDelay(2,0);
gen.setBurstSource(2, 'INT'); 
%gen.setSquareDutyCycle(2,0.05)
gen.setIdleLevel(2, 'TOP')
gen.alignPhase();

%% Enable outputs
gen.outputOn(1);
gen.outputOn(2);
gen.alignPhase();
%% Disable outputs
gen.outputOff(1);
gen.outputOff(2);

%% --------------------------- 3D stage motor configuration ---------------------- %%
%% Motor Initialization for z-axis
zSerialNumber = '0021550513';  
zMotor = PIMotorController(zSerialNumber, '1');
zMotor.connect();
zMotor.setServo(true);
[minPos, maxPos, zRange] = zMotor.getTravelRange();
fprintf('Z-axis travel range: %.2f mm to %.2f mm\n', minPos, maxPos);
%% Move to reference position z-axis
pos_z = minPos +1;
zMotor.moveAbs(pos_z);
%% Motor Initialization for y-axis
ySerialNumber = '0021550514';  
yMotor = PIMotorController(ySerialNumber, '1');
yMotor.connect();
yMotor.setServo(true);
[minPos, maxPos, yRange] = yMotor.getTravelRange();
fprintf('Y-axis travel range: %.2f mm to %.2f mm\n', minPos, maxPos);
%% Move to reference position y-axis
pos_y = minPos + 1;
yMotor.moveAbs(pos_y);
%% Motor Initialization for x-axis
xSerialNumber = '0021550510';  
xMotor = PIMotorController(xSerialNumber, '1');
xMotor.connect();
xMotor.setServo(true);
[minPos, maxPos, xRange] = xMotor.getTravelRange();
fprintf('X-axis travel range: %.2f mm to %.2f mm\n', minPos, maxPos);
%% Move to reference position x-axis
pos_x = minPos + 1;
xMotor.moveAbs(pos_x);
%% ---------------------------------- Oscilloscope configuration ------------------------------%%
% Oscilloscope Initialization for HF MHz with RF switch
ipAddress = '10.48.7.251';
osc = T3DSO2502A(ipAddress);
osc.setInputBufferSize(2^22);   % Increase input buffer size to 4MB
osc.setTimeout(60);             % Set timeout to 60 seconds
osc.connect();

% horizontal settings "time scale"
timeScale = 2e-6; % time per division
numberDivisions = 10;
totalSpan = timeScale * numberDivisions; 
osc.setTimeScale(timeScale);
osc.setTimebaseDelay(-totalSpan/2);

% acquisition and triggering
osc.setImpedance(1,'FIFT')%50 Ohms
osc.setImpedance(2,'FIFT')%50 Ohms
osc.setImpedance(3,'FIFT')%50 Ohms
osc.setAcquisitionType('NORM');
osc.setTriggerType('EDGE');
osc.setTriggerLevel(720e-3);

% no averaging in this osc model
% avgCount = 1024;
% fprintf(osc.visaObj, sprintf(':ACQW:AVER:COUN %d', avgCount));

% vertical settings "Voltage scale"
osc.setVerticalScale(1, 1);
osc.setVerticalScale(2, 500e-3);
osc.setVerticalScale(3, 1);
%osc.setFunctionVerticalScaleAve(2,200e-3)
osc.setOffset(1,0);
osc.setOffset(3,0);
osc.setOffset(4,0);
%osc.setFunctionOffsetAve(2,0);
pause(1);

% Confirm what the oscilloscope applied
Fs_actual = osc.getSampleRate();
fprintf('Oscilloscope sample rate set to: %.2f MSa/s\n', Fs_actual/1e6);

totalTime = timeScale * 10; % 10 divisions
adcMaxValue = 2^16;     % 16-bit ADC resolution
%% ---------------------Define and create output folder -------------------------%%
% Get today's date as a folder name (yyyy-mm-dd format)
dateFolder = datestr(now, 'yyyy-mm-dd');

% Main folder for current date
mainFolder = fullfile(pwd, dateFolder);
if ~exist(mainFolder, 'dir')
    mkdir(mainFolder);
end

% Subfolder inside the date folder
subFolderName = 'acquire_signle_signal';
outputFolder = fullfile(mainFolder, subFolderName);
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder)
end

%% ------------- Scan downward averaged with loop -------------------------------%%
num_steps = 1;                % Number of motor steps
step_size_mm = 0.001;         % 1 µm step size = 0.001 mm
fprintf('Step size: %.4f mm (%.0f µm)\n', step_size_mm, step_size_mm * 1000);

% Preallocate storage
positions_mm = zeros(1, num_steps);
data_all = cell(1, num_steps);
t = [];

disp('Starting Scan downward...');
for i = 1:num_steps
    target_pos = pos_z + i * step_size_mm;
    zMotor.moveAbs(target_pos);
    osc.resetAveragingByOffset(3); % This need to be change based on Channel and the offset level 
    pause(80);  % Wait for motor to settle 80 second chosen for 1024 trace for average 
     
    current_pos = zMotor.getPosition();  % Read actual motor position
    fprintf('Current Position: %.4f mm\n', current_pos);
    positions_mm(i) = current_pos;

    % Acquire data
    [data, t] = acquire_single_trace(osc, adcMaxValue, Fs_actual, t);
    data_all{i} = data;

    pause(1);  % Let pulse or system stabilize before next step
end

% Return to reference position
zMotor.moveAbs(pos_z);
pause(3);

% Save all data in a single file
filename = fullfile(outputFolder, 'scan_downward_all_data.mat');
save(filename, 't', 'positions_mm', 'data_all');
fprintf('All data saved to: %s\n', filename);

%% get single trace of the data
data = osc.getDataAveraged(1, 1, adcMaxValue);  % channel 1
save('osc_data.mat', 'data');

% Create time vector
Fs = 2e9;                 
Ts = 1 / Fs;               
N = length(data);         
t = (0:N-1) * Ts;         

% Plot the result
figure;
plot(t * 1e6, data);       % Convert time to microseconds for readability
xlabel('Time (\mus)');
ylabel('Amplitude');
title('Oscilloscope data with SR 2 GHz');
grid on;
%% Cleanup 
osc.disconnect();
motor.disconnect();
disp('Experiment finished and cleaned up.');
