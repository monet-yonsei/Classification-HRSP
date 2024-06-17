%% Generate HRSP with interpolation method,
%  based on Individual ICA weights & Group ICA weights

number_of_subject = 17;
number_of_task    = 10;

for sub = 1:number_of_subject
    
    % ---------------------------------------------------------------------
    % Individual Components 

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
    % Group Components 
    
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

%% Trial by Trial Normalization 

Binary_Indi_Heart_HRSP_Norm  = cell(1,number_of_subject);
Binary_Indi_Sound_HRSP_Norm  = cell(1,number_of_subject);
Binary_Group_Heart_HRSP_Norm = cell(1,number_of_subject);
Binary_Group_Sound_HRSP_Norm = cell(1,number_of_subject);

number_of_task = 2;

for sub = 1:number_of_subject

    X = ['HRSP = Offline_Individual_HRSP_',num2str(sub),';']; eval(X);    
    [Binary_Indi_Heart_HRSP_Norm{1,sub},Binary_Indi_Sound_HRSP_Norm{1,sub}]   = mnet_trial_by_trial_normalization(HRSP,number_of_task);
    
    X = ['HRSP = Offline_Group_HRSP_',num2str(sub),';']; eval(X);    
    [Binary_Group_Heart_HRSP_Norm{1,sub},Binary_Group_Sound_HRSP_Norm{1,sub}] = mnet_trial_by_trial_normalization(HRSP,number_of_task);

end

%% Single-trial Baseline Correction

Binary_Indi_Heart_HRSP_Single  = cell(1,number_of_subject);
Binary_Indi_Sound_HRSP_Single  = cell(1,number_of_subject);  
Binary_Group_Heart_HRSP_Single = cell(1,number_of_subject);
Binary_Group_Sound_HRSP_Single = cell(1,number_of_subject);  

for sub = 1:number_of_subject

    [Binary_Indi_Heart_HRSP_Single{1,sub},Binary_Indi_Sound_HRSP_Single{1,sub}] = ...
     mnet_baseline_correction(Binary_Indi_Heart_HRSP_Norm{1,sub},Binary_Indi_Sound_HRSP_Norm{1,sub},[],2,[]);  
    
    [Binary_Group_Heart_HRSP_Single{1,sub},Binary_Group_Sound_HRSP_Single{1,sub}] = ...
     mnet_baseline_correction(Binary_Group_Heart_HRSP_Norm{1,sub},Binary_Group_Sound_HRSP_Norm{1,sub},[],2,[]);

end