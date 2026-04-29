function Job = myptb_eyelink(Job, cmd, varargin)
% Job = myptb_eyelink(Job, 'openfile', run_info)
% Job = myptb_eyelink(Job, 'trigger', trigger_msg)
% Job = myptb_eyelink(Job, 'save', fname_edf)

if not(isfield(Job,'EyeLink')), Job.EyeLink.IsOnline=false; end

if not(Job.EyeLink.IsOnline)
  % 0. Initialize connection
  Job.EyeLink.IsOnline = not(Eyelink('Initialize'));
  EyelinkInit(0,1); % enables callback which displays eye image on display PC
  assert(Eyelink('IsConnected')==1, 'EyeLink: No connection found!')

  % 1. Set up samples to collect:
  flag = Eyelink('command','link_sample_data = LEFT,RIGHT,GAZE,AREA,GAZERES,HREF,PUPIL,STATUS,INPUT');
  if not(flag)
    error('Problem receiving samples from Eyelink. StatusCode=%i', flag);
  end

  % 2. Send graphics enviroment
  el = EyelinkInitDefaults(window);
  el.backgroundcolour = [0 0 0]; % set backgound to black
  el.foregroundcolour = [255 255 255]; % light grey
  EyelinkUpdateDefaults(el); % apply changes made above
  el.callback = []; % what is this for?

  % 3. Start calibration (how?)
  while EyelinkDoTrackerSetup(el, el.ENTER_KEY) ~=0; end

end

switch cmd
  case 'openfile'
    
    % Open a temp file
    name = java.util.UUID.randomUUID;
    Job.EyeLink.TempFile = [name(1:8),'.edf']; % data.edf
    Eyelink('command','sample_rate = 1000');
    flag = Eyelink('OpenFile', Job.EyeLinkTempFile);
    assert(not(flag), 'EYELINK: FAIL: cannot open an EyeLink EDF file!')

    % Enter run info
    Eyelink('Message', sprintf('SUBJECT_ID=%s', Job.SubjectId));

    % Start recording
    flag = Eyelink('StartRecording', 1, 1, 1, 1); 
    Eyelink('WaitForModeReady', 30);
    assert(not(flag), 'EYELINK: FAIL: cannot start recording!')
    Job.EyeLink.IsRecording = true;

    % Mark run info
    runInfo = varargin{1};
    Eyelink('command', sprintf('record_status_message "CRF, %s"', runInfo));
    

  case 'trigger'
    assert(Job.EyeLink.IsRecording, 'No recording is open!')

    % Send trigger to EyeLink
    triggerMsg = varargin{1};
    Eyelink('Message', triggerMsg);

  case 'save'
    assert(Job.EyeLink.IsRecording, 'No recording is open!')
    
    % Close file
    Eyelink('StopRecording');
    Eyelink('CloseFile');
    Eyelink('Command','clear_screen 0');
    Job.EyeLink.IsRecording = false;

    % Transfer file to this PC
    fnameEdf = varargin{1};
    flag = Eyelink('ReceiveFile', Job.EyeLink.TempFile, fnameEdf);
    if not(flag)
      warning('The EyeLink file could not be copied here! Transfer it before shutting it down!')
    end
    Job.EyeLink.TempFile = '';

  otherwise
    warning('Unknown cmd="%s"')
end

end