%% Preprocess from Raw Four experimental data (N=12) to Baseline corrected HRSP
%  Offline individual HRSP & Offline group HRSP

%  Raw_EEG_4task -> Just load EEG data using pop_loadbv function
%  Event_4task   -> Just load .mat format

number_of_subject = 12;
number_of_task    = 20;

%% Preprocess binary experimental data 
%  For Preprocess divided task EEGs 

option = [];
option.number_of_task = 4;
option.ICA_option     = [];
% option.Orig_EEG     = Divided_4task_EEG{1,1}.chanlocs;

for sub = 1:number_of_subject
    [Divided_4task_EEG{1,sub},Divided_4task_ECG{1,sub}] = ...
     mnet_prep_eeg(Raw_EEG_4task{1,sub},[],option);
end

%% Preprocess binary experimental data
%  For Individual ICA weights

option = [];
option.number_of_task = 4;
option.ICA_option     = 'yes';
option.individual_ICA = 'yes';

for sub = 1:number_of_subject
    [Individual_ICA_4task{1,sub}] = ...
     mnet_prep_eeg(Raw_EEG_4task{1,sub},Event_4task{1,sub},option);
end

%% Preprocess binary experimental data
%  For Group ICA weights

option = [];
option.number_of_task = 4;
option.ICA_option     = 'yes';
option.individual_ICA = 'no';

for sub = 1:number_of_subject
    [Subject_EEG{1,sub}] = ...
     mnet_prep_eeg(Raw_EEG_4task{1,sub},Event_4task{1,sub},option);
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
Group_ICA_4task = mnet_groupICA(Total_EEG);
Group_ICA_4task = pop_icflag(Group_ICA_4task,[0 0.7;0 0;0 0;0 0;0 0;0 0;0 0]);
Group_ICA_4task = pop_subcomp(Group_ICA_4task,find(Group_ICA_4task.reject.gcompreject == 1),0,0);

%% Generate HRSP with interpolation based on Individual & Group Components

for sub = 1:number_of_subject

    % Individual Components 

    EEG = Individual_ICA_4task{1,sub};
    EEG = pop_icflag(EEG,[0 0.7;0 0;0 0;0 0;0 0;0 0;0 0]);
    EEG = pop_subcomp(EEG,find(EEG.reject.gcompreject == 1),0,0);
    
    EEGs = Divided_4task_EEG{1,sub};
    ECGs = Divided_4task_ECG{1,sub};

    Total_HRSP = cell(1,number_of_task);
    for j = 1:number_of_task
        Total_HRSP{1,j} = mnet_extract_hrsp(EEGs{1,j},EEG.icaweights,[ECGs{1,j}.event.latency]);
    end

    X = ['Offline_Individual_HRSP_4task_',num2str(sub),' = Total_HRSP;']; eval(X)
    
    % Group Components 

    EEGs = Divided_4task_EEG{1,sub};
    ECGs = Divided_4task_ECG{1,sub};

    Total_HRSP = cell(1,number_of_task);
    for j = 1:number_of_task
        Total_HRSP{1,j} = mnet_extract_hrsp(EEGs{1,j},Group_ICA_4task.icaweights,[ECGs{1,j}.event.latency]);
    end

    X = ['Offline_Group_HRSP_4task_',num2str(sub),' = Total_HRSP;']; eval(X)

end

%% Trial by Trial Normalization 

HRSP_Norm_indi_4task  = cell(1,number_of_subject);
HRSP_Norm_group_4task = cell(1,number_of_subject);

number_of_task = 4;

for sub = 1:number_of_subject

    X = ['HRSP = Offline_Individual_HRSP_4task_',num2str(sub),';']; eval(X);    
    [HRSP_Norm_indi_4task{1,sub}]  = mnet_trial_by_trial_normalization(HRSP,number_of_task);
    
    X = ['HRSP = Offline_Group_HRSP_4task_',num2str(sub),';']; eval(X);    
    [HRSP_Norm_group_4task{1,sub}] = mnet_trial_by_trial_normalization(HRSP,number_of_task);

end

%% Single-trial Baseline Correction

Heart_HRSP_single_indi_4task = cell(1,number_of_subject);
Sound_HRSP_single_indi_4task = cell(1,number_of_subject);
Time_HRSP_single_indi_4task  = cell(1,number_of_subject);
Toes_HRSP_single_indi_4task  = cell(1,number_of_subject);

Heart_HRSP_single_group_4task = cell(1,number_of_subject);
Sound_HRSP_single_group_4task = cell(1,number_of_subject);
Time_HRSP_single_group_4task  = cell(1,number_of_subject);
Toes_HRSP_single_group_4task  = cell(1,number_of_subject);

for sub = 1:number_of_subject

    [Heart_HRSP_single_indi_4task{1,sub},Sound_HRSP_single_indi_4task{1,sub},Time_HRSP_single_indi_4task{1,sub},Toes_HRSP_single_indi_4task{1,sub}] = ...
     mnet_baseline_correction([],[],HRSP_Norm_indi_4task{1,sub},number_of_task,Event_4task{1,sub});  
    
    [Heart_HRSP_single_group_4task{1,sub},Sound_HRSP_single_group_4task{1,sub},Time_HRSP_single_group_4task{1,sub},Toes_HRSP_single_group_4task{1,sub}] = ...
     mnet_baseline_correction([],[],HRSP_Norm_group_4task{1,sub},number_of_task,Event_4task{1,sub});

end