function [TblTrial, TblSubject] = parsethissubject(json, TblDemo)
INDEX_SEQUENCE = 1;
INDEX_CONSENT = 2;
INDEX_JAMENDO = (3:22);
INDEX_GMSI = [23, 24];
INDEX_MUSPREF = 25;

TblTrial = [];
for j = INDEX_JAMENDO
  TblTrial = [TblTrial; parsejamendotrial(json{j}.trials)];
end
prolificPid = json{INDEX_CONSENT}.PROLIFIC_PID;
TblTrial = addvars(TblTrial, repmat(string(prolificPid), [size(TblTrial,1), 1]), ...
  NewVariableName='prolificId', Before='seqIdx');

[~,idxDemo] = ismember(prolificPid, TblDemo.("Participant id"));
sequenceId = string(json{INDEX_SEQUENCE}.sequence_id);
TblSubject = addvars(TblDemo(idxDemo,:), sequenceId);
TblSubject = [TblSubject, parsegmsi(json(INDEX_GMSI))];
TblSubject = [TblSubject, parsemuspref(json{INDEX_MUSPREF})];
end

