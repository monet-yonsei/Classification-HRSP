function varargout = mnet_offline_groupica(Heart,Sound,freq,output)
    
    % Initial setting    
    Trained_net     = cell(17,5);
    Total_Testdata  = cell(1,17);
    Total_Testlabel = cell(1,17);
    Trained_acc     = zeros(17,5);

    %% Define Frequency

    Input_Heart = Heart;
    Input_Sound = Sound;
    
    for sub = 1:17
        cfg = [];
        cfg.latency        = [-0.200 0.596]; % Timepoint -> 200
        cfg.frequency      = freq;           % Frequency
        cfg.keeptrials     = 'yes';          % Keeptrials
        Input_Heart{1,sub} = ft_freqdescriptives(cfg,Input_Heart{1,sub});
        Input_Sound{1,sub} = ft_freqdescriptives(cfg,Input_Sound{1,sub});
    end
    
    %% Set Testdata & Testlabel
        
    for sub = 1:17
    
        % Test subject 
        Test_Heart_HRSP = Input_Heart{:,sub};
        Test_Sound_HRSP = Input_Sound{:,sub};
        Testdata        = cat(1,Test_Heart_HRSP.powspctrm,Test_Sound_HRSP.powspctrm);
        Testdata        = reshape(Testdata,[size(Testdata,2),size(Testdata,3),size(Testdata,4),1,size(Testdata,1)]);  
        Testlabel       = [ones(1,size(Test_Heart_HRSP.powspctrm,1)) zeros(1,size(Test_Sound_HRSP.powspctrm,1))];        
        
        % Shuffle
        Shuffle_idx = randperm(length(Testlabel));
        Testlabel   = Testlabel(:,Shuffle_idx);
        Testlabel   = categorical(Testlabel);
        Testdata    = Testdata(:,:,:,:,Shuffle_idx);

        Total_Testdata{1,sub}  = Testdata;
        Total_Testlabel{1,sub} = Testlabel;
    
    end
    
    %% Classification
      
    for sub = 1:17
        
        % Except one subject
        sub_index = setdiff(1:17,sub);
    
        % All Train subject's HRSP
        Train_Heart_HRSP = Input_Heart(:,sub_index);
        Train_Heart_HRSP = ft_appendfreq([],Train_Heart_HRSP{:});   
        Train_Sound_HRSP = Input_Sound(:,sub_index);
        Train_Sound_HRSP = ft_appendfreq([],Train_Sound_HRSP{:});
            
        % Train data & label
        Traindata   = cat(1,Train_Heart_HRSP.powspctrm,Train_Sound_HRSP.powspctrm);
        Traindata   = reshape(Traindata,[size(Traindata,2),size(Traindata,3),size(Traindata,4),1,size(Traindata,1)]);
        Trainlabel  = [ones(1,size(Train_Heart_HRSP.powspctrm,1)) zeros(1,size(Train_Sound_HRSP.powspctrm,1))];        
        Shuffle_idx = randperm(length(Trainlabel));
        Trainlabel  = Trainlabel(:,Shuffle_idx);
        Trainlabel  = categorical(Trainlabel);
        Traindata   = Traindata(:,:,:,:,Shuffle_idx);
           
        % CNN Layer
        if size(Traindata,2) == 4 
           layer = make_cnn(Traindata,output,1);
        else
           layer = make_cnn(Traindata,output,0);
        end
        
        % Train classification model      
        kfold_val   = 5; 
        num_samples = length(Trainlabel);
        fold        = cvpartition(num_samples, 'kfold', kfold_val);
        
        for i = 1:kfold_val
        
            train_idx  = fold.training(i);
            valid_idx  = fold.test(i);
            traindata  = Traindata(:,:,:,:,train_idx);
            trainlabel = Trainlabel(:,train_idx);      
            validdata  = Traindata(:,:,:,:,valid_idx);
            validlabel = Trainlabel(:,valid_idx);
        
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
        
            Trained_net{sub,i} = trainNetwork(traindata, trainlabel, layer, options); 
    
            % Use test dataset for classification accuracy
            prediction = classify(Trained_net{sub,i},Total_Testdata{1,sub})';
            accuracy   = zeros(1,length(prediction));
            for j = 1:length(accuracy)
                if prediction(1,j) == Total_Testlabel{1,sub}(1,j)
                   accuracy(1,j) = 1;
                else
                   accuracy(1,j) = 0;
                end
            end
            disp(length(find(accuracy==1))/length(accuracy))
            Trained_acc(sub,i) = length(find(accuracy==1))/length(accuracy);    
        end
    end

    varargout{1} = Trained_net;
    varargout{2} = Trained_acc;
    varargout{3} = Total_Testdata;
    varargout{4} = Total_Testlabel;

end

function layer = make_cnn(Data,output,freq_option)
         
         if freq_option == 0 % 5~12 Hz or 5~20 Hz or 13~20 [Zero Padding]
             
            dropratio = 0.2;
        
            layer = [ ...
                                
            image3dInputLayer([size(Data,1) size(Data,2) size(Data,3), 1])
                
            convolution3dLayer([1 3 5],16,'Stride',[1 1 1],'padding',0,'Name','CNN_1')
            batchNormalizationLayer
            reluLayer
            maxPooling3dLayer([1 2 2],'Stride',[1 1 2],'padding',0,'Name','Pool_1')
              
            convolution3dLayer([1 3 5],16,'Stride',[1 1 1],'padding',0,'Name','CNN_2')
            batchNormalizationLayer
            reluLayer    
            maxPooling3dLayer([1 2 2],'Stride',[1 1 2],'padding',0,'Name','Pool_2')
        
            convolution3dLayer([1 1 1],8,'Stride',[1 1 1],'padding',0,'Name','CNN_3')
            batchNormalizationLayer
            reluLayer      
            maxPooling3dLayer([1 2 4],'Stride',[1 2 2],'padding',0,'Name','Pool_3')
                   
            flattenLayer('Name','flatten','Name','Flatten')
            fullyConnectedLayer(128,'Name','fc_1')
            dropoutLayer(dropratio)
            fullyConnectedLayer(output,'Name','fc_2')
                
            softmaxLayer('Name','Softmax')
            classificationLayer];

         else % Theta or Alpha [Padding Same]

            dropratio = 0.2;
        
            layer = [ ...
                                
            image3dInputLayer([size(Data,1) size(Data,2) size(Data,3), 1])
                
            convolution3dLayer([1 3 5],16,'Stride',[1 1 1],'padding','same','Name','CNN_1')
            batchNormalizationLayer
            reluLayer
            maxPooling3dLayer([1 2 2],'Stride',[1 1 2],'padding','same','Name','Pool_1')
              
            convolution3dLayer([1 3 5],16,'Stride',[1 1 1],'padding','same','Name','CNN_2')
            batchNormalizationLayer
            reluLayer  
            maxPooling3dLayer([1 2 2],'Stride',[1 1 2],'padding','same','Name','Pool_2')
        
            convolution3dLayer([1 1 1],8,'Stride',[1 1 1],'padding','same','Name','CNN_3')
            batchNormalizationLayer
            reluLayer     
            maxPooling3dLayer([1 2 4],'Stride',[1 2 2],'padding','same','Name','Pool_3')
                   
            flattenLayer('Name','flatten','Name','Flatten')
            fullyConnectedLayer(128,'Name','fc_1')
            dropoutLayer(dropratio)
            fullyConnectedLayer(output,'Name','fc_2')
                
            softmaxLayer('Name','Softmax')
            classificationLayer];

         end
end