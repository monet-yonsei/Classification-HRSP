function [EEG_Prep,ECG,EOG] = mnet_prep_binary(EEG)

% -------------------------------------------------------------------------
% The function [mnet_prep_binary] preprocess binary state data. 
% It measures the R peak in the ECG for the same time period and 
% adds this information to the preprocessed EEG data format before returning it.
%
% Downsample
% :
% Select OutEEG & Return Only EEG
% :
% Filtering 0.3Hz <
% : 
% Filtering 30Hz  >
% :
% Set Channel location with standard template
% :
% Re-reference with Common average reference
% :
% Dipole setting (Warp Channel location)
% 
% Use as
%   [EEG_prep,ECG_prep,EOG_prep] = mnet_prep_binary(EEG);
% -------------------------------------------------------------------------

% Downsample EEG with 250Hz
EEG = pop_resample(EEG,250);

% Select OutEEG (ECG,EOG)
ECG = pop_select(EEG,'channel',65); 
EOG = pop_select(EEG,'channel',20); 

% Reject Non-EEG channel (EOG,ECG1,ECG2,pulse,skin,breath)
% and Return Only EEG channel
EEG = pop_select(EEG,'nochannel',[20,65:69]);

% Filtering HPF (0.3Hz<)
EEG = pop_eegfiltnew(EEG,'locutoff',0.3,'plotfreqz',0);
    
% Filtering LPF (30 Hz>)
EEG = pop_eegfiltnew(EEG,'hicutoff',30,'plotfreqz',0);
            
% Set channel location with standard template
EEG = pop_chanedit(EEG,'lookup',[fileparts(which('eeglab')) '/plugins/dipfit/standard_BEM/elec/standard_1005.elc']);
    
% Rereference with Common Avearge reference (CAR)
EEG.nbchan = EEG.nbchan+1;
EEG.data(end+1,:) = zeros(1, EEG.pnts);
EEG.chanlocs(1,EEG.nbchan).labels = 'initialReference';
EEG = pop_reref(EEG, []);
EEG = pop_select( EEG,'nochannel',{'initialReference'});

% Delete events for R peak events
EEG.event = [];
    
% Dipole Setting (Channel location)
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
                      'chansel',1:EEG.nbchan); EEG_Prep = eeg_checkset(EEG);

end