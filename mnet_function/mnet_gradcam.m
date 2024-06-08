%% Function - Grad-CAM anaylsis for Trained net and Testdata

function GradGAM = mnet_gradcam(Trained_net,Total_TD,Total_TL,num_of_repeat)

    % Find correct index for Grad-CAM anaylsis
    Total_Acc     = zeros(num_of_repeat,5);
    Total_Correct = cell(num_of_repeat,5);
    Total_Pred    = cell(num_of_repeat,5);  
    for Repeat = 1:num_of_repeat
        for fold = 1:5     
            Net  = Trained_net{1,Repeat}{1,fold};
            TD   = Total_TD{1,Repeat}{1,fold};
            TL   = Total_TL{1,Repeat}{1,fold};  
            Pred = classify(Net,TD)';
            Acc  = zeros(1,length(Pred));
            for j = 1:length(Acc)
                if Pred(1,j) == TL(1,j)
                   Acc(1,j) = 1;
                else
                   Acc(1,j) = 0;
                end
            end   
            Total_Acc(Repeat,fold)     = length(find(Acc==1))/length(Acc);
            Total_Correct{Repeat,fold} = Acc;
            Total_Pred{Repeat,fold}    = Pred;  
        end
    end

    % Grad-CAM anaylsis with Correct index
    % with True Heart HRSP & Pred Heart HRSP
    GradGAM = cell(num_of_repeat,5);
    for Repeat = 1:num_of_repeat
        for fold = 1:5   
            Net       = Trained_net{1,Repeat}{1,fold};
            TD        = Total_TD{1,Repeat}{1,fold};
            Pred      = Total_Pred{Repeat,fold};
            Correct   = Total_Correct{Repeat,fold};
            Total_map = cell(1,length(Pred));
            for j = 1:length(Pred)
                if Correct(1,j) == 1 && Pred(1,j) == '1' % True Heart && Pred Heart     
                   [classfn,~] = classify(Net,TD(:,:,:,:,j));
                   [Total_map{1,j}] = gradCAM(Net,TD(:,:,:,:,j),classfn);            
                end
            end
            Total_map = Total_map(:,~cellfun(@isempty,Total_map));
            GradGAM{Repeat,fold} = Total_map;
        end
    end
end