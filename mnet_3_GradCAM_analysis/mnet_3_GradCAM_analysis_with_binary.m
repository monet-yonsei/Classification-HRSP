%% Figure 6 - Grad-CAM
%  Use Group Components by Offline Group ICA

load Heart_HRSP_single_group
load Sound_HRSP_single_group

%% Grad-CAM analysis by Actual R peaks

for sub = 1:17
    Total_Heart_single{1,sub} = ft_appendfreq([],Heart_HRSP_single_group{1,sub}{:});
    Total_Sound_single{1,sub} = ft_appendfreq([],Sound_HRSP_single_group{1,sub}{:});
end

All_Heart_single = ft_appendfreq([],Total_Heart_single{:});
All_Sound_single = ft_appendfreq([],Total_Sound_single{:});

for Repeat = 1:5

    [Net_entire{1,Repeat},Testdata{1,Repeat},Testlabel{1,Repeat},Acc_entire{1,Repeat}] = ...
     mnet_train_for_gradcam(All_Heart_single,All_Sound_single);

end

GradCAM = mnet_gradcam(Net_entire,Testdata,Testlabel,Repeat);

%% Grad-CAM analysis by Sham R peaks

% Reject Non-brain independent components
% Use preprocessed Heart_EEG, Sound_EEG, Group_ICA 
% Group_ICA = pop_icflag(Group_ICA,[0 0.9;0 0;0 0;0 0;0 0;0 0;0 0]);
% Group_ICA = pop_subcomp(Group_ICA,find(Group_ICA.reject.gcompreject == 1),0,0);

%% Sham R peaks for Grad-CAM anaylsis

for Repeat = 1:10
    for i = 1:17
        
        ICA_weights  = Group_ICA.icaweights;
        HEEGs        = Heart_EEG{1,i};
        SEEGs        = Sound_EEG{1,i};
        Total_H_HRSP = cell(1,10);
        Total_S_HRSP = cell(1,10);
    
        for j = 1:10
            
            HEEG       = HEEGs{1,j};
            HEEG_Rpeak = [HEEG.event.latency];
            for k = 1:length(HEEG_Rpeak)
                HEEG_Rpeak(1,k) = HEEG_Rpeak(1,k) + randi([-125,125]);
            end
            HEEG_Rpeak = round(HEEG_Rpeak);
            HEEG_Rpeak = sort(HEEG_Rpeak);
            H_HRSP     = mnet_extract_sham_hrsp(HEEG,ICA_weights,HEEG_Rpeak,1);
            
            SEEG       = SEEGs{1,j};
            SEEG_Rpeak = [SEEG.event.latency];      
            for k = 1:length(SEEG_Rpeak)
                SEEG_Rpeak(1,k) = SEEG_Rpeak(1,k) + randi([-125,125]); 
            end
            SEEG_Rpeak = round(SEEG_Rpeak);
            SEEG_Rpeak = sort(SEEG_Rpeak);
            S_HRSP     = mnet_extract_sham_hrsp(SEEG,ICA_weights,SEEG_Rpeak,1);
          
            Total_H_HRSP{1,j} = H_HRSP;
            Total_S_HRSP{1,j} = S_HRSP;
    
        end
    
        X = ['Sham_HRSP_',num2str(i),'{1,1} = Total_H_HRSP;']; eval(X)
        X = ['Sham_HRSP_',num2str(i),'{1,2} = Total_S_HRSP;']; eval(X)
        
    end
        
    % Single Trial Baseline Correction   
    Heart_HRSP_Norm = cell(1,17);
    Sound_HRSP_Norm = cell(1,17);  
    for sub = 1:17
        X = ['HRSP = Sham_HRSP_',num2str(sub),';']; eval(X);    
        [Heart_HRSP_Norm{1,sub},Sound_HRSP_Norm{1,sub}] = mnet_trial_by_trial_normalization(HRSP);
    end
    
    % Single-trial Baseline Correction  
    Heart_HRSP_single = cell(1,17);
    Sound_HRSP_single = cell(1,17); 
    for sub = 1:17    
        [Heart_HRSP_single{1,sub},Sound_HRSP_single{1,sub}] = ...
         mnet_single_trial_baseline_correction(Heart_HRSP_Norm{1,sub},Sound_HRSP_Norm{1,sub});  
    end
    
    % Append all sham single-trial HRSP   
    Heart_HRSPs = cell(1,17);
    Sound_HRSPs = cell(1,17);  
    for sub = 1:17
        Heart_HRSPs{1,sub} = ft_appendfreq([],Heart_HRSP_single{1,sub}{:});
        Sound_HRSPs{1,sub} = ft_appendfreq([],Sound_HRSP_single{1,sub}{:});
    end
        
    All_sham_heart_single = ft_appendfreq([],Heart_HRSPs{:});
    All_sham_sound_single = ft_appendfreq([],Sound_HRSPs{:});
        
    [Sham_net{1,Repeat},Sham_testdata{1,Repeat},Sham_testlabel{1,Repeat},Sham_acc{1,Repeat}] = ...
    mnet_train_for_gradcam(All_sham_heart_single,All_sham_sound_single);

