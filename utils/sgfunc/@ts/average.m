function TsAvg = average(TsArray)
%TsAvg = average(TsArray)

nTs = numel(TsArray);
TsAvg = TsArray(1);
TsAvg.Data = TsAvg.Data*0;
intersectionTime = TsAvg.Time;
for j = 1:nTs
  intersectionTime = intersect(intersectionTime, TsArray(j).Time);
end
TsAvg = delsample(TsAvg, 'Index', find(not(ismember(TsAvg.Time, intersectionTime))));
for j = 1:nTs
  TsAvg.Data = TsAvg.Data  + TsArray(j).Data(ismember(TsArray(j).Time, intersectionTime),:);
end
TsAvg.Data = TsAvg.Data  / nTs;

% FIX SOME METADATA
switch TsAvg.Name
  case 'eeg'
    TsAvg.UserData.SubjName = strrep(TsAvg.UserData.SubjName, 'Run01', 'RunAvg');
    warning('WILL FIX ORIGMEAN/STD LATER!')
  case 'fmri'
  case 'stim'
  case 'bhv'
end

end