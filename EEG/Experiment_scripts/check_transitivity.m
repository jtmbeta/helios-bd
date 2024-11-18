function check_transitivity(subject)

%CALCULAtes salience for this observer, recorded using the
%adjustment_salience_matching.m script
%
%for wellcome project
%
%j martinovic, 2024

path_name='c:/research//wellcome/results/salience/';

data = load([path_name subject '_transit.result'],'convector','-ascii');

ncond=4; %number of conditions

%match S to L-M, 4 levels - that's first 4 conditions
%match lum to L-M, 4 levels - that's conds 5-8

meanc=zeros(ncond,1);

for n=1:ncond
    
    conddata=data((data(:,2)==n),:);
   
    meanc(n)=mean(conddata(:,6));
    
end

% read in mean results for this participant
% these will have Scs and Lumcs from the salience measurement
result1=sprintf('C:/research/wellcome/results/flicker/%s.mat',subject);
eval(['load ' result1]);

%express difference as % of lum contrasts measured for L-M standard
diff=(meanc-Lumcs)./ Lumcs * 100;

