%% Train CNN models For Grad-CAM analysis

function varargout = mnet_train_for_gradcam(Total_Heart,Total_Sound)
    
    % Adjust HRSP's Timepoint, Frequency, Trials
    cfg = [];
    cfg.latency    = [-0.200 0.596]; % Timepoint -> 200 points
    cfg.frequency  = [5 20];         % Full Frequency band
    cfg.keeptrials = 'yes';          % option for keeptrials
    Total_Heart    = ft_freqdescriptives(cfg,Total_Heart);
    Total_Sound    = ft_freqdescriptives(cfg,Total_Sound);
    
    % Train data & label
    Traindata   = cat(1,Total_Heart.powspctrm,Total_Sound.powspctrm);
    Traindata   = reshape(Traindata,[size(Traindata,2),size(Traindata,3),size(Traindata,4),1,size(Traindata,1)]);  
    Trainlabel  = [ones(1,size(Total_Heart.powspctrm,1)) 2*ones(1,size(Total_Sound.powspctrm,1))];        
    Shuffle_idx = randperm(length(Trainlabel));
    Trainlabel  = Trainlabel(:,Shuffle_idx);
    Trainlabel  = categorical(Trainlabel);
    Traindata   = Traindata(:,:,:,:,Shuffle_idx);
    
    % 3D CNN classification model
    layers = make_cnn(Traindata,2,0);
  
    % Train with 5-Fold Cross Validation 
    kfold_val   = 5; 
    num_samples = length(Trainlabel);
    fold        = cvpartition(num_samples,'kfold',kfold_val);
    
    Trained_net = cell(1,5);
    Testdata    = cell(1,5);
    Testlabel   = cell(1,5);
    Trained_acc = cell(1,5);
    
    for i = 1:kfold_val
    
        train_idx  = fold.training(i);
        test_idx   = fold.test(i);
        
        traindata  = Traindata(:,:,:,:,train_idx);
        trainlabel = Trainlabel(:,train_idx);
    
        % Divide train & validation & testdata set
    
        testdata   = Traindata(:,:,:,:,test_idx);
        testlabel  = Trainlabel(:,test_idx);
    
        validdata  = traindata(:,:,:,:,1:round(length(trainlabel)*0.2));
        validlabel = trainlabel(:,1:round(length(trainlabel)*0.2));
    
        traindata  = traindata(:,:,:,:,round(length(trainlabel)*0.2)+1:end);
        trainlabel = trainlabel(:,round(length(trainlabel)*0.2)+1:end);
    
        % Set training option
        options = trainingOptions('adam',...
                          'InitialLearnRate',0.001,...
                          'LearnRateSchedule','piecewise',...
                          'MiniBatchSize',128,...
                          'MaxEpochs',30, ...
                          'Verbose',false,...
                          'LearnRateDropFactor',0.1,...
                          'LearnRateDropPeriod',10,...
                          'ValidationData',{validdata,validlabel},...
                          'ValidationFrequency',50,...
                          'ValidationPatience',5,...
                          'Shuffle','every-epoch',...
                          'Plots','none');
    
        % Train 3D CNN models
        Trained_net{1,i} = trainNetwork(traindata, trainlabel, layers, options); 
    
        % Accuracy
        prediction = classify(Trained_net{1,i},testdata)';
        accuracy   = zeros(1,length(prediction));
        for j = 1:length(accuracy)
            if prediction(1,j) == testlabel(1,j)
               accuracy(1,j) = 1;
            else
               accuracy(1,j) = 0;
            end
        end
   
        Testdata{1,i}    = testdata;
        Testlabel{1,i}   = testlabel;
        Trained_acc{1,i} = length(find(accuracy==1))/length(accuracy);
    
    end
    
    varargout{1} = Trained_net;
    varargout{2} = Testdata;
    varargout{3} = Testlabel;
    varargout{4} = Trained_acc;

end