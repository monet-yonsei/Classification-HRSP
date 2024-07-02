%% Part 1. Preprocessing Raw EEG [Binary experimental data (N=17)]
%  1-1. Load Raw EEGs
%  1-2. Preprocess Binary experimental data (N=17)
%  1-3. Preprocess Binary experimental data (N=17) for Individual ICA
%  1-4. Preprocess Binary experimental data (N=17) for Group ICA

number_of_subject = 17;

%% 1-1. Load Raw EEGs

load('~\Event.mat')
load('~\Raw_EEG.mat')

% Raw_EEG : load ETH datasets
% Event   : load ETH event datasets (store.event)
% [30,31,32,33,34,35,36,39,40_2,41,42,43,44,45,47,48,49]

%% 1-2. Preprocess Binary experimental data (N=17)
%  Divide each task blocks after preprocessing 

option = [];
option.number_of_task = 2;
option.divide         = 'yes';
option.individual_ICA = [];

for sub = 1:number_of_subject
    [Binary_hearttask{1,sub},Binary_soundtask{1,sub}] = ...
     mnet_prep_eeg(Raw_EEG{1,sub},Event{1,sub},option);
end

%% 1-3. Preprocess Binary experimental data (N=17) for Individual ICA

option = [];
option.number_of_task = 2;
option.divide         = 'no';
option.individual_ICA = 'yes';

for sub = 1:number_of_subject
    [Binary_Individual_ICA{1,sub}] = ...
     mnet_prep_eeg(Raw_EEG{1,sub},Event{1,sub},option);
end

%% 1-4. Preprocess Binary experimental data (N=17) for Group ICA

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
Binary_Group_ICA = mnet_groupICA(Total_EEG);
Binary_Group_ICA = pop_icflag(Binary_Group_ICA,[0 0.9;0 0;0 0;0 0;0 0;0 0;0 0]);
Binary_Group_ICA = pop_subcomp(Binary_Group_ICA,find(Binary_Group_ICA.reject.gcompreject == 1),0,0);

%% Part 2. Generate HRSP [Binary experimental data (N=17)]
%  2-1. Generate HRSP with interpolation method based on Individual ICA weights & Group ICA weights
%  2-2. Trial by Trial Normalization for single-trial HRSP
%  2-3. Baseline Correction for single-trial HRSP

number_of_task = 10;

%% 2-1. Generate HRSP with interpolation method based on Individual ICA weights & Group ICA weights

for sub = 1:number_of_subject
     
    % Individual ICA weights 

    EEG = Binary_Individual_ICA{1,sub};
    EEG = pop_icflag(EEG,[0 0.9;0 0;0 0;0 0;0 0;0 0;0 0]);
    EEG = pop_subcomp(EEG,find(EEG.reject.gcompreject == 1),0,0);
    
    HEEGs = Binary_hearttask{1,sub};
    SEEGs = Binary_soundtask{1,sub};

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
    
    % ---------------------------------------------------------------------
    % Group ICA weights  

    HEEGs = Binary_hearttask{1,sub};
    SEEGs = Binary_soundtask{1,sub};

    Total_H_HRSP = cell(1,number_of_task);
    Total_S_HRSP = cell(1,number_of_task);

    for j = 1:number_of_task

        HEEG       = HEEGs{1,j};
        HEEG_Rpeak = [HEEG.event.latency];
        H_HRSP     = mnet_extract_hrsp(HEEG,Binary_Group_ICA.icaweights,HEEG_Rpeak);

        SEEG       = SEEGs{1,j};
        SEEG_Rpeak = [SEEG.event.latency];
        S_HRSP     = mnet_extract_hrsp(SEEG,Binary_Group_ICA.icaweights,SEEG_Rpeak);

        Total_H_HRSP{1,j} = H_HRSP;
        Total_S_HRSP{1,j} = S_HRSP;

    end

    X = ['Offline_Group_HRSP_',num2str(sub),'{1,1} = Total_H_HRSP;']; eval(X)
    X = ['Offline_Group_HRSP_',num2str(sub),'{1,2} = Total_S_HRSP;']; eval(X)

end

%% 2-2. Trial by Trial Normalization for single-trial HRSP

for sub = 1:number_of_subject

    X = ['HRSP = Offline_Individual_HRSP_',num2str(sub),';']; eval(X);    
    [Binary_Indi_Heart_HRSP_Norm{1,sub},Binary_Indi_Sound_HRSP_Norm{1,sub}]   = mnet_trial_by_trial_normalization(HRSP,2);
    
    X = ['HRSP = Offline_Group_HRSP_',num2str(sub),';']; eval(X);    
    [Binary_Group_Heart_HRSP_Norm{1,sub},Binary_Group_Sound_HRSP_Norm{1,sub}] = mnet_trial_by_trial_normalization(HRSP,2);

end

%% 2-3. Baseline Correction for single-trial HRSP

for sub = 1:number_of_subject

    [Binary_Indi_Heart_HRSP_Single{1,sub},Binary_Indi_Sound_HRSP_Single{1,sub}] = ...
     mnet_baseline_correction(Binary_Indi_Heart_HRSP_Norm{1,sub},Binary_Indi_Sound_HRSP_Norm{1,sub},[],2,[]);  
    
    [Binary_Group_Heart_HRSP_Single{1,sub},Binary_Group_Sound_HRSP_Single{1,sub}] = ...
     mnet_baseline_correction(Binary_Group_Heart_HRSP_Norm{1,sub},Binary_Group_Sound_HRSP_Norm{1,sub},[],2,[]);

end

save Binary_Indi_Heart_HRSP_Norm Binary_Indi_Heart_HRSP_Norm
save Binary_Indi_Sound_HRSP_Norm Binary_Indi_Sound_HRSP_Norm
save Binary_Group_Heart_HRSP_Norm Binary_Group_Heart_HRSP_Norm
save Binary_Group_Sound_HRSP_Norm Binary_Group_Sound_HRSP_Norm

save Binary_Indi_Heart_HRSP_Single Binary_Indi_Heart_HRSP_Single
save Binary_Indi_Sound_HRSP_Single Binary_Indi_Sound_HRSP_Single
save Binary_Group_Heart_HRSP_Single Binary_Group_Heart_HRSP_Single
save Binary_Group_Sound_HRSP_Single Binary_Group_Sound_HRSP_Single
