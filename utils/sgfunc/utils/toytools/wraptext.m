function out = wraptext(txt, maxwidth)
fields = strsplit(char(txt),' ');
out = ''; 
charNum = 0;
for i = 1:numel(fields)
  charNum = charNum + numel(fields{i});
  if charNum > maxwidth
    out = [out,'\n',fields{i}];
    charNum = 0;
  else
    out = [out,' ',fields{i}];
  end
end
out(1) = [];
end
