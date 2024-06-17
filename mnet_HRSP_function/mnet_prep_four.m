function [EEG,ECG] = mnet_prep_four(EEG,idx_interpolate,option)

% -------------------------------------------------------------------------
% The function mnet_prep_four_state preprocesses four state data. 
% It measures the R peak in the ECG for the same time period and 
% adds this information to the preprocessed EEG data format before returning it.
%
% Downsample
% :
% Select OutEEG & Return Only EEG
% :
% Reject Bad Channels, and interpolate
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
%   
% option = [];
% idx_interpolate = 0;
% [EEG,ECG] = mnet_prep_four_state(EEG,idx_interpolate,option);
% -------------------------------------------------------------------------

    if idx_interpolate == 0
    
       % Downsample EEG with 250Hz
       EEG = pop_resample(EEG,250);
        
       % Select OutEEG (ECG)
       ECG = pop_select(EEG,'channel',31);
        
       % Filtering HPF (0.3Hz<)
       EEG = pop_eegfiltnew(EEG,'locutoff',0.3,'plotfreqz',0);
        
       % Filtering LPF (30 Hz>)
       EEG = pop_eegfiltnew(EEG,'hicutoff',30,'plotfreqz',0);
        
       % Set channel location with standard template
       EEG = pop_chanedit(EEG,'lookup',[fileparts(which('eeglab')) '/plugins/dipfit/standard_BEM/elec/standard_1005.elc']);
        
       % Reject Non-EEG channel (ECG1,ECG2)
       % and Return Only EEG channel
       EEG = pop_select(EEG,'nochannel',[31,32]);
       Orig_EEG = EEG;
        
       % Find bad EEG channel and reject using clean_rawdata
       EEG = pop_clean_rawdata(EEG,'FlatlineCriterion',5,'ChannelCriterion',0.8,...
                                   'LineNoiseCriterion',4,'Highpass','off','BurstCriterion','off',...
                                   'WindowCriterion','off','BurstRejection','off','Distance','Euclidian');
        
       % Interpolate bad channel
       EEG = pop_interp(EEG,Orig_EEG.chanlocs,'spherical');
        
       % Rereference with Common Avearge reference (CAR)
       EEG.nbchan = EEG.nbchan+1;
       EEG.data(end+1,:) = zeros(1, EEG.pnts);
       EEG.chanlocs(1,EEG.nbchan).labels = 'initialReference';
       EEG = pop_reref(EEG, []);
       EEG = pop_select( EEG,'nochannel',{'initialReference'});
       EEG = eeg_checkset(EEG);
        
       % Delete events for R peak events
       EEG.event = [];
            
       % Dipole setting (channel location)
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

    else
        
       % Downsample EEG with 250Hz
       EEG = pop_resample(EEG,250);
    
       % Select OutEEG (ECG)
       ECG = pop_select(EEG,'channel',28);
        
       % Filtering HPF (0.3Hz<)
       EEG = pop_eegfiltnew(EEG,'locutoff',0.3,'plotfreqz',0);
        
       % Filtering LPF (30 Hz>)
       EEG = pop_eegfiltnew(EEG,'hicutoff',30,'plotfreqz',0);
        
       % Set channel location with standard template
       EEG = pop_chanedit(EEG,'lookup',[fileparts(which('eeglab')) '/plugins/dipfit/standard_BEM/elec/standard_1005.elc']);
           
       % Reject ECG (Number of ECGs are 28,29)
       EEG = pop_select(EEG,'nochannel',[28,29]);
        
       % find bad EEG channel and reject
       EEG = pop_clean_rawdata(EEG,'FlatlineCriterion',5,'ChannelCriterion',0.8,...
                                   'LineNoiseCriterion',4,'Highpass','off','BurstCriterion','off',...
                                   'WindowCriterion','off','BurstRejection','off','Distance','Euclidian');
        
       % interpolate bad channel
       EEG = pop_interp(EEG,option.Orig_EEG.chanlocs,'spherical');
        
       % Common Avearge reference
       EEG.nbchan = EEG.nbchan+1;
       EEG.data(end+1,:) = zeros(1, EEG.pnts);
       EEG.chanlocs(1,EEG.nbchan).labels = 'initialReference';
       EEG = pop_reref(EEG, []);
       EEG = pop_select(EEG,'nochannel',{'initialReference'});
       EEG = eeg_checkset(EEG);
        
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
                                  'chansel',1:EEG.nbchan); EEG = eeg_checkset(EEG);    
    end
end
