%% Function GroupICA

function EEG = mnet_groupICA(EEG)

% Set Channel location again
eeglabPath  = fileparts(which('eeglab'));
stanBEMPath = fullfile(eeglabPath,'plugins','dipfit','standard_BEM');
elecfile    = fullfile(stanBEMPath,'elec','standard_1005.elc');
hdmfile     = fullfile(stanBEMPath,'standard_vol.mat');
mrifile     = fullfile(stanBEMPath,'standard_mri.mat');       
[~,CTP]     = coregister(EEG.chanlocs,elecfile,'warp','auto','manual','off');                                                          
EEG         = pop_dipfit_settings(EEG,...
                      'hdmfile',hdmfile    ,...
                      'coordformat','MNI'  ,...
                      'mrifile',mrifile    ,...
                      'chanfile',elecfile  ,...
                      'coord_transform',CTP,...
                      'chansel',1:EEG.nbchan); EEG = eeg_checkset(EEG); 

% Principle Component Analysis
[PCA_activation,PCA_weigths,PCA_singular_values] = runpca(EEG.data);

% Independent Component Analysis
[ICA_weights,ICA_sphere] = runica(PCA_activation);

% Total GroupICA's weights
Total_weights   = (ICA_weights*ICA_sphere)*inv(PCA_weigths);
EEG.icaweights  = Total_weights;
EEG.icasphere   = eye(length(EEG.chanlocs));
EEG.icachansind = 1:length(EEG.chanlocs);

% ICLABEL
EEG = eeg_checkset(EEG,'ica');
EEG = iclabel(EEG,'default');
EEG = eeg_checkset(EEG);

end