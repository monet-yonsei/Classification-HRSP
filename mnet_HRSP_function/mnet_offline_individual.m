% -------------------------------------------------------------------------
% The function "mnet_offline_individual" performs offline individual classification using heart and sound HRSP data.
% The HRSP data is processed to obtain frequency descriptives, and a 3D CNN
% is trained using a 5-fold cross-validation scheme to classify the data.
% 
% Input : 
%   Heart  - Cell array containing Heart HRSP for each subject.
%   Sound  - Cell array containing Sound HRSP for each subject.
%   option - Structure containing options for the classification, including frequency
% -------------------------------------------------------------------------

function Total_Accuracy = mnet_offline_individual(Heart,Sound,option)

    %% Define Frequency
      
    for sub = 1:17
    
        cfg = [];
        cfg.latency    = [-0.2 0.596];
        cfg.frequency  = option.freqband;
        cfg.keeptrials = 'yes';
        Heart{1,sub}   = ft_freqdescriptives(cfg,Heart{1,sub});
        Sound{1,sub}   = ft_freqdescriptives(cfg,Sound{1,sub});
    
    end
        
    %% Individual Classification
    %-> Repeat 5 Times

    Total_Accuracy = zeros(17,5);

    for r = 1:5
        for sub = 1:17
    
            Heart_HRSP = Heart{:,sub};
            Sound_HRSP = Sound{:,sub};
    
            % Totaldata & label
    
            Totaldata   = cat(1,Heart_HRSP.powspctrm,Sound_HRSP.powspctrm);
            Totaldata   = reshape(Totaldata,[size(Totaldata,2),size(Totaldata,3),size(Totaldata,4),1,size(Totaldata,1)]); 
            Totallabel  = [ones(1,size(Heart_HRSP.powspctrm,1)) zeros(1,size(Sound_HRSP.powspctrm,1))];       
            Shuffle_idx = randperm(length(Totallabel));
            Totallabel  = Totallabel(:,Shuffle_idx);
            Totallabel  = categorical(Totallabel);
            Totaldata   = Totaldata(:,:,:,:,Shuffle_idx);
      
            % 3D CNN Layer

            if size(Totaldata,2) == 4 

               layers = make_cnn(Totaldata,option.output,1);

            else

               layers = make_cnn(Totaldata,option.output,0);

            end

            % Train by 5-Fold Cross Validation
          
            kfold_val   = 5; 
            num_samples = length(Totallabel);
            fold        = cvpartition(num_samples, 'kfold', kfold_val);
            Accuracy    = zeros(1,5);
            
            for i = 1:kfold_val
            
                train_idx = fold.training(i);
                test_idx  = fold.test(i);

                % First, divide train & test dataset.
                
                traindata  = Totaldata(:,:,:,:,train_idx);
                trainlabel = Totallabel(:,train_idx);
     
                testdata   = Totaldata(:,:,:,:,test_idx);
                testlabel  = Totallabel(:,test_idx);

                % Second, extract validation dataset (20%) in traindata set.

                validdata  = traindata(:,:,:,:,1:round(length(trainlabel)*0.2));
                validlabel = trainlabel(:,1:round(length(trainlabel)*0.2));

                traindata  = traindata(:,:,:,:,round(length(trainlabel)*0.2)+1:end);
                trainlabel = trainlabel(:,round(length(trainlabel)*0.2)+1:end);
            
                % Set training option with minibatch size (32)

                options = trainingOptions('adam',...
                                  'InitialLearnRate',0.001,...
                                  'LearnRateSchedule','piecewise',...
                                  'MiniBatchSize',32,...
                                  'MaxEpochs',30, ...
                                  'Verbose',false,...
                                  'LearnRateDropFactor',0.1,...
                                  'LearnRateDropPeriod',10,...
                                  'ValidationData',{validdata,validlabel},...
                                  'ValidationFrequency',50,...
                                  'ValidationPatience',5,...
                                  'Shuffle','every-epoch',...
                                  'Plots','none');
            
                % Train 3D CNN Classification model

                trained_net = trainNetwork(traindata, trainlabel, layers, options); 
                
                % Predict & Calculate Accuracy with testdata

                pred = classify(trained_net,testdata)';
                acc  = zeros(1,length(pred));
                for j = 1:length(acc)
                    if pred(1,j) == testlabel(1,j)
                       acc(1,j) = 1;
                    else
                       acc(1,j) = 0;
                    end
                end
    
                Accuracy(1,i) = length(find(acc==1))/length(acc);
                disp(length(find(acc==1))/length(acc))
               
            end
    
            Total_Accuracy(sub,r) = mean(Accuracy);

        end
    end
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