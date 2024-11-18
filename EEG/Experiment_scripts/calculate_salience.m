function calculate_salience(subject,type)

%CALCULAtes salience for this observer, recorded using the
%adjustment_salience_matching.m script or its TF version
%
%need to input 'type' for whether it should do it for static or TF
%modulated stimuli. 1 for static, 2 for flickering.
%
%for wellcome project
%
%j martinovic, 2024

if type==1
path_name='c:/research//wellcome/results/salience/';
elseif type==2
    path_name='c:/research//wellcome/results/salienceTF/';
end

data = load([path_name subject '_matching.result'],'convector','-ascii');

ncond=8; %number of conditions

%match S to L-M, 4 levels - that's first 4 conditions
%match lum to L-M, 4 levels - that's conds 5-8

meanc=zeros(ncond,1);

for n=1:ncond
    
    conddata=data((data(:,2)==n),:);
   
    meanc(n)=mean(conddata(:,6));
    
end

%now add the averages into the file
filename=sprintf('%s.mat', subject);

if type==1
Scs=meanc(1:4); %first 4 are s 
Lumcs=meanc(5:8); %second 4 are lum
save(strcat('c:/research/wellcome/results/flicker/',filename),'Scs','Lumcs','-append');
elseif type==2
ScsTF=meanc(1:4); %first 4 are s 
LumcsTF=meanc(5:8); %second 4 are lum
save(strcat('c:/research/wellcome/results/flicker/',filename),'ScsTF','LumcsTF','-append');
end





