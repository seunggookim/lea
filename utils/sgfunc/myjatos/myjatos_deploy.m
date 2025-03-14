function Job = myjatos_deploy(Job)
%MYJATOS_DEPLOY deploys an experiment from a local JATOS server to a remote JATOS server
%
% Job = myjatos_deploy(Job)
%
% Job [1x1] structure contains:
% .LocalUrl   '1xN' upto 'jatos'  e.g., 'http://localhost:9000'
% .LocalKey   '1xN'
% .RemoteUrl  '1xN' upto 'jatos'  e.g., 'https://cortex.jatos.org'
% .RemoteKey  '1xN'
% .StudyTitle '1xN' 
%
% (CC0) seung-goo.kim@ae.mpg.de
%
% SEE ALSO https://github.com/JATOS/JATOS/blob/main/jatos-api.yaml


API_PATH = '/jatos/api/v1';
import matlab.net.*
import matlab.net.http.*
import matlab.net.http.io.*

% clean URLs:
Job.LocalUrl(end) = strrep(Job.LocalUrl(end),'/','');
Job.RemoteUrl(end) = strrep(Job.RemoteUrl(end),'/','');

%% TOKEN TEST

header = HeaderField('Authorization', ['Bearer ',Job.LocalKey]);
uri = URI([Job.LocalUrl,API_PATH,'/admin/token']);
response = RequestMessage('get', header).send(uri.EncodedURI);

if strcmp(response.StatusCode,'OK')
  disp(response.Body.Data.data)
  logthis('TOKEN CHECK PASS')
else
  disp(response)
  error('TOKEN CHECK FAILED')
end

%% FIND THE STUDY IN MY LOCAL SERVER

header = HeaderField('Authorization', ['Bearer ',Job.LocalKey]);
uri = URI([Job.LocalUrl,API_PATH,'/studies/properties']);
response = RequestMessage('get', header).send(uri.EncodedURI);

if strcmp(response.StatusCode,'OK')
  studyTitles = {response.Body.Data.data.title};
  studyUuids = {response.Body.Data.data.uuid};
  LOCAL_STUDY_UUID = studyUuids{contains(studyTitles, Job.StudyTitle)};
  logthis('STUDY_TITLE="%s" STUDY_UUID="%s" FOUND.\n', Job.StudyTitle, LOCAL_STUDY_UUID)
else
  disp(response)
  error('COULD NOT FIND A STUDY="%s" in "%s"', Job.StudyTitle, Job.LocalUrl)
end

%% EXPORT THE STUDY FROM MY LOCAL SERVER

header = HeaderField('Authorization', ['Bearer ',Job.LocalKey]);
uri = URI([Job.LocalUrl,API_PATH,'/studies/',LOCAL_STUDY_UUID]);
response = RequestMessage('get', header).send(uri.EncodedURI);

if strcmp(response.StatusCode,'OK')
  filenameJzip = [tempname,'.jzip'];
  fid = fopen(filenameJzip, 'wb');
  fwrite(fid, response.Body.Data);
  fclose(fid);
  logthis('STUDY DOWNLOADED FROM THE LOCAL: ')
  ls(filenameJzip)
else
  disp(response)
  error('CANNOT DOWNLOAD THE STUDY!')
end

%% IMPORT THE STUDY IN THE REMOTE SERVER
header = [
    field.AcceptField(MediaType('application/json'))
    HeaderField('Authorization', ['Bearer ',Job.RemoteKey])
    HeaderField('Content-Type', 'multipart/form-data')
    ]';
uri = URI([Job.RemoteUrl,API_PATH,'/study']);
body = MultipartFormProvider('study', FileProvider(filenameJzip));
response = RequestMessage('post', header, body).send(uri.EncodedURI);

if strcmp(response.StatusCode,'OK')
  disp(response.Body.Data)
  logthis('STUDY UPLOADED TO THE REMOTE.\n')
else
  disp(response)
  error('CANNOT UPLOAD THE STUDY!')
end


%%
if not(nargout)
  clear Job
end

end
