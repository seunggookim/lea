function validatejob(Job, ValidFields)
% validatejob(Job, ValidFields)
% test if there are not INVALID fields defined (due to typo)

Fields = fieldnames(Job);
for i = 1:numel(Fields)
    assert(ismember(Fields{i}, ValidFields), 'Field "%s" NOT VALID!', Fields{i});
end
end
