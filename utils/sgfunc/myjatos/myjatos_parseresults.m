function Results = myjatos_parseresults(rawPathToRead)
global DN_PROJ

DnProgress = [DN_PROJ,'/meta/prolific-progress/'];
DnDone = [DnProgress,'/sequencesDone'];
[~,~] = mkdir(DnDone);
DnProc = [DN_PROJ,'/data/prolific-data/proc/'];
fnameDemo = findfiles([DN_PROJ,'/data/prolific-data/raw/%s/*.csv'], rawPathToRead);
fnameResults = findfiles([DN_PROJ,'/data/prolific-data/raw/%s/*.txt'], rawPathToRead);
fnameDemo = fnameDemo{1};

fnameDone = [DnProgress,'/done.mat'];
if isfile(fnameDone)
  load(fnameDone, 'idxSeqDone')
else
  idxSeqDone = [];
end

TblDemo = readtable(fnameDemo, FileType='Text', VariableNamingRule='preserve');
Results = []; 
for iSubj = 1:numel(fnameResults)
  json = parsetxt(fnameResults{iSubj});
  [thisTrial, thisMeta] = parsethissubject(json, TblDemo);
  Results = [Results, struct(TblTrials=thisTrial, TblMeta=thisMeta)];
  validateResults(Results(end))
  sequenceDoneCode = Results(end).TblMeta.sequenceId;
  logthis('DONE SequenceId=%s\n',sequenceDoneCode)
  sequenceDoneNum = str2double(Results(end).TblMeta.sequenceId);
  writetable(Results(end).TblTrials, sprintf('%s/seq%s.csv', DnDone, sequenceDoneCode))

  hfig = figure(Visible='off');
  mas_plotresults(Results(end))
  exportgraphics(hfig, sprintf('%s/seq%s.png', DnDone, sequenceDoneCode) )
  close(hfig)

  idxSeqDone = unique([idxSeqDone, sequenceDoneNum]);
end

save([DnProc,'/',rawPathToRead,'.mat'], 'Results')

save(fnameDone,'idxSeqDone')
logthis('Working log file updated: "%s"\n', fnameDone)

Todo = setdiff(1:200, idxSeqDone);
fnameJson = sprintf('%s/TODO_n%03i.json', DnProgress, numel(Todo));
fid = fopen(fnameJson, 'w');
jsonText = jsonencode(struct(todo=Todo));
fprintf(fid, '%s', jsonText);
fclose(fid);
logthis('TODO json list updated: "%s"\n', fnameJson)

end

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


function json = parsetxt(fname)
txt = fileread(fname);
idx = strfind(txt, 'sequence_id');
if numel(idx) > 1
  warning('Multiple entry: taking the last one.')
  txt = txt(idx(end)-2:end);
end
json = jsondecode(['[', strrep(txt, '}{', '},{'), ']']);
end


function tbl = parse7ptlikert(Trial, scales)
presentedScales = fieldnames(Trial.response);
for i = 1:numel(scales)
  pageOrder(i) = find(contains(presentedScales, scales(i)));
  isNegative(i) = contains(presentedScales{pageOrder(i)}, 'neg');
  response(i) = Trial.response.(presentedScales{pageOrder(i)});  % 0 to 6
  if isNegative(i)
    response(i) = 6 - response(i);
  end
  response(i) = response(i) + 1; % make it 1 to 7.
end
tbl = table();
for i = 1:numel(scales)
  tbl = addvars(tbl, response(i), NewVariableNames=[char(scales(i)),'Response']);
  tbl = addvars(tbl, pageOrder(i), NewVariableNames=[char(scales(i)),'PageOrder']);
  tbl = addvars(tbl, isNegative(i), NewVariableNames=[char(scales(i)),'IsNegative']);
end

end

function tbl = parsejamendotrial(Trial)
rtSec = Trial.rt/1000;
txt = strsplit(Trial.audio_track_id, '; ');
cells = strsplit(txt{3},'=');
trackId = string(cells{2});
cells = strsplit(txt{2},'=');
trlIdx = str2double(cells{2});
cells = strsplit(txt{1},'=');
seqIdx = str2double(cells{2});
trackStartSec = Trial.audio_start_time;
trackPlaySec = Trial.audio_play_time;
tbl = table(seqIdx, trlIdx, rtSec, trackId, trackStartSec, trackPlaySec);

scales = ["familiarity", "professionalism", "liking", "valence", "arousal"];
tbl = [tbl, parse7ptlikert(Trial, scales)];


end


function tbl = parsegmsi(Trials)
rtGmsiEmSec = Trials{1}.trials.rt/1000;
rtGmsiMtSec = Trials{2}.trials.rt/1000;

tbl = table(rtGmsiMtSec, rtGmsiEmSec);
scales = ["EM_01", "EM_02", "EM_03", "EM_04", "EM_05", "EM_06"];
tbl = [tbl, parse7ptlikert(Trials{1}.trials, scales)];

scales = ["MT_01", "MT_02", "MT_03", "MT_04", "MT_05", "MT_06"];
tbl = [tbl, parse7ptlikert(Trials{2}.trials, scales)];
end

function tbl = parsemuspref(Trial)

musicGenres = ["Blues", "Classical", "Electronic", "Folk, World, & Country", "Funk / Soul", "Hip Hop", "Jazz",...
  "Latin", "Pop", "Reggae", "Rock", "Other"];
rtMusPrefSec = Trial.trials.rt/1000;

tbl = table(rtMusPrefSec);
for j = 1:numel(musicGenres)
  tbl = addvars(tbl, contains(musicGenres{j}, Trial.trials.response.genres), NewVariableNames=musicGenres(j));
end
end


function validateResults(Result)
logthis('PID=%s, SEQID=%s\n', Result.TblMeta.("Participant id"){1}, Result.TblMeta.("sequenceId"))
assert(Result.TblMeta.("Time taken")/60 < 60, 'Took too long! [%.2f min]', Result.TblMeta.("Time taken")/60)
logthis('PASS: total time took < 60 min\n')
if Result.TblMeta.("Time taken")/60 > 30
  warning('still took long: [%.2f min]', Result.TblMeta.("Time taken")/60)
end

X = Result.TblTrials(:,contains(Result.TblTrials.Properties.VariableNames,'Response')).Variables;
isNeg = Result.TblTrials(1,contains(Result.TblTrials.Properties.VariableNames,'IsNegative')).Variables;
order = Result.TblTrials(:,contains(Result.TblTrials.Properties.VariableNames,'PageOrder')).Variables;
X(:,isNeg) = 8-X(:,isNeg);

assert(all(std(X,[],1)>0))
logthis('PASS: no straight lining\n')

mdl = fitlm(order(:), X(:));
if mdl.Coefficients.pValue(end)<0.0001
  disp(mdl)
  figure; plotmdl(mdl,'x1')
  warning('PAGE-ORDER EFFFECT IN RATING!')
else
  logthis('PASS: no PAGE-ORDER EFFECT\n')
end

scales = Result.TblTrials.Properties.VariableNames(contains(Result.TblTrials.Properties.VariableNames,'Response'));
for j = 1:5
  mdl = fitlm([(1:20)' (1:20)'.^2], X(:,j));
  if mdl.coefTest<0.0001
    warning('[%s] quadratic bias! ', scales{j})
    disp(mdl)
    figure; plotmdl(mdl,'x2')
  else
    logthis('PASS: no quadratic bias in [%s]\n', scales{j})
  end
end




end
