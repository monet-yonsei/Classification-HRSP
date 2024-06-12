%% Preprocess from Raw Binary experimental data (N=17) to Baseline corrected HRSP
%  Offline individual HRSP & Offline group HRSP

%  Raw_EEG : load ETH datasets
%  [30,31,32,33,34,35,36,39,40_2,41,42,43,44,45,47,48,49]
%  Event   : load ETH event datasets

number_of_subject = 17;
number_of_task    = 10;

%% Preprocess binary experimental data 
%  For Preprocess divided task EEGs 

option = [];
option.number_of_task = 2;
option.divide_task    = 'yes';
option.individual_ICA = [];

for sub = 1:number_of_subject
    [Divided_Heart_Tasks_2task_EEG{1,sub},Divided_Sound_Tasks_2task_EEG{1,sub},...
     Divided_Heart_Tasks_2task_ECG{1,sub},Divided_Sound_Tasks_2task_ECG{1,sub}] = ...
     mnet_prep_eeg(Raw_EEG{1,sub},Event{1,sub},option);
end

%% Preprocess binary experimental data
%  For Individual ICA weights

option = [];
option.number_of_task = 2;
option.divide_task    = 'no';
option.individual_ICA = 'yes';

for sub = 1:number_of_subject
    [Individual_ICA_2task{1,sub}] = ...
     mnet_prep_eeg(Raw_EEG{1,sub},Event{1,sub},option);
end

%% Preprocess binary experimental data
%  For Group ICA weights

option = [];
option.number_of_task = 2;
option.divide_task    = 'no';
option.individual_ICA = 'no';

for sub = 1:number_of_subject
    [Subject_EEG{1,sub}] = ...
     mnet_prep_eeg(Raw_EEG{1,sub},Event{1,sub},option);
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
Group_ICA_2task = mnet_groupICA(Total_EEG);
Group_ICA_2task = pop_icflag(Group_ICA_2task,[0 0.9;0 0;0 0;0 0;0 0;0 0;0 0]);
Group_ICA_2task = pop_subcomp(Group_ICA_2task,find(Group_ICA_2task.reject.gcompreject == 1),0,0);

%% Generate HRSP with interpolation based on Individual & Group Components

for sub = 1:number_of_subject

    % Individual Components 

    EEG = Individual_ICA_2task{1,sub};
    EEG = pop_icflag(EEG,[0 0.9;0 0;0 0;0 0;0 0;0 0;0 0]);
    EEG = pop_subcomp(EEG,find(EEG.reject.gcompreject == 1),0,0);
    
    HEEGs = Divided_Heart_Tasks_2task_EEG{1,sub};
    SEEGs = Divided_Sound_Tasks_2task_EEG{1,sub};

    Total_H_HRSP = cell(1,number_of_task);
    Total_S_HRSP = cell(1,number_of_task);

    for j = 1:number_of_task

        HEEG       = HEEGs{1,j};
        HEEG_Rpeak = [HEEG.event.latency];
        H_HRSP     = mnet_extract_hrsp(HEEG,EEG.icaweights,HEEG_Rpeak);

        SEEG       = SEEGs{1,j};
        SEEG_Rpeak = [SEEG.event.latency];
        S_HRSP     = mnet_extract_hrsp(SEEG,EEG.icaweights,SEEG_Rpeak);

        Total_H_HRSP{1,j} = H_HRSP;
        Total_S_HRSP{1,j} = S_HRSP;

    end

    X = ['Offline_Individual_HRSP_',num2str(sub),'{1,1} = Total_H_HRSP;']; eval(X)
    X = ['Offline_Individual_HRSP_',num2str(sub),'{1,2} = Total_S_HRSP;']; eval(X)

    % Group Components 
    
    HEEGs = Divided_Heart_Tasks_2task_EEG{1,sub};
    SEEGs = Divided_Sound_Tasks_2task_EEG{1,sub};

    Total_H_HRSP = cell(1,number_of_task);
    Total_S_HRSP = cell(1,number_of_task);

    for j = 1:number_of_task

        HEEG       = HEEGs{1,j};
        HEEG_Rpeak = [HEEG.event.latency];
        H_HRSP     = mnet_extract_hrsp(HEEG,Group_ICA_2task.icaweights,HEEG_Rpeak);

        SEEG       = SEEGs{1,j};
        SEEG_Rpeak = [SEEG.event.latency];
        S_HRSP     = mnet_extract_hrsp(SEEG,Group_ICA_2task.icaweights,SEEG_Rpeak);

        Total_H_HRSP{1,j} = H_HRSP;
        Total_S_HRSP{1,j} = S_HRSP;

    end

    X = ['Offline_Group_HRSP_',num2str(sub),'{1,1} = Total_H_HRSP;']; eval(X)
    X = ['Offline_Group_HRSP_',num2str(sub),'{1,2} = Total_S_HRSP;']; eval(X)

end

%% Trial by Trial Normalization 

Heart_HRSP_Norm_indi = cell(1,number_of_subject);
Sound_HRSP_Norm_indi = cell(1,number_of_subject);
Heart_HRSP_Norm_group = cell(1,number_of_subject);
Sound_HRSP_Norm_group = cell(1,number_of_subject);

number_of_task = 2;

for sub = 1:number_of_subject

    X = ['HRSP = Offline_Individual_HRSP_',num2str(sub),';']; eval(X);    
    [Heart_HRSP_Norm_indi{1,sub},Sound_HRSP_Norm_indi{1,sub}] = mnet_trial_by_trial_normalization(HRSP,number_of_task);
    
    X = ['HRSP = Offline_Group_HRSP_',num2str(sub),';']; eval(X);    
    [Heart_HRSP_Norm_group{1,sub},Sound_HRSP_Norm_group{1,sub}] = mnet_trial_by_trial_normalization(HRSP,number_of_task);

end

%% Single-trial Baseline Correction

Heart_HRSP_single_indi  = cell(1,number_of_subject);
Sound_HRSP_single_indi  = cell(1,number_of_subject);  
Heart_HRSP_single_group = cell(1,number_of_subject);
Sound_HRSP_single_group = cell(1,number_of_subject);  

for sub = 1:number_of_subject

    [Heart_HRSP_single_indi{1,sub},Sound_HRSP_single_indi{1,sub}] = ...
     mnet_baseline_correction(Heart_HRSP_Norm_indi{1,sub},Sound_HRSP_Norm_indi{1,sub},[],number_of_task,[]);  
    
    [Heart_HRSP_single_group{1,sub},Sound_HRSP_single_group{1,sub}] = ...
     mnet_baseline_correction(Heart_HRSP_Norm_group{1,sub},Sound_HRSP_Norm_group{1,sub},[],number_of_task,[]);

end