end

Sham_gradcam = mnet_gradcam(Sham_net,Sham_testdata,Sham_testlabel,Repeat);

%% Plot Grad-CAM analysis result
%  Actual R peaks [repeat 5 times]

repeat_data = cell(1,5);
for repeat = 1:5
    fold_data = cell(1,5);
    for fold = 1:5
        Data = GradCAM{repeat,fold};
        for i = 1:length(Data)
            Data{1,i} = rescale(Data{1,i});
        end
        fold_data{1,fold} = Data;
    end    
    repeat_data{1,repeat} = [fold_data{:}];
end

Total_data = [repeat_data{:}];
Total_data = cat(4,Total_data{:}); % size(Total_data,4) == 16063
Total_data = mean(Total_data,4);
Total_data = rescale(Total_data);

Data = Total_data;
freq = 5:1:20;
time = -0.2:0.004:0.6;
time = round(time,3);

fig = figure;
hold on
tiledlayout(4,3,'TileSpacing', 'Compact', 'Padding', 'Compact');
for channel = 1:11
    nexttile;
    imagesc(time,freq,squeeze(Data(channel,:,:)),[0 1])
    title(['Comp ',[ num2str(channel)]],'FontName','Arial Narrow','fontsize',25,'FontWeight','bold')
    xline(-0.1,'k:','LineWidth',2)
    xticks([-0.2 -0.1 0 0.2 0.4 0.6])
    set(gca, 'XTickLabel', get(gca,'XTickLabel'),'FontName','Arial Narrow','fontsize',25,'FontWeight','bold','LineWidth',2)
    axis xy
    colormap jet
end

x0=0;
y0=0;
width  = 1400;
height = 1000;
set(gcf,'position',[x0,y0,width,height])
sgtitle('Grad-CAM of actual R peaks','FontSize',40,'FontWeight','bold')

%% Sham R peaks [repeat 10 times]

repeat_data = cell(1,10);
for repeat = 1:10
    fold_data = cell(1,5);
    for fold = 1:5
        Data = Sham_gradcam{repeat,fold};
        for i = 1:length(Data)
            Data{1,i} = rescale(Data{1,i});
        end
        fold_data{1,fold} = Data;
    end    
    repeat_data{1,repeat} = [fold_data{:}];
end

Total_data = [repeat_data{:}];
Total_data = cat(4,Total_data{:}); % size(Total_data,4) == 32728
Total_data = mean(Total_data,4);
Total_data = rescale(Total_data);

Data = Total_data;
freq = 5:1:20;
time = -0.2:0.004:0.6;
time = round(time,3);
Clim = [0 1];

fig = figure;
hold on
tiledlayout(4,3,'TileSpacing', 'Compact', 'Padding', 'Compact');
for channel = 1:11
   nexttile;
   imagesc(time,freq,squeeze(Data(channel,:,:)),Clim)
   title(['Comp ',[ num2str(channel)]],'FontName','Arial Narrow','fontsize',25,'FontWeight','bold')
   xline(-0.1,'k:','LineWidth',2)
   xticks([-0.2 -0.1 0 0.2 0.4 0.6])
   set(gca, 'XTickLabel', get(gca,'XTickLabel'),'FontName','Arial Narrow','fontsize',25,'FontWeight','bold','LineWidth', 2)
   axis xy
   colormap jet
end

cb = colorbar(); 
cb.Layout.Tile = 'east';
cb.LineWidth   = 2;

x0=0;
y0=0;
width  = 1400;
height = 1000;
set(gcf,'position',[x0,y0,width,height])
sgtitle('Grad-CAM of sham R peaks','FontName','Arial Narrow','fontsize',40,'FontWeight','bold')
