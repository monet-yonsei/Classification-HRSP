%% Function [trial by trial normalization]

%  Use EEGLAB -> newtimeftrialbaseln
%  'trialbase' = ['on'|'off'|'full'] perform baseline (normalization or division 
%                  above in single trial instead of the trial average. Default
%                  if 'off'. 'full' is an option that perform single
%                  trial normalization (or simple division based on the
%                  'basenorm' input over the full trial length) before
%                  performing standard baseline removal. It has been
%                  shown to be less sensitive to noisy trials in Grandchamp R, 
%                  Delorme A. (2011) Single-trial normalization for event-related 
%                  spectral decomposition reduces sensitivity to noisy trials. 
%                  Front Psychol. 2:236.

function varargout = mnet_trial_by_trial_normalization(HRSP,number_of_task)
   
    if number_of_task == 2

        Heart_HRSP = HRSP{1,1};
        Sound_HRSP = HRSP{1,2};
                
        % Heart HRSP - Trial by trial normalization
        for i = 1:10
            FT = Heart_HRSP{1,i}.powspctrm(:,:,:,:);
            % Trial * Ch * Freq * Time -> Ch * Freq * Time * Trial
            FT = permute(FT,[2 3 4 1]);
            tmpbase = 1:size(FT,3);
            mbase   = mean(FT(:,:,tmpbase,:),3);
            mstd    = std(FT(:,:,tmpbase,:),[],3);
            FT      = bsxfun(@rdivide, bsxfun(@minus, FT, mbase), mstd);
            NewFT   = permute(FT,[4 1 2 3]);
            % Trial * Ch * Freq * Time
            Heart_HRSP{1,i}.powspctrm = NewFT;
        end
       
        % Sound HRSP - Trial by trial normalization
        for i = 1:10
            FT = Sound_HRSP{1,i}.powspctrm(:,:,:,:);
            % Trial * Ch * Freq * Time -> Ch * Freq * Time * Trial   
            FT = permute(FT,[2 3 4 1]);
            tmpbase = 1:size(FT,3);
            mbase   = mean(FT(:,:,tmpbase,:),3);
            mstd    = std(FT(:,:,tmpbase,:),[],3);
            FT      = bsxfun(@rdivide, bsxfun(@minus, FT, mbase), mstd);   
            NewFT   = permute(FT,[4 1 2 3]);
            % Trial * Channel * Frequency * Time
            Sound_HRSP{1,i}.powspctrm = NewFT; 
        end

        varargout{1} = Heart_HRSP;
        varargout{2} = Sound_HRSP;

    elseif number_of_task == 4

        New_HRSP = HRSP;

        % Trial by Trial normalization all task HRSPs
        for i = 1:20
            FT = HRSP{1,i}.powspctrm(:,:,:,:);
            % Trial * Ch * Freq * Time -> Ch * Freq * Time * Trial
            FT = permute(FT,[2 3 4 1]);
            tmpbase = 1:size(FT,3);
            mbase   = mean(FT(:,:,tmpbase,:),3);
            mstd    = std(FT(:,:,tmpbase,:),[],3);
            FT      = bsxfun(@rdivide, bsxfun(@minus, FT, mbase), mstd);
            NewFT = permute(FT,[4 1 2 3]);
            % Trial * Ch * Freq * Time
            New_HRSP{1,i}.powspctrm = NewFT;
        end

        varargout{1} = New_HRSP;

    else
        error('error with number of task')
    end
end