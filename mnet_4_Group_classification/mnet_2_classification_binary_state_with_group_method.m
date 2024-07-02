%% Use Binary state experimental data (HRSP) -> Classificatio with Leave-ont-out
number_of_subject = 17;
load Heart_HRSP_single_group
load Sound_HRSP_single_group

%% Append All Subject's Single-trial HRSPs

for sub = 1:number_of_subject

    Single_trial_Heart_group{1,sub} = ft_appendfreq([],Heart_HRSP_single_group{1,sub}{:});
    Single_trial_Sound_group{1,sub} = ft_appendfreq([],Sound_HRSP_single_group{1,sub}{:});

end

%% Define frequency for CNN model's input frequency

freq_band  = [5 20];
num_of_out = 2;

[Net_entire_single,Acc_entire_single,TD_entire_single,TL_entire_single] = ...
mnet_offline_groupica(Single_trial_Heart_group,Single_trial_Sound_group,freq_band,num_of_out);

%% Theta

freq_band   = [5 8];
num_of_out  = 2;

[~,Acc_theta_single,~,~] = ...
mnet_offline_groupica(Single_trial_Heart_group,Single_trial_Sound_group,freq_band,num_of_out);

%% Alpha 

freq_band   = [9 12];
num_of_out  = 2;

[~,Acc_alpha_single,~,~] = ...
mnet_offline_groupica(Single_trial_Heart_group,Single_trial_Sound_group,freq_band,num_of_out);

%% Theta + Alpha 

freq_band   = [5 12];
num_of_out  = 2;

[~,Acc_thetaalpha_single,~,~] = ...
mnet_offline_groupica(Single_trial_Heart_group,Single_trial_Sound_group,freq_band,num_of_out);

%% Low beta

freq_band   = [13 20];
num_of_out  = 2;

[~,Acc_lbeta_single,~,~] = ...
mnet_offline_groupica(Single_trial_Heart_group,Single_trial_Sound_group,freq_band,num_of_out);

%% Averaging multi-trial -> [example] Averaging 5 epochs

mean_number = 5;

for sub = 1:number_of_subject
    
    % Averaging single-trial HRSPs for multi-trial HRSPs
    [Mean_Heart_HRSPs{1,sub},Mean_Sound_HRSPs{1,sub}] = ...
     mnet_average_HRSP(Heart_HRSP_single_group{1,sub},Sound_HRSP_single_group{1,sub},mean_number);
    
    % Append All Subject's Single-trial HRSPs
    Total_heart_group_averaging{1,sub} = ft_appendfreq([],Mean_Heart_HRSPs{1,sub}{:});
    Total_sound_group_averaging{1,sub} = ft_appendfreq([],Mean_Sound_HRSPs{1,sub}{:});

end

freq_band   = [5 12];
num_of_out  = 2;

[~,Acc_thetaalpha_mean5,~,~] = ...
mnet_offline_groupica(Total_heart_group_averaging,Total_sound_group_averaging,freq_band,num_of_out);
