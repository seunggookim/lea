function installwebfile(url, targetFolder, folderName)
%installwebfile(url, targetFolder, folderName)

logthis('Downloading `%s`...', url)
[~, name, ext] = myfileparts(url);
currentFolder = pwd;
cd(targetFolder)
fname = websave([name,ext], url);
fprintf('\n')

logthis('Decompressing `%s`...', fname)
switch ext
  case '.zip'
    unzip(fname)
  case {'.tar.gz', '.tar'}
    untar(fname)
  otherwise
    error('Extension `%s` is not ready!', ext)
end
delete(fname)
fprintf('\n')

if exist('folderName','var')
  [thisPath, ~, ~] = myfileparts(fname);
else
  [thisPath, folderName, ~] = myfileparts(fname);
end
logthis('Downloaded files are here: %s\n', [fullfile(thisPath, folderName),filesep])
ls(folderName)
cd(currentFolder)
end


