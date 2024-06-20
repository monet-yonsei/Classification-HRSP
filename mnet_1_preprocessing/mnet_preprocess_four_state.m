%% Part 1. Preprocessing Raw EEG [Four state experimental data (N=12)]
%  1-1. Load Raw EEGs
%  1-2. Preprocess Four experimental data (N=12)
%  1-3. Preprocess Four experimental data (N=12) for Individual ICA
%  1-4. Preprocess Four experimental data (N=12) for Group ICA

%% 1-1. Load Raw EEGs

Datapath = '~\Four_state'; 
load('~\Task_sequence.mat')

for sub = 1:12
    
    Filename = ['Sub_',num2str(sub)];
    Filepath = fullfile(Datapath,Filename);
    Raw_EEG{1,sub} = pop_loadset([Filename,'.set'],Filepath);

end
    
%  Raw_EEG_4task -> Load EEG data using pop_loadbv function
%  Event_4task   -> Load .mat format

number_of_subject = 12;

%% 1-2. Preprocess Four state experimental data (N=17)
%  Divide each task blocks after preprocessing

option = [];
option.number_of_task = 4;
option.ICA_option     = [];

for sub = 1:number_of_subject
    if sub ~= 12
       [Fourstate_taskEEG{1,sub},Fourstate_taskECG{1,sub}] = ...
       mnet_prep_eeg(Raw_EEG{1,sub},[],option);
    else
       option.Orig_EEG = Divided_4task_EEG{1,1}{1,1}.chanlocs;
       [Fourstate_taskEEG{1,sub},Fourstate_taskECG{1,sub}] = ...
       mnet_prep_eeg(Raw_EEG{1,sub},[],option);
    end
end

%% 1-3. Preprocess Four state experimental data (N=17) for Individual ICA

option = [];
option.number_of_task = 4;
option.ICA_option     = 'yes';
option.individual_ICA = 'yes';

for sub = 1:number_of_subject
    if sub ~= 12
       [Fourstate_Individual_ICA{1,sub}] = ...
       mnet_prep_eeg(Raw_EEG{1,sub},[],option);
    else
       option.Orig_EEG = Fourstate_Individual_ICA{1,1}.chanlocs;
       [Fourstate_Individual_ICA{1,sub}] = ...
       mnet_prep_eeg(Raw_EEG{1,sub},[],option);
    end
end

%% 1-4. Preprocess Four state experimental data (N=17) for Group ICA

option = [];
option.number_of_task = 4;
option.ICA_option     = 'yes';
option.individual_ICA = 'no';

for sub = 1:number_of_subject
    if sub ~= 12
       [Subject_EEG{1,sub}] = ...
       mnet_prep_eeg(Raw_EEG{1,sub},[],option);
    else
       option.Orig_EEG = Subject_EEG{1,1}.chanlocs;
       [Subject_EEG{1,sub}] = ...
       mnet_prep_eeg(Raw_EEG{1,sub},[],option);
    end
end

% Merge all subject's entire EEG
for sub = 1:number_of_subject
    if sub == 1       
       Total_EEG = Subject_EEG{1,sub};
       Total_EEG = pop_rmbase(Total_EEG,[],[]);
    else
       Plus_EEG  = Subject_EEG{1,sub};
       Plus_EEG  = pop_rmbase(Plus_EEG,[],[]);
       Total_EEG = pop_mergeset(Total_EEG,Plus_EEG,0);
    end
end

% Group ICA
Four_state_Group_ICA = mnet_groupICA(Total_EEG);
Four_state_Group_ICA = pop_icflag(Four_state_Group_ICA,[0 0.7;0 0;0 0;0 0;0 0;0 0;0 0]);
Four_state_Group_ICA = pop_subcomp(Four_state_Group_ICA,find(Four_state_Group_ICA.reject.gcompreject == 1),0,0);

%% Part 2. Generate HRSP [Four state experimental data (N=12)]
%  2-1. Generate HRSP with interpolation method based on Individual ICA weights & Group ICA weights
%  2-2. Trial by Trial Normalization for single-trial HRSP
%  2-3. Baseline Correction for single-trial HRSP

number_of_task = 20;

%% Generate HRSP with interpolation based on Individual & Group Components

for sub = 1:number_of_subject

    % Individual ICA weights 

    EEG = Fourstate_Individual_ICA{1,sub};
    EEG = pop_icflag(EEG,[0 0.7;0 0;0 0;0 0;0 0;0 0;0 0]);
    EEG = pop_subcomp(EEG,find(EEG.reject.gcompreject == 1),0,0);
    
    EEGs = Divided_4task_EEG{1,sub};
    ECGs = Divided_4task_ECG{1,sub};

    Total_HRSP = cell(1,number_of_task);
    for j = 1:number_of_task
        Total_HRSP{1,j} = mnet_extract_hrsp(EEGs{1,j},EEG.icaweights,[ECGs{1,j}.event.latency]);
    end

    X = ['Offline_Individual_HRSP_4task_',num2str(sub),' = Total_HRSP;']; eval(X)
    
    % ---------------------------------------------------------------------
    % Group ICA weights

    EEGs = Divided_4task_EEG{1,sub};
    ECGs = Divided_4task_ECG{1,sub};

    Total_HRSP = cell(1,number_of_task);
    for j = 1:number_of_task
        Total_HRSP{1,j} = mnet_extract_hrsp(EEGs{1,j},Four_state_Group_ICA.icaweights,[ECGs{1,j}.event.latency]);
    end

    X = ['Offline_Group_HRSP_4task_',num2str(sub),' = Total_HRSP;']; eval(X)

end

%% 2-2. Trial by Trial Normalization for single-trial HRSP

for sub = 1:number_of_subject

    X = ['HRSP = Offline_Individual_HRSP_4task_',num2str(sub),';']; eval(X);    
    [Four_state_Indi_HRSP_Norm{1,sub}]  = mnet_trial_by_trial_normalization(HRSP,4);
    
    X = ['HRSP = Offline_Group_HRSP_4task_',num2str(sub),';']; eval(X);    
    [Four_state_Group_HRSP_Norm{1,sub}] = mnet_trial_by_trial_normalization(HRSP,4);

end

%% 2-3. Baseline Correction for single-trial HRSP

for sub = 1:number_of_subject

    [Four_state_Indi_Heart_HRSP_Single{1,sub},Four_state_Indi_Sound_HRSP_Single{1,sub},...
     Four_state_Indi_Time_HRSP_Single{1,sub}, Four_state_Indi_Toes_HRSP_Single{1,sub}] = ...
     mnet_baseline_correction([],[],Four_state_Indi_HRSP_Norm{1,sub},4,Sequence{1,sub});  
    
    [Four_state_Group_Heart_HRSP_Single{1,sub},Four_state_Group_Sound_HRSP_Single{1,sub},...
     Four_state_Group_Time_HRSP_Single{1,sub}, Four_state_Group_Toes_HRSP_Single{1,sub}] = ...
     mnet_baseline_correction([],[],Four_state_Group_HRSP_Norm{1,sub},4,Sequence{1,sub});

end