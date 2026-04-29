function tsAvg = average(tsArray)
%TsAvg = average(TsArray)

nTs = numel(tsArray);
tsAvg = tsArray(1);
tsAvg.Data = tsAvg.Data*0;
intersectionTime = tsAvg.Time;
for j = 1:nTs
  intersectionTime = intersect(intersectionTime, tsArray(j).Time);
end
tsAvg = delsample(tsAvg, 'Index', find(not(ismember(tsAvg.Time, intersectionTime))));
for j = 1:nTs
  tsAvg.Data = tsAvg.Data  + tsArray(j).Data(ismember(tsArray(j).Time, intersectionTime),:);
end
tsAvg.Data = tsAvg.Data  / nTs;

% FIX SOME METADATA
switch tsAvg.Name
  case 'eeg'
    tsAvg.UserData.SubjName = strrep(tsAvg.UserData.SubjName, 'Run01', 'RunAvg');
    warning('WILL FIX ORIGMEAN/STD LATER!')
  case 'fmri'
  case 'stim'
  case 'bhv'
end

end