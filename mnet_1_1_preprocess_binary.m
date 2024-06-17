%% Preprocess from Raw Binary experimental data (N=17)
%  Offline individual HRSP & Offline group HRSP

%  Raw_EEG : load ETH datasets
%  [30,31,32,33,34,35,36,39,40_2,41,42,43,44,45,47,48,49]
%  Event   : load ETH event datasets

number_of_subject = 17;
number_of_task    = 10;

%% Common Preprocess [binary experimental data] 
%-> Divide each task EEG 

option = [];
option.number_of_task = 2;
option.divide         = 'yes';
option.individual_ICA = [];

for sub = 1:number_of_subject
    [Binary_hearttask{1,sub},Binary_soundtask{1,sub}] = ...
     mnet_prep_eeg(Raw_EEG{1,sub},Event{1,sub},option);
end

%% Preprocess binary experimental data
%-> For Individual ICA

option = [];
option.number_of_task = 2;
option.divide         = 'no';
option.individual_ICA = 'yes';

for sub = 1:number_of_subject
    [Binary_Individual_ICA{1,sub}] = ...
     mnet_prep_eeg(Raw_EEG{1,sub},Event{1,sub},option);
end

%% Preprocess binary experimental data
%-> For Group ICA

option = [];
option.number_of_task = 2;
option.divide_task    = 'no';
option.individual_ICA = 'no';

for sub = 1:number_of_subject
    [Subject_EEG{1,sub}] = ...
     mnet_prep_eeg(Raw_EEG{1,sub},Event{1,sub},option);
end

% Merge all subject's entire EEG
for sub = 1:number_of_subject
    if sub == 1       
       Total_EEG = Subject_EEG{1,sub};
       Total_EEG = pop_rmbase(Total_EEG,[],[]);
    else
       Plus_EEG  = Subject_EEG{1,sub};
       Plus_EEG  = pop_rmbase(Plus_EEG,[],[]);
       Total_EEG = pop_mergeset(Total_EEG,Plus_EEG,0);
    end
end

% Group ICA
Binary_Group_ICA = mnet_groupICA(Total_EEG);
Binary_Group_ICA = pop_icflag(Binary_Group_ICA,[0 0.9;0 0;0 0;0 0;0 0;0 0;0 0]);
Binary_Group_ICA = pop_subcomp(Binary_Group_ICA,find(Binary_Group_ICA.reject.gcompreject == 1),0,0);