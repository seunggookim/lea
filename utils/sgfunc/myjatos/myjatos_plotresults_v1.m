function myjatos_plotresults(Results)
global DN_PROJ
thisMeta = Results.TblMeta;
thisTrials = Results.TblTrials;
TblSeq = readtable([DN_PROJ,'/meta/rating_sequence_list.csv']);
thisSeq = TblSeq(TblSeq.("seq_id")==str2double(thisMeta.("sequenceId")),:);

set(gcf, Position=[1, 1, 1148 611], DefaultAxesFontSize=12)

Resp = thisTrials(:, contains(thisTrials.Properties.VariableNames, 'Response')).Variables;
subplot(3,6,[1 7 13])
imagesc(Resp, [1 7])
ylabel('Trial#'); set(gca, xTick=1:5, xTickLabel={'F','P','L','V','A'})
colormap(gca, flipud(brewermap(7, 'RdYlBu')))
hcb = colorbaro(Location='southoutside');
title('Rating')

scales = ["familiarity", "professionalism", "liking", "valence", "arousal"];
for j = 1:numel(scales)
  subplot(3,6,1+j)
  boxplot(thisTrials.(strcat(scales(j),"Response")), thisSeq.selected)
  ylim([1 7]); xlabel('IsSelected')
  title(scales(j))
  if j==1
    ylabel('7-point rating (1-based)')
  end
end

subplot(3,6,[14 15])
plot(thisTrials.rtSec-30, lineWidth=2); ylabel('Time after music ends [sec]'); xlabel('Trial#')

subplot(3,6,8)
histogram(thisTrials.rtSec-30); xlabel('Time after music ends [sec]'); ylabel('# Trials')

%{
Muellensiefne+.2014.PLOS1.UK n=147633, Mean [SD]:

EM = 34.66 [5.04]
MT = 26.51 [11.44]
%}
varNames = thisMeta.Properties.VariableNames;
thisEM = sum(thisMeta(1,contains(varNames,'Response') & contains(varNames,'EM')).Variables);
thisMT = sum(thisMeta(1,contains(varNames,'Response') & contains(varNames,'MT')).Variables);

subplot(3,6,9);
x = linspace(6,42,1000);
plot(x, pdf('normal', x, 34.66, 5.04))
xline(thisEM, 'r'); title('GMSI:Emotions')
xlim([x(1) x(end)])

subplot(3,6,10);
x = linspace(7,49,1000);
plot(x, pdf('normal', x, 26.51, 11.41))
xline(thisMT, 'r'); title('GMSI:MusicalTraining')
xlim([x(1) x(end)])

subplot(3,6,11)
thisMeta.Age = string(thisMeta.Age);
textcell = cellfun(@(x) [x,'={\color{blue}',char(thisMeta.(x)),'}'], {...
  'sequenceId','Experience with musical instruments', 'Active interests','Age','Sex','Ethnicity simplified',...
  'Country of birth','Country of residence','Nationality','Language'}, uni=0);
text(0,0,textcell, VerticalAlignment='bottom',FontSize=10, Interpreter='tex')
axis off

subplot(3,6,17)
genres = {'Blues','Classical','Electronic','Folk, World, & Country','Funk / Soul','Hip Hop','Jazz','Latin','Pop'...
  'Reggae','Rock','Other'};
[~,idxVars] = ismember(genres, thisMeta.Properties.VariableNames);
% genres = thisMeta.Properties.VariableNames(idxVars);
isTicked = thisMeta(1,idxVars).Variables;
textcell = {};
for i = 1:12
  if isTicked(i)
    textcell{i} = ['{\color{Blue}', genres{i}, '}'];
  else
    textcell{i} = ['{\color{gray}', genres{i}, '}'];
  end
end
textcell = ['Preferred genres=', textcell];
text(0,0, textcell, VerticalAlignment='bottom', Interpreter='tex', Fontsize=10)
axis off


end
