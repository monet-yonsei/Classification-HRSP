%% After single-trial baseline correction, Classification Binary state data [Offline individual]

number_of_subject = 17;

%% Single-trial HRSP [Append all Single-trial HRSPs]

for sub = 1:number_of_subject

    Binary_Indi_Heart_HRSP_singletrial{1,sub} = ft_appendfreq([],Binary_Indi_Heart_HRSP_single{1,sub}{:});
    Binary_Indi_Sound_HRSP_singletrial{1,sub} = ft_appendfreq([],Binary_Indi_Sound_HRSP_single{1,sub}{:});

end

% Theta [5 ~ 8 Hz]
option = [];
option.freqband = [5 8];
option.output   = 2;
Acc_theta_single_indi = mnet_offline_individual(Binary_Indi_Heart_HRSP_singletrial,Binary_Indi_Sound_HRSP_singletrial,option);

% Alpha [9 ~ 12 Hz]
option = [];
option.freqband = [9 12];
option.output   = 2;
Acc_alpha_single_indi = mnet_offline_individual(heart_indi_single,Binary_Indi_Sound_HRSP_singletrial,option);

% Theta + Alpha [5 ~ 12 Hz]
option = [];
option.freqband = [5 12];
option.output   = 2;
Acc_thetaalpha_single_indi = mnet_offline_individual(heart_indi_single,Binary_Indi_Sound_HRSP_singletrial,option);

% Low beta [13 ~ 20 Hz]
option = [];
option.freqband = [13 20];
option.output   = 2;
Acc_lbeta_single_indi = mnet_offline_individual(heart_indi_single,Binary_Indi_Sound_HRSP_singletrial,option);

% Full frequency band [5 ~ 20 Hz]
option = [];
option.freqband = [5 20];
option.output   = 2;
Acc_entire_single_indi = mnet_offline_individual(heart_indi_single,Binary_Indi_Sound_HRSP_singletrial,option);

%% Average 3,5,7 and 9 single trial HRSPs
%  example) Average 5 HRSPs

number_of_averaging = 5;

for sub = 1:number_of_subject

    [heart_indi_averaging{1,sub},sound_indi_averaging{1,sub}] = ...
     mnet_average_HRSP(Heart_HRSP_single_indi{1,sub},Sound_HRSP_single_indi{1,sub},number_of_averaging);
    
    Total_heart_indi_averaging{1,sub} = ft_appendfreq([],heart_indi_averaging{1,sub}{:});
    Total_sound_indi_averaging{1,sub} = ft_appendfreq([],sound_indi_averaging{1,sub}{:});

end

% Theta [5 ~ 8 Hz]
option = [];
option.freqband = [5 8];
option.output   = 2;
Acc_theta_mean5_indi = mnet_offline_individual(Total_heart_indi_averaging,Total_sound_indi_averaging,option);