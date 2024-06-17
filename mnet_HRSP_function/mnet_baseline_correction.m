% -------------------------------------------------------------------------
% The function "mnet_baseline_correction" is After trial by trial normalization,
% Use for Baseline corretion with each single-trial HRSP with "ft_freqbaseline"
%
% Use as
%   ex) binary experimental data
%       [Binary_Indi_Heart_HRSP_Single{1,sub},Binary_Indi_Sound_HRSP_Single{1,sub}] = ...
%        mnet_baseline_correction(Binary_Indi_Heart_HRSP_Norm{1,sub},Binary_Indi_Sound_HRSP_Norm{1,sub},[],2,[]);  
% -------------------------------------------------------------------------

function varargout = mnet_baseline_correction(Heart_HRSP_Norm,Sound_HRSP_Norm,Norm_HRSP,number_of_task,event)
   
    if number_of_task == 2

        Heart_HRSP_BC = cell(1,10);
        Sound_HRSP_BC = cell(1,10);
    
        for i = 1:10   
            HRSP = Heart_HRSP_Norm{1,i};     
            Number_of_trial = size(HRSP.powspctrm,1);        
            New_HRSP = cell(1,Number_of_trial);
            for j = 1:Number_of_trial
                cfg = [];
                cfg.trials     = j;
                cfg.keeptrials = 'no';
                HRSP_DATA      = ft_freqdescriptives(cfg,HRSP);
    
                cfg = [];
                cfg.baseline     = [-0.200 -0.100];
                cfg.baselinetype = 'zscore';
                New_HRSP{1,j}    = ft_freqbaseline(cfg,HRSP_DATA);
            end
            Heart_HRSP_BC{1,i} = ft_appendfreq([],New_HRSP{:});
        end
    
        for i = 1:10   
            HRSP = Sound_HRSP_Norm{1,i};     
            Number_of_trial = size(HRSP.powspctrm,1);        
            New_HRSP = cell(1,Number_of_trial);
            for j = 1:Number_of_trial
                cfg = [];
                cfg.trials     = j;
                cfg.keeptrials = 'no';
                HRSP_DATA      = ft_freqdescriptives(cfg,HRSP);
                
                cfg = [];
                cfg.baseline     = [-0.200 -0.100];
                cfg.baselinetype = 'zscore';
                New_HRSP{1,j}    = ft_freqbaseline(cfg,HRSP_DATA);
            end
            Sound_HRSP_BC{1,i} = ft_appendfreq([],New_HRSP{:});
        end

        varargout{1} = Heart_HRSP_BC;
        varargout{2} = Sound_HRSP_BC;

        % -----------------------------------------------------------------
        % Four state experimental data

    elseif number_of_task == 4

        Total_New_HRSP = cell(1,20);

        for i = 1:20
        
            HRSP = Norm_HRSP{1,i};
            Number_of_trial = size(HRSP.powspctrm,1);
            New_HRSP = cell(1,Number_of_trial);
    
            for j = 1:Number_of_trial
                
                cfg = [];
                cfg.trials     = j;
                cfg.keeptrials = 'no';
                HRSP_DATA      = ft_freqdescriptives(cfg,HRSP);
                
                cfg = [];
                cfg.baseline     = [-0.200 -0.100];
                cfg.baselinetype = 'zscore';
                New_HRSP{1,j}    = ft_freqbaseline(cfg,HRSP_DATA);
    
            end
    
            Total_New_HRSP{1,i} = ft_appendfreq([],New_HRSP{:});
    
        end

        Heart_HRSPs = Total_New_HRSP(:,find(event == 1));   
        Sound_HRSPs = Total_New_HRSP(:,find(event == 2));   
        Time_HRSPs  = Total_New_HRSP(:,find(event == 3));     
        Toe_HRSPs   = Total_New_HRSP(:,find(event == 4));

        varargout{1} = Heart_HRSPs;
        varargout{2} = Sound_HRSPs;
        varargout{3} = Time_HRSPs;
        varargout{4} = Toe_HRSPs;

    else
        error('error with number of task')
    end
end