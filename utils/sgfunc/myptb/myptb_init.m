function Job = myptb_init(Job)
% Job = myptb_init(Job)
% (cc) 2025, seung-goo.kim@ae.mpg.de

if not(exist('Job', 'var')), Job = struct(); end
Job = defaultjob(struct(Machine='mpieaeeg1', Debug=true, AudioMode=1, AudioSrateHz=44100, AudioReqLatencyClass=3, ...
  AudioNumChannels=2, TextSize=100, TextFont='Segoe UI', TextColor=[204 204 204], Vspace=1.25, ...
  FillRect=round(255*0.2*[1 1 1]) ), Job, mfilename);

% Consolas
% Segoe UI
% Calibri

%{
REFERENCE:

http://psychtoolbox.org/docs/PsychPortAudio-Open ‘mode’ Mode of operation. Defaults to 1 == sound playback only. Can be
set to 2 == audio capture, or 3 for simultaneous capture and playback of sound. Note however that mode 3 (full duplex)
does not work reliably on all sound hardware. On some hardware this mode may crash hard! There is also a special
monitoring mode == 7, which only works for full duplex devices when using the same number of input- and output-channels.
This mode allows direct feedback of captured sounds back to the speakers with minimal latency and without involvement of
your script at all, however no sound can be captured during this time and your code mostly doesn’t have any control over
timing etc. You can also define a audio device as a master device by adding the value 8 to mode. Master devices
themselves are not directly used to playback or capture sound. Instead one can create (multiple) slave devices that are
attached to a master device. Each slave can be controlled independently to playback or record sound through a subset of
the channels of the master device. This basically allows to virtualize a soundcard. See help for subfunction ‘OpenSlave’
for more info.

‘reqlatencyclass’ Allows to select how aggressive PsychPortAudio should be about minimizing sound latency and getting
good deterministic timing, i.e. how to trade off latency vs. system load and playing nicely with other sound
applications on the system. Level 0 means: Don’t care about latency or timing precision. This mode works always and with
all settings, plays nicely with other sound applications. Level 1 (the default) means: Try to get the lowest latency
that is possible under the constraint of reliable playback, freedom of choice for all parameters and interoperability
with other applications. Level 2 means: Take full control over the audio device, even if this causes other sound
applications to fail or shutdown. Level 3 means: As level 2, but request the most aggressive settings for the given
device. Level 4: Same as 3, but fail if device can’t meet the strictest requirements.

%}

switch Job.Machine
  case 'thinkpad'
    Screen('Preference','ConserveVRAM', 2^19);
    Job.AudioDevice = 'Microsoft Sound Mapper - Output';
    Screen('Preference', 'SkipSyncTests', 1);

    % FULL-HD (1920 x 1080 px^2) SCREEN of the primary display
    Job.ScreenRect = [0 0 1920 1080]; 

    % PULSE-TTL CODE
    Job.PulseKey = "5%";

    % RESPONSE CODE
    % Blue=1! (#49), Yellow=2@, Green=3#, Red=4$ (#52)
    Job.ResponseKeys = ["1!", "2@", "3#", "4$"];
    % Job.CedrusResponseBoxPort = 'COM3';
    % Job.CedrusResponseBoxButtonIds = ["4.Left", "5.Left", "6.Left", "7.Left"];


  case 'myubuntu22'
    setenv('WAYLAND_DISPLAY'); %Screen('Preference','ConserveVRAM', 2^19);  
    % My lovely Ubuntu 22.04.1 uses XWayland
    Screen('Preference', 'SkipSyncTests', 1);  
    % Skip the test as XWayland is not officially supported
    Job.AudioDevice = 'sysdefault';
    % but this requires Mesa OpenGL hardware

    Job.ScreenRect = [0 0 1920 1080];
    % FULL-HD (1920 x 1080 px^2) SCREEN of the left screen
    Job.TextSize = 36;

%% MPIEA LAB

  case 'mpieaeeg1'    
    % REF: https://confluence.ae.mpg.de/display/LABWIK/Matlab
    %
    %[EEG1]
    % Presentation Computer  (PC-31):
    %  - Fujisu CELSIUS M740B, Xeon 3.5 GHz, 16 GB, SSD 1 TB
    %  - Windows 10 Pro (64-bit)
    %  - MATLAB R2024b (24.2.0.2740171 (R2024b) Update 1)
    %  - Psychphysics Toolbox 3 (v3.0.19.669150966)
    %  - External sound card: RME Fireface UCX
    %  - Loudspeakers: Neumann Model KH120A
    %
    %[Other equipments]
    % - Audiometer: MAICO MA25 (Neurosci department?)
    % - Sound level meter: RS PRO RS-1150 (ArtLab)
    %
    %[TRIGGER OUTPUT]
    %
    % LAB requires "io64.mexw64" and "inpoutx64.dll" to send triggers from
    % PRESENTATION PC to EEG-RECORDING PC via USB-ADAPTOR-BOX. These files are
    % now in sgfunc/mypbt/external/
    %
    %```
    % Initialize LPT
    % ioObj = io64;
    % status = io64(ioObj);
    % address = hex2dec('dfff8');
    %
    % %Send trigger
    % triggervalue=255
    % io64(ioObj,address,triggervalue);
    % WaitSecs(0.005);
    % io64(ioObj,address,0);
    %```
    %
    % EEG1:LPT3:0xDFF8
    % EEG2:LPT3:0xFFF8
    % PSYPHY:LPT3:0xDFE8
    Job.PtrTrg = io64;
    Job.TrgStatus = io64(Job.PtrTrg);
    Job.TriggerAddress = hex2dec('dff8'); % EEG1

    % DISPLAY
    Screen('Preference', 'SkipSyncTests', 0)
    Job.ScreenRect = [0 0 1920 1080]; 
    % FULL-HD (1920 x 1080 px^2) SCREEN of the left screen

    % AUDIO
    Job.AudioDevice = 'Speakers (RME Fireface UCX)';
    Job.AudioReqLatencyClass = 4;

    % RESPONSE CODE: button pad
    Job.ResponseKeys = ["1!", "2@", "3#", "4$"];
    % Job.CedrusResponseBoxPort = 'COM6';
    % Job.CedrusResponseBoxButtonIds = ["4.Left", "5.Left", "6.Left", "7.Left"];

  case 'mpieaeeg2'
    Job.TriggerAddress = hex2dec('fff8'); % EEG2
    Job.PtrTrg = io64;
    Job.TrgStatus = io64(Job.PtrTrg);


  case 'mpieapsyphy'
    Job.TriggerAddress = hex2dec('dfe8'); % PsyPhy
    Job.PtrTrg = io64;
    Job.TrgStatus = io64(Job.PtrTrg);

%% Cobic
  case 'prisma2'

    % DISPLAY
    Screen('Preference','ConserveVRAM', 2^19);
    Screen('Preference', 'SkipSyncTests', 1)
    Job.ScreenRect = [-1920 0 0 1080]; 
    % FULL-HD (1920 x 1080 px^2) SCREEN of the left screen

    % AUDIO
    Job.AudioDevice = 'Speakers (Realtek HD Audio output)'; % what?

    % PULSE-TTL CODE
    Job.PulseKey = "5%";

    % RESPONSE CODE: Blue=1! (#49), Yellow=2@, Green=3#, Red=4$ (#52)
    Job.ResponseKeys = ["1!", "2@", "3#", "4$"];

    % EYELINK


  case 'prisma1'
    
    % DISPLAY
    Screen('Preference','ConserveVRAM', 2^19);
    Screen('Preference', 'SkipSyncTests', 1)
    Job.ScreenRect = [1920 0 1920+1920 1080]; 
    % FULL-HD (1920 x 1080 px^2) SCREEN of the right screen

    % AUDIO
    Job.AudioDevice = 'Speakers (Sound Blaster AE-9)'; % isn't this FireFace?

    % PULSE-TTL CODE
    Job.PulseKey = "5%";
    
    % RESPONSE CODE: Blue=1! (#49), Yellow=2@, Green=3#, Red=4$ (#52)
    Job.ResponseKeys = ["1!", "2@", "3#", "4$"];

    % EYELINK


  case 'terra1'
    
    % DISPLAY
    Screen('Preference','ConserveVRAM', 2^19);
    Screen('Preference', 'SkipSyncTests', 1)
    Job.ScreenRect = [1920 0 1920+1920 1080]; 
    % FULL-HD (1920 x 1080 px^2) SCREEN of the right screen

    % AUDIO
    Job.AudioDevice = 'Speakers (Sound Blaster AE-9)';

    % PULSE-TTL CODE
    Job.PulseKey = "t";
    
    % RESPONSE CODE: Blue=1! (#49), Yellow=2@, Green=3#, Red=4$ (#52)
    Job.ResponseKeys = ["1!", "2@", "3#", "4$"];

    % EYELINK


  otherwise
    error('Machine="%s" NOT DEFINED', Job.Machine)

end

%% VIDEO OUTPUT

% Set screen size: debug (640x360), non-debug (full screen, no cursor)
if Job.Debug
  FACTOR = 1.5;
  win = round([1980 1080]/FACTOR);
  Job.ScreenRect = [0 0 0+win(1) 0+win(2)]; % ONLY FOR DEBUGGING
  Job.TextSize = round(Job.TextSize/FACTOR);
  ShowCursor;
end
sca; close all; HideCursor;

% Create the pointer for the Window
Job.PtrWin = Screen('OpenWindow', 0, 0, Job.ScreenRect);

% Set the Window properties
Screen('Preference', 'Verbosity',0); % error only
Screen('FillRect', Job.PtrWin, Job.FillRect);  % Screen background color
Screen('TextSize', Job.PtrWin, Job.TextSize);
Screen('TextFont', Job.PtrWin, Job.TextFont);
Screen('TextStyle', Job.PtrWin, 0);  % 0=normal, 1=bold, 2=italic, 4=underline (1+2=bold+italic)

%% AUDIO OUTPUT
InitializePsychSound();  % Initialize the sound driver
PsychPortAudio('Close');  % close audio device
PsychPortAudio('Verbosity', 0);  % error only
Dev = PsychPortAudio('GetDevices');  % get audio device IDs
Idx = find(ismember({Dev.DeviceName}, Job.AudioDevice));
if numel(Idx)
  logthis('Audio output device "%s" will be used...\n', Dev(Idx(1)).DeviceName)
  Job.PtrAud = PsychPortAudio('Open', Dev(Idx(1)).DeviceIndex, Job.AudioMode, ...
    Job.AudioReqLatencyClass, Job.AudioSrateHz, Job.AudioNumChannels);
else
  logthis(['Which audio output device do know mean? AUDIO_DEVICE="%s", ',...
    'and the found devices are:\n'], Job.AudioDevice)
  disp({Dev.DeviceName}')
  error('AUDIO DEVICE NOT DETEREMINED')
end
beep off;


%% KEYBOARD/MOUSE INPUT
MaxPriority('GetSecs', 'KbWait', 'WaitSecs', 'KbEventAvail');
try
  if isfield(Job,'CedrusResponseBoxPort')
    Job.CedPtr = CedrusResponseBox('Open', Job.CedrusResponseBoxPort);
    logthis('Cedrus response box connected.\n')
  end
catch
  warning('Cedurs response box port defined but not connected.')
end


end

