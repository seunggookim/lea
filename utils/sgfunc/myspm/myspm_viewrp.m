function myspm_viewrp(fn_epi)

fn_rp = spm_file(fn_epi,'prefix','rp_', 'ext','txt');
if isfile(strrep(fn_rp, '.txt', '.png'))
  return
end

rp = readmatrix(fn_rp);
rp(:,4:6) = rp(:,4:6)/2/pi*360;
figure(Position=[1 1 700 450], Visible='off')
subplot(211); plot(rp(:,1:3)); xlabel('Vol'); ylabel('mm'); grid on; legend(["trans-x","trans-y","trans-z"])
title(fn_epi, interp='none', fontweight='normal', fontsize=11)
subplot(212); plot(rp(:,4:6)); xlabel('Vol'); ylabel('deg'); grid on; legend(["pitch","roll","yaw"])
export_fig(strrep(fn_rp, '.txt', '.png'), '-r150')

end