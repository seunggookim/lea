function target_amplitude = myptb_targetvolume(stimLUFS_dB, threshold_1k_dB, targetHL_dB)
% target_amplitude = myptb_targetvolume(stimLUFS_dB, threshold_1k_dB, targetHL_dB)

%{
-0.2762 LUFS dB = loudness at 1 kHz
Music's loudness is about -20 dB (because I set so).

attenuation_dB = threshold_1k_dB + targetHL_dB - stimLUFS_dB + correction_dB
%}

assert(not(isempty(stimLUFS_dB)));
assert(not(isempty(threshold_1k_dB)));
assert(not(isempty(targetHL_dB)));

correction_dB = -0.2762;
attenuation_dB = threshold_1k_dB + targetHL_dB - stimLUFS_dB + correction_dB; % this will play the music at targetHL_dB
if attenuation_dB > 0
  warning('attenuation_dB = %.2f ? It cannot be greater than 1!', attenuation_dB)
  attenuation_dB = 1;
end
target_amplitude = 10^(attenuation_dB/20);
end