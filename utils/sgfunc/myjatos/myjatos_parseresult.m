function Results = myjatos_parseresult(fnameText, fnameDemo)

% PARSE jsonl without linebreaks:
txt = fileread(fnameText);
idx = strfind(txt, 'sequence_id');
if numel(idx) > 1
  warning('Multiple entry: taking the last one.')
  txt = txt(idx(end)-2:end);
end
json = jsondecode(['[', strrep(txt, '}{', '},{'), ']']);

%%
assert (numel(json) == 28, 'This does not look like v2!')
INDEX_SEQUENCE = 1;
INDEX_CONSENT = 2;
INDEX_SELF = (3:5);
INDEX_EXP = (6:25);
INDEX_GMSI = [26, 27];
INDEX_MUSPREF = 28;

if not(isempty(fieldnames(json{INDEX_CONSENT})))
  prolificPid = json{INDEX_CONSENT}.PROLIFIC_PID;
else
  prolificPid = nan;
end

TblSelf = table();
for j = INDEX_SELF
  TblSelf = [TblSelf; parseratingtrial(json{j}.trials)];
end
TblExp = table();
for j = INDEX_EXP
  TblExp = [TblExp; parseratingtrial(json{j}.trials)];
end

%%
TblRatings = [TblSelf; TblExp];

if exist('fnameDemo', 'var')
  TblDemo = readtable(fnameDemo);
  [~,idxDemo] = ismember(prolificPid, TblDemo.("Participant id"));
  sequenceId = string(json(INDEX_SEQUENCE).sequence_id);
  TblSubject = addvars(TblDemo(idxDemo,:), sequenceId);
  TblSubject = addvars(TblSubject, repmat(string(prolificPid), [size(TblSubject,1), 1]), ...
    NewVariableName='prolificId', Before='seqIdx');
  
else
  TblSubject = table(string(prolificPid), VariableNames="prolificPid");
end
TblSubject = [TblSubject, parsegmsi(json(INDEX_GMSI))];
TblSubject = [TblSubject, parsemuspref(json{INDEX_MUSPREF})];

Results = struct(TblRatings=TblRatings, TblSubject=TblSubject);

end


function tbl = parseratingtrial(thisTrial)
rtSec = thisTrial.time_elapsed/1000;
if not(contains(thisTrial.audio_track_id,';')) % if APPLE MUSIC SELF-SELECTED
  seqIdx = nan;
  trlIdx = nan;
  trackId = "A"+string(thisTrial.audio_track_id);
else
  txt = strsplit(thisTrial.audio_track_id, '; ');
  cells = strsplit(txt{3},'=');
  trackId = string(cells{2});
  cells = strsplit(txt{2},'=');
  trlIdx = str2double(cells{2});
  cells = strsplit(txt{1},'=');
  seqIdx = str2double(cells{2});
end
trackStartSec = thisTrial.audio_start_time;
trackPlaySec = thisTrial.audio_play_time;
trackUrl = string(thisTrial.audio_stimulus);

tbl = table(seqIdx, trlIdx, rtSec, trackId, trackUrl, trackStartSec, trackPlaySec);
ratings = parsesliderrating(thisTrial);
tbl = [tbl, ratings];
end


function [ratings, labelOrder, isFlipped] = parsesliderrating(thisTrial)
%{
[
  ["Professional", "<em>It sounds ...</em>", "Unprofessional"],
  ["Familiar", "<em>It sounds ...</em>", "Unfamiliar"],
  ["Moved or Touched", "<em>I feel ...</em>", "Bored or Disgusted"],
  ["Like it", "<em>I ...</em>", "Dislike it"],
  ["Joyful or Amused", "<em>I feel ...</em>", "Sorrowful or Agitated"],
  ["Excited or Energized", "<em>I feel ...</em>", "Calm or Relaxed"]
]
%}
labels = thisTrial.labels;
response = thisTrial.response;
ratingLabels = ["professionalism","familiarity","valence","arousal","liking","moved"];
searchTerm = ["Professional","Familiar","Joyful","Excited","Like","Moved"];

for i = 1:numel(ratingLabels)
  labelOrder(i) = find(cellfun(@(x) any(contains(x, searchTerm(i))), labels));
  isFlipped(i) = find(contains(labels{labelOrder(i)}, searchTerm(i))) == 1; % POSITIVE To LEFT?
  if max(response(:)) > 100
    values(i) = ( (response(labelOrder(i)) - 100) * (isFlipped(i)*-2+1) ) / 100; % [0,200] -> [-1,+1]
  else
    values(i) = ( (response(labelOrder(i)) - 50) * (isFlipped(i)*-2+1) ) / 50; % [0,100] -> [-1,+1]
  end
end
assert( isequal(sort(labelOrder), 1:numel(ratingLabels)) )
assert( any(isFlipped) )
ratings = [...
  array2table(values, VariableNames = arrayfun(@(x) x+"_val", ratingLabels)), ...
  array2table(int16(labelOrder), VariableNames = arrayfun(@(x) x+"_ord", ratingLabels)), ...
  array2table(isFlipped, VariableNames = arrayfun(@(x) x+"_neg", ratingLabels)) ...
  ];
end


function tbl = parsegmsi(Trials)
rtGmsiEmSec = Trials{1}.trials.time_elapsed/1000;
rtGmsiMtSec = Trials{2}.trials.time_elapsed/1000;

tbl = table(rtGmsiMtSec, rtGmsiEmSec);
scales = ["EM_01", "EM_02", "EM_03", "EM_04", "EM_05", "EM_06"];
tbl = [tbl, parse7ptlikert(Trials{1}.trials, scales)];

scales = ["MT_01", "MT_02", "MT_03", "MT_04", "MT_05", "MT_06", "MT_07"];
tbl = [tbl, parse7ptlikert(Trials{2}.trials, scales)];
%{
Muellensiefne+.2014.PLOS1.UK n=147633, Mean [SD]:
EM = 34.66 [5.04]
MT = 26.51 [11.44]
%}
varnames = tbl.Properties.VariableNames;
Emo_val = sum(tbl(:,contains(varnames, 'EM') & contains(varnames, '_val')).Variables);
Emo_prc = cdf('norm', Emo_val, 34.66, 5.04);
MTr_val = sum(tbl(:,contains(varnames, 'MT') & contains(varnames, '_val')).Variables);
MTr_prc = cdf('norm', MTr_val, 26.51, 11.44);
tbl = addvars(tbl, Emo_val, Emo_prc, MTr_val, MTr_prc);
end

function tbl = parsemuspref(Trial)
musicGenres = ["Blues", "Classical", "Electronic", "Folk, World, & Country", "Funk / Soul", ...
  "Hip Hop", "Jazz", "Latin", "Pop", "Reggae", "Rock", "Other"];
rtMusPrefSec = Trial.trials.time_elapsed/1000;

tbl = table(rtMusPrefSec);
for j = 1:numel(musicGenres)
  tbl = addvars(tbl, contains(musicGenres{j}, Trial.trials.response.genres), NewVariableNames=musicGenres(j));
end
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
  tbl = addvars(tbl, response(i), NewVariableNames=[char(scales(i)),'_val']);
  tbl = addvars(tbl, pageOrder(i), NewVariableNames=[char(scales(i)),'_order']);
  tbl = addvars(tbl, isNegative(i), NewVariableNames=[char(scales(i)),'_neg']);
end
end
