function [EEG,ECG,EOG] = mnet_prep_binary(EEG)

% The function mnet_prep_binary preprocesses binary state data. 
% It measures the R peak in the ECG for the same time period and 
% adds this information to the preprocessed EEG data format before returning it.
%
% Use as
%   [EEG_prep,ECG_prep,EOG_prep] = mnet_prep_binary(EEG);

% downsample 250Hz
EEG = pop_resample(EEG,250);

% outEEG (ECG,EOG)
ECG = pop_select(EEG,'channel',65); % extract ECG
EOG = pop_select(EEG,'channel',20); % extract EOG

% reject Non-EEG channel (EOG,ECG1,ECG2,pulse,skin,breath)
EEG = pop_select(EEG,'nochannel',[20,65:69]);

% filtering HPF
EEG = pop_eegfiltnew(EEG,'locutoff',0.3,'plotfreqz',0);
    
% filtering LPF
EEG = pop_eegfiltnew(EEG,'hicutoff',30,'plotfreqz',0);
            
% set channel location with standard template
EEG = pop_chanedit(EEG,'lookup',[fileparts(which('eeglab')) '/plugins/dipfit/standard_BEM/elec/standard_1005.elc']);
    
% Common Avearge reference (CAR)
EEG.nbchan = EEG.nbchan+1;
EEG.data(end+1,:) = zeros(1, EEG.pnts);
EEG.chanlocs(1,EEG.nbchan).labels = 'initialReference';
EEG = pop_reref(EEG, []);
EEG = pop_select( EEG,'nochannel',{'initialReference'});

% delete events for R peak events
EEG.event = [];
    
% dipole Setting (Channel location)
eeglabPath  = fileparts(which('eeglab'));
stanBEMPath = fullfile(eeglabPath,'plugins','dipfit','standard_BEM');
elecfile    = fullfile(stanBEMPath,'elec','standard_1005.elc');
hdmfile     = fullfile(stanBEMPath,'standard_vol.mat');
mrifile     = fullfile(stanBEMPath,'standard_mri.mat');       
[~,CTP]     = coregister(EEG.chanlocs,elecfile,'warp','auto','manual','off');                                                          
EEG = pop_dipfit_settings(EEG,...
                      'hdmfile',hdmfile    ,...
                      'coordformat','MNI'  ,...
                      'mrifile',mrifile    ,...
                      'chanfile',elecfile  ,...
                      'coord_transform',CTP,...
                      'chansel',1:EEG.nbchan); EEG = eeg_checkset(EEG);

end