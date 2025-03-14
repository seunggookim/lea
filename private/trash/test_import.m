clear all
lea_addpath()
fnameFmri = '/Volumes/APFS-2TB/extendedhome/MATLAB Drive/lars-audscene/data/prep/S1/S1_r1_CUT_mr1.nii';
fnameEeg = '/Volumes/APFS-2TB/git/dualeeg/data/raw/pair03-player1.mat';
%%
!rm testdata.*
lea_import( ...
  struct(FnameData='/Volumes/APFS-2TB/extendedhome/MATLAB Drive/ksmpc-ss24-sess03/data/chills_song4.csv', ...
  DataType='bhv', FnameTs='testdata.mat'))
out = loadts('testdata.mat')
out.DataInfo.UserData
%%
!rm testdata.*
lea_import( ...
  struct(FnameData=fnameEeg, DataType='eeg', FnameTs='testdata.mat'))
out = loadts('testdata.mat')
out.DataInfo.UserData
out.TimeInfo
plot(out)
%%
!rm testdata.*
lea_import( ...
  struct(FnameData=fnameFmri, DataType='fmri', FnameTs='testdata.mat', Detrend=''))
out = loadts('testdata.mat')

out.DataInfo.UserData
out.TimeInfo
% out = loadts('testdata.mat')
% Elapsed time is 19.433873 seconds.
% tic;niftireadgz(fnameFmri);toc
% Elapsed time is 26.552543 seconds.
%% Preprocessing
% cd /Volumes/APFS-2TB/git/lea/
mkdir proc
fnamesX = string(findfiles('./demo/env*'))
for i = 1:numel(fnamesX)
  Tbl = readtable(fnamesX(i));
  Tbl.Properties.VariableNames{1} = 'timeSec';
  fnameOut = strrep(fnamesX(i), 'env', 'ENV');
  writetable(Tbl, fnameOut)
  lea_import(struct(FnameData=fnameOut, DataType='stim', ...
    FnameTs=sprintf('proc/stim-env_song-%i.mat', i)))
end

fnamesT = string(findfiles('./demo/touched*'))
for i = 1:7
  Tbl = readtable(fnamesT(i))
  Tbl.Properties.VariableNames{1} = 'timeSec';
  fnameOut = strrep(fnamesT(i), 'touched', 'Touched');
  writetable(Tbl, fnameOut)
  lea_import(struct(FnameData=fnameOut, DataType='bhv', ...
    FnameTs=sprintf('proc/bhv-touched_song-%i.mat', i)))
end

fnamesB = string(findfiles('./demo/beauty*'))
for i = 1:7
  Tbl = readtable(fnamesB(i))
  Tbl.Properties.VariableNames{1} = 'timeSec';
  fnameOut = strrep(fnamesB(i), 'beauty', 'Beauty');
  writetable(Tbl, fnameOut)
  lea_import(struct(FnameData=fnameOut, DataType='bhv', ...
    FnameTs=sprintf('proc/bhv-beauty_song-%i.mat', i)))
end

%% Import

%%
cd ~/Downloads/
fnamesX = findfilesstr('proc/stim-env*.mat')
fnamesY = [findfilesstr('proc/bhv-touched*.mat'), findfilesstr('proc/bhv-beauty*.mat')]

Job = struct(FnamesX=fnamesX, FnamesY=fnamesY, RelToiSec=[15 -15], ...
  DnameMdl='./demo/mdl3/', DelaysSmp=(-1:2));
[Job] = lea_main(Job);
