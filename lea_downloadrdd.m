function downloadrdd()


dnData = './data';
if not(isfolder(dnData))
  mkdir(dnData)
end
urlData = '';
fnZip = tempname;
logthis('Downloading data...'); tic
websave(fnZip, urlData); toc
unzip(fnzip, dnData)
logthis('Unzipped: ')


dnData = './data';
if not(isfolder(dnData))
  mkdir(dnData)
end
urlData = '';
fnZip = tempname;
logthis('Downloading data...'); tic
websave(fnZip, urlData); toc
unzip(fnzip, dnData)
logthis('Unzipped: ')
end
