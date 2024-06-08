%% Extract HRSP for Sham peaks

function HRSP = mnet_extract_sham_hrsp(EEG,ICA,Rpeak,bin)
    
    % ICA activation = ICA weights * EEG Data    
    ICAACT = icaact(EEG.data,ICA,0);
    
    % Extract Braincomponent timeseris data & EEGLAB format    
    EEG         = eeg_emptyset();
    EEG.data    = ICAACT;
    EEG.times   = EEG.times;
    EEG.nbchan  = size(ICAACT,1);
    EEG.pnts    = size(ICAACT,2);
    EEG.trials  = 1;
    EEG.srate   = 250;
    EEG         = eeg_checkset(EEG);
    
    % Transform to Fieldtrip format and Transform with Morlet wavelet for HRSP
    ft_EEG         = eeglab2fieldtrip(EEG,'raw','none');
    option         = [];
    option.output  = 'pow';
    option.channel = {'all'};
    option.method  = 'wavelet';
    option.width   = 7;
    option.pad     = 'nextpow2';
    option.foi     = 5:bin:20;   
    option.toi     = ft_EEG.time{1,1};
    HRSP           = ft_freqanalysis(option,ft_EEG);
    
    % Calculate R-R interval with pre-detected R peaks
    RRI = diff(Rpeak)/250;
    RRI = [0 RRI];
    
    % Define epochtime based R peaks [-200ms ~ R ~ 600ms]
    Epochtimes = cell(1,length(RRI));
    for i = 1:length(RRI)   
        Epochtime = [Rpeak(1,i)-250*0.2 Rpeak(1,i)+250*0.6];
        if any(Epochtime < 1) || any(Epochtime > size(HRSP.powspctrm,3))
           continue
        else
           Epochtimes{1,i} = Epochtime;
        end  
    end
    
    % Index of R peaks, RRI, Epochtimes
    Total_R_data = [num2cell(Rpeak); num2cell(RRI); Epochtimes];
    
    % Fieldtrip Powspctrum format
    pow           = mnet_empty_powspctrm();
    pow.label     = HRSP.label;
    pow.dimord    = 'chan_freq_time';
    pow.powspctrm = [];
    pow.time      = -0.2:0.004:0.6; % [-200ms : 4ms : 600ms] with 250 Hz
    pow.freq      = HRSP.freq;

    % Inter Epochtime for Interpolation
    ETime = cell(1,length(Epochtimes));
    for i = 2:length(Epochtimes)-1
        try   
            if cell2mat(Total_R_data(2,i)) > 0.8 % Pre R peak duration
               Epochstart = cell2mat(Total_R_data(3,i));
               if ~isempty(Epochstart)
                  Epochstart = Epochstart(1,1);
               else
                  continue
               end
            else 
               duration   = cell2mat(Total_R_data(2,i))*250;
               duration   = round(duration*(0.25));
               Epochstart = cell2mat(Total_R_data(1,i))-duration;
            end
          
            if cell2mat(Total_R_data(2,i+1)) > 0.8 % Post R peak duration        
               Epochend = cell2mat(Total_R_data(3,i));
               Epochend = Epochend(1,2);
            else
               duration = cell2mat(Total_R_data(2,i+1))*250;
               duration = round(duration*(0.75));
               Epochend = cell2mat(Total_R_data(1,i))+duration;
            end  
            ETime{1,i} = [Epochstart Epochend];
        catch
            ETime{1,i} = [];
        end
    end
    
    % Delete empty data
    Rpeak(:,cellfun(@isempty,ETime)) = [];
    ETime(:,cellfun(@isempty,ETime)) = [];
    
    Single_HRSPs = cell(1,length(ETime));
    Total_pre    = cell(1,length(ETime));
    Total_post   = cell(1,length(ETime));

    for i = 1:length(ETime)
        
        % Pre-powspctrm [-200ms ~ R] : timepoint = 51
        if ETime{1,i}(1) > 0      
           pre_powspctrm = HRSP.powspctrm(:,:,ETime{1,i}(1):Rpeak(1,i));
        else
           pre_powspctrm = [];
        end

        % Fillmissing NaN value with boundary effect
        if any(isnan(pre_powspctrm),'all')
           fillmissed_pre = [];              
           for ch = 1:size(pre_powspctrm,1)
               old_pre = squeeze(pre_powspctrm(ch,:,:));
               old_pre = fillmissing(old_pre,'linear',1,'EndValues','nearest');
               fillmissed_pre = cat(3,fillmissed_pre,old_pre);
           end
           fillmissed_pre = permute(fillmissed_pre,[3 1 2]);
           pre_powspctrm  = fillmissed_pre;
        end

        % Interpolate pre-powspctrum if short RRI
        if ~isempty(pre_powspctrm)
            if size(pre_powspctrm,3) < 51
               new_pre_powspctrm = [];
               try   
                   for ch = 1:size(pre_powspctrm,1)
                       old_pre = squeeze(pre_powspctrm(ch,:,:));
                       [old_X, old_Y] = meshgrid(1:size(old_pre,2),1:size(old_pre,1));
                       [new_X, new_Y] = meshgrid(linspace(1,size(old_pre,2),51), 1:size(old_pre,1));
                       new_pre = interp2(old_X,old_Y,old_pre,new_X,new_Y,'linear');
                       new_pre_powspctrm = cat(3,new_pre_powspctrm,new_pre);
                   end 
                   new_pre_powspctrm = permute(new_pre_powspctrm,[3 1 2]);
                   pre_powspctrm     = new_pre_powspctrm;
               catch
                   pre_powspctrm = [];
               end  
            end
        end
        Total_pre{1,i} = pre_powspctrm;
    end

    for i = 1:length(ETime)
        
        % Post-powspctrm [R+1 ~ 600ms] : timepoint = 150
        if ETime{1,i}(2) < length(HRSP.time)
           post_powspctrm = HRSP.powspctrm(:,:,Rpeak(1,i)+1:ETime{1,i}(2));
        else
           post_powspctrm = [];
        end

        % Fillmissing NaN value with boundary effect
        if any(isnan(post_powspctrm),'all')
           fillmissed_post = [];              
           for ch = 1:size(post_powspctrm,1)
               old_post = squeeze(post_powspctrm(ch,:,:));
               old_post = fillmissing(old_post,'linear',1,'EndValues','nearest');
               fillmissed_post = cat(3,fillmissed_post,old_post);
           end
           fillmissed_post = permute(fillmissed_post,[3 1 2]);
           post_powspctrm = fillmissed_post;
        end

        % interpolate post-powspctrum if short RRI
        if size(post_powspctrm,3) < 150
           new_post_powspctrm = [];
           try
               for ch = 1:size(post_powspctrm,1)    
                   old_post = squeeze(post_powspctrm(ch,:,:));
                   [old_X, old_Y] = meshgrid(1:size(old_post,2),1:size(old_post,1));
                   [new_X, new_Y] = meshgrid(linspace(1,size(old_post,2),150), 1:size(old_post,1));
                   new_post = interp2(old_X,old_Y,old_post,new_X,new_Y,'linear');
                   new_post_powspctrm = cat(3,new_post_powspctrm,new_post);  
               end 
               new_post_powspctrm = permute(new_post_powspctrm,[3 1 2]);
               post_powspctrm     = new_post_powspctrm;
           catch
               post_powspctrm = [];
           end
        end
        Total_post{1,i} = post_powspctrm;
    end

    for i = 1:length(ETime)
        if any(isnan(Total_pre{1,i}),'all') || any(isnan(Total_post{1,i}),'all')
           Single_HRSPs{1,i} = [];
        else
           if ~isempty(Total_pre{1,i}) && ~isempty(Total_post{1,i})
               Powspctrm = cat(3,Total_pre{1,i},Total_post{1,i});
               pow.powspctrm = Powspctrm;
               Single_HRSPs{1,i} = pow;
           else
               Single_HRSPs{1,i} = [];
           end
        end
    end

    Single_HRSPs(:,cellfun(@isempty,Single_HRSPs)) = [];
    HRSP = ft_appendfreq([],Single_HRSPs{:});

end

function pow = mnet_empty_powspctrm()

pow           = [];
pow.label     = [];
pow.dimord    = [];
pow.freq      = [];
pow.time      = [];
pow.powspctrm = [];
pow.elec      = [];
pow.cfg       = [];

end