function varargout = mnet_prep_eeg(EEG,event,option)

% The function mnet_prep_eeg preprocesses raw EEG data that includes ECG. 
% It takes the task index for each participant as input and returns the preprocessed EEG 
% for each task segment or the entire task length with event markers at the points corresponding to the R peaks.
%
% Use as
%   ex) binary experimental data
%   option = [];
%   option.number_of_task = 2;
%   option.divide_task    = 'yes';
%   option.individual_ICA = [];
%   [Heart_EEG,Sound_EEG,Heart_ECG,Sound_ECG] = mnet_prep_eeg(EEG,event,option)
%
%   ex) four state experimental data 
%   option = [];
%   option.number_of_task = 4;
%   option.divide_task    = 'yes';
%   option.individual_ICA = [];
%   [Heart_EEG,Sound_EEG,Heart_ECG,Sound_ECG] = mnet_prep_eeg(EEG,event,option)

if option.number_of_task == 2

   [EEG,ECG,~] = mnet_prep_binary(EEG); % Preprocess binary state experimental data

   if strcmp(option.divide_task,'yes') % For divided task EEGs

      Hearttask_event = [event.store.events.heartOn;event.store.events.heartOff];
      Soundtask_event = [event.store.events.soundOn;event.store.events.soundOff];

      Heart_EEG = cell(1,10);
      Sound_EEG = cell(1,10);    
      Heart_ECG = cell(1,10);
      Sound_ECG = cell(1,10);

      for i = 1:10
          Heart_EEG{1,i} = pop_select(EEG,'time',Hearttask_event(:,i)');
          Sound_EEG{1,i} = pop_select(EEG,'time',Soundtask_event(:,i)');
          Heart_ECG{1,i} = pop_select(ECG,'time',Hearttask_event(:,i)');
          Sound_ECG{1,i} = pop_select(ECG,'time',Soundtask_event(:,i)');
      end

      % Detect R peaks & ECG's event -> EEG's event

      for i = 1:10
          Heart_ECG{1,i} = mnet_detect_rpeaks(Heart_ECG{1,i});
          Heart_EEG{1,i}.event = Heart_ECG{1,i}.event;
          Sound_ECG{1,i} = mnet_detect_rpeaks(Sound_ECG{1,i});
          Sound_EEG{1,i}.event = Sound_ECG{1,i}.event;
      end

      % Output is Divided EEG with task

      varargout{1} = Heart_EEG;
      varargout{2} = Sound_EEG;
      varargout{3} = Heart_ECG;
      varargout{4} = Sound_ECG;
   
   elseif strcmp(option.divide_task,'no') % For individual ICA

      Hearttask_event = [event.store.events.heartOn;event.store.events.heartOff];
      Soundtask_event = [event.store.events.soundOn;event.store.events.soundOff];
      Task_event      = [Hearttask_event Soundtask_event];
      Task_event      = sort(Task_event,2);
      EEG             = pop_select(EEG,'time',Task_event');

      if strcmp(option.individual_ICA,'yes')

         EEG = pop_runica(EEG,'runica');
         EEG = iclabel(EEG,'default');
         EEG = eeg_checkset(EEG,'ica');
         varargout{1} = EEG;

      else

         varargout{1} = EEG;

      end

   end

elseif option.number_of_task == 4

    % Common preprocess for four state experimental data

    if EEG.nbchan == 64
       [EEG,ECG] = mnet_prep_four_state(EEG,0,[]);
    else
       if isempty(option.Orig_EEG)
          error("For interpolating, use prior preprocessed EEG's channel location")
       end
       % Interpolate missing channel
       [EEG,ECG] = mnet_prep_four_state(EEG,1,option.Orig_EEG);
    end
       
    % Divide EEG with task
    [EEG_prep,ECG_prep] = mnet_divide_task(EEG,ECG);
   
    % Detect R peaks each divided ECG
    for i = 1:20
        ECG_prep{1,i} = mnet_detect_rpeaks(ECG_prep{1,i});
        EEG_prep{1,i}.event = ECG_prep{1,i}.event;
    end

    varargout{1} = EEG_prep;
    varargout{2} = ECG_prep;

    if strcmp(option.ICA_option,'yes')
       Merged_EEG = eeg_emptyset();
       Merged_EEG = EEG_prep{1,1};
       Merged_EEG = pop_rmbase(Merged_EEG,[],[]);
       for i = 2:20
           Plus_EEG = EEG_prep{1,i};
           Plus_EEG = pop_rmbase(Plus_EEG,[],[]);
           Merged_EEG = pop_mergeset(Merged_EEG,Plus_EEG);
       end       
       if strcmp(option.individual_ICA,'yes')            
          Merged_EEG = pop_runica(Merged_EEG,'runica');
          Merged_EEG = iclabel(Merged_EEG,'default');
          Merged_EEG = eeg_checkset(Merged_EEG,'ica');
          varargout{1} = Merged_EEG;    
       else % For GroupICA    
          varargout{1} = Merged_EEG;   
       end
    end
else
    error('Format is not appropriate')
end