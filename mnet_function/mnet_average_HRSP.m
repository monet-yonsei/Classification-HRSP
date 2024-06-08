%% Average single-trial HRSP for Multi-trial HRSP

function [Mean_Heart_HRSP,Mean_Sound_HRSP] = mnet_average_HRSP(Heart_HRSP_Single,Sound_HRSP_Single,number)

    Mean_Heart_HRSP = cell(1,10);
    Mean_Sound_HRSP = cell(1,10);

    for i = 1:10

        HRSP = Heart_HRSP_Single{1,i};
        Sidx = createSlidingWindows(size(HRSP.powspctrm,1),number); 
        New_HRSP = cell(1,size(Sidx,1));
        
        for j = 1:size(Sidx,1)

            cfg = [];
            cfg.trials     = Sidx(j,:);
            cfg.keeptrials = 'no';
            New_HRSP{1,j}  = ft_freqdescriptives(cfg,HRSP);
            
        end

        Mean_Heart_HRSP{1,i} = ft_appendfreq([],New_HRSP{:});

    end

    for i = 1:10

        HRSP = Sound_HRSP_Single{1,i};
        Sidx = createSlidingWindows(size(HRSP.powspctrm,1),number); 
        New_HRSP = cell(1,size(Sidx,1));
       
        for j = 1:size(Sidx,1)

            cfg = [];
            cfg.trials     = Sidx(j,:);
            cfg.keeptrials = 'no';
            New_HRSP{1,j}  = ft_freqdescriptives(cfg,HRSP);
            
        end

        Mean_Sound_HRSP{1,i} = ft_appendfreq([],New_HRSP{:});

    end
end

%%

function slidingWindows = createSlidingWindows(dataLength, windowSize)    
    data = 1:dataLength;
    numWindows = dataLength - windowSize + 1;
    slidingWindows = zeros(numWindows, windowSize);
    for i = 1:numWindows
        slidingWindows(i, :) = data(i:i+windowSize-1);
    end    
end
