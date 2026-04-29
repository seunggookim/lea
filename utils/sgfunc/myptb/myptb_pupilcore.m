function Job = myptb_pupilcore(Job, Cmd, Label)
% Controls Pupil Labs' CORE
% Job = myptb_pupilcore(Job, Cmd, Label)

% code from [https://github.com/pupil-labs/pupil-helpers]
% [https://github.com/PyPlr/cvd_pupillometry/blob/master/pyplr/pupil.py]

ENDPOINT = 'tcp://127.0.0.1:50020';

switch (Cmd)

  case ('open')
    % Setup zmq context and remote helper
    Ctx = zmq.core.ctx_new();
    Socket = zmq.core.socket(Ctx, 'ZMQ_REQ');

    % set timeout to 1000ms in order to not get stuck in a blocking
    % mex-call if server is not reachable, see
    % http://api.zeromq.org/4-0:zmq-setsockopt#toc19
    zmq.core.setsockopt(Socket, 'ZMQ_RCVTIMEO', 1000);
    logthis('Trying to connect to "%s"...\n', ENDPOINT);
    zmq.core.connect(Socket, ENDPOINT);
    Job.Eyetracker = struct(Ctx=Ctx, Socket=Socket, Endpoint=ENDPOINT);
    

    t1 = GetSecs; % Measure round trip delay
    [~] = command(Job, 't');
    t2 = GetSecs;
    Delay_s = (t2-t1)/2;
    Job.Eyetracker.OneWayDelay_ms = Delay_s;
    logthis('One-way trip command delay: %.4f sec\n', Delay_s);

    

  case ('close')
    zmq.core.disconnect(Job.Eyetracker.Socket, ENDPOINT);
    zmq.core.close(Job.Eyetracker.Socket);
    Job.Eyetracker.Socket = [];

    zmq.core.ctx_shutdown(Job.Eyetracker.Ctx);
    zmq.core.ctx_term(Job.Eyetracker.Ctx);
    Job.Eyetracker.Ctx = [];

    logthis('ZMQ context & socket CLOSED\n')

  case ('rec start')
    Job = myptb_core(Job, 'open');

    % set current Pupil time to 0.0
    % zmq.core.send(Job.Eyetracker.Socket, uint8('T 0.0'));
    % result = zmq.core.recv(Job.Eyetracker.Socket);
    Result = command(Job, 'T 0.0');
    logthis('RECEIVED: "%s"\n', char(Result));

    % start recording
    % zmq.core.send(Job.Eyetracker.Socket, uint8(['R ',Job.RunName]));
    % result = zmq.core.recv(Job.Eyetracker.Socket);
    Result = command(Job, ['R ',Job.SessName,'_',Job.RunName]);
    logthis('Recording should start: "%s"\n', char(Result));
    WaitSecs(5);

  case ('rec stop')
    % zmq.core.send(Job.Eyetracker.Socket, uint8('r'));
    % result = zmq.core.recv(Job.Eyetracker.Socket);
    Result = command(Job, 'r');
    logthis('Recording stopped: "%s"\n', char(Result));

    Job = myptb_core(Job, 'close');

  case ('annot')
    % zmq.core.send(Job.Eyetracker.Socket, uint8('t'));
    % result = zmq.core.recv(Job.Eyetracker.Socket);
    t1 = GetSecs; % Measure round trip delay
    [Result] = command(Job, 't');
    t2 = GetSecs;
    Delay_s = (t2-t1)/2;
    PupilTime = str2double(char(Result)) + Delay_s;
    send_annotation(Job.Eyetracker.Socket, ...
      containers.Map({'topic','label','timestamp','duration'}, {'annotation', Label, PupilTime, 0.0}) );
    logthis('ANNOTATION="%s" SENT @ PupulTime=%.4f sec\n', Label, PupilTime)

  otherwise
    error('"%s": UNKNOWN COMMAND!', Cmd)

end


end

function result = command(Job, Cmd)
try
  zmq.core.send(Job.Eyetracker.Socket, uint8(Cmd));
catch % if the STATUS isn't ready to listen
  [~] = zmq.core.recv(Job.Eyetracker.Socket); % flush it
  zmq.core.send(Job.Eyetracker.Socket, uint8(Cmd)); % re-send it
end
result = zmq.core.recv(Job.Eyetracker.Socket);
end