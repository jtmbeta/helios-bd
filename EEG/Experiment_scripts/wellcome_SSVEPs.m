function wellcome_SSVEPs(subject,TF,viewdist)

%subject - needs to be input as text, so like this: '1' for 1
% TF - temporal frequency, in Hz
% viewdist - viewing distance, in cm

%presents flickering stimuli that vary in contrast and measures SSVEPs to
%them 

%scripted by J Martinovic, 2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%---------------------------------------------------------
% initialise VSG-Card
%---------------------------------------------------------
global CRS;

crsInit('');                                    % default VSG initialisation
crsSetVideoMode(CRS.EIGHTBITPALETTEMODE+CRS.GAMMACORRECT); % make sure we are using basic CLUT mode
crsSetDrawMode(CRS.CENTREXY + CRS.SOLIDFILL);    % set draw mode co-ordinate system
crsSetViewDistMM(viewdist*10); %needs to be in milimeters
%monitor width in display++: 39.4
%display++ height: 39.4
%in 1080x1080 one pixel is 0.0365 x 0.0365 cm
%----------------------------------------------------------
%SET COLOUR PARAMETERS
%----------------------------------------------------------
% make a greyscale CLUT - 256x3 matrix, add colours to it
crsSetColourSpace(CRS.CS_RGB);	% use RGB space

%use Stockman & Sharpe (2000) cone fundamentals
Sensors = 'ConeSensitivities_SS_2degELin3908301.mat';
% Define which display device SPD to use.
deviceSPD = 'DisplayPlusPlus.mat';
%deviceSPD = 'ViewsonicP227f.mat';
%2 deg cmfs
SensorsCMF = 'CMF_CIE1931_2deg3608301.mat';

%choose white point
WP_xyY=[0.3127 0.3290 50];

[WP_RGB, ErrorCode] = ctGetColourTrival('CS_CIE1931xyY','CS_RGB',WP_xyY,deviceSPD,SensorsCMF);
if ErrorCode == -1, warning('THE REQUESTED WP COLOUR IS OUT OF RANGE'); end

WP_RGB=WP_RGB';

LUTBuff=repmat(WP_RGB,256,1);

white=[1,1,1]; %rgb white
LUTBuff(255,:)=white; 
backpix=256; %set background to 256

crsLUTBUFFERWrite(1,LUTBuff);     % load the CLUT into VSG LUT memory
crsLUTBUFFERtoPalette(1);           % make the whitepoint CLUT the current palette

crsSetDrawPage(CRS.VIDEOPAGE,1,backpix);  % clear draw page to grey
crsSetZoneDisplayPage(CRS.VIDEOPAGE,1);   % set display page to draw page

% read in mean results from HCFP
%---------------------------------
% these will have relLum_90, relLum_270, relLum_0, and relLum_180
result1=sprintf('C:/research/wellcome/results/flicker/%s.mat',subject);
eval(['load ' result1]);

delete(instrfindall);

%open communication with the cedrus button box
%------------------------------------------------
dev.link = serial('COM9', 'BaudRate', 115200, 'DataBits', 8, 'StopBits', 1,...
    'FlowControl', 'none', 'Parity', 'none', 'Terminator', 'CR', 'Timeout', 400,...
    'InputBufferSize', 16000);
fopen(dev.link);
% Set the device protocol to XID mode
fprintf(dev.link,'c10'); %c10 is the xid mode, which is the one that reads RTs
%fprintf(dev.link, '_d3'); %gets the model ID: 1 is RB530
%bytes = dev.link.BytesAvailable; if bytes==1, disp('RB530 is operational');
%fprintf(dev.link, '_d1'); %gets the name of the model
%bytes = dev.link.BytesAvailable;
%dev.Name = char([fread(dev.link,bytes)]')
% Reset base timer:
fprintf(dev.link,'e1');

% part of path, where data will be stored:
path_name='c:/research/wellcome/results/ssvep/';

%open file for results
if exist([path_name subject '_VEP.result'], 'file')
display('the file for this participant number already exists!')
return
else
    fid1=fopen(sprintf('%s%s_VEP.result',path_name,subject),'w');  
end
%each trial is recorded in a single line in this file

%------------------------------------------------------------------------------------
        %instructions
%------------------------------------------------------------------------------------
        str1='In this part of the study, you will see different flickering';
        str2=' patterns on the screen. Your task is to push a button when';
        str3='you see a pattern that is horizontally oriented. Please fixate ';
        str4='the cross in the middle of the pattern throughout. Try to refrain';
        str5='from blinking while the patterns are shown - feel free to blink ';
        str6='during the presentation of the grey screen between patterns.';
        str7=' ';
        str8='Once you are ready to start, press a button to continue.';
            
    ScrHeight=crsGetScreenHeightPixels;
    %Select a page in memory to draw onto.
    crsSetDrawPage(CRS.VIDEOPAGE,2, backpix);
    %Select pixel-level(1) to draw with - 255 IS WHITE
    crsSetPen1(255);
    %Load the true type font that you want to write with.
    crsSetTrueTypeFont('Arial.ttf');
    %Set the draw modes for the text i.e. centred, italic, angle, size.
    crsSetStringMode([0 ScrHeight/30], CRS.ALIGNLEFTTEXT, CRS.ALIGNTOPTEXT, 0, CRS.FONTNORMAL);
    %Change the drawing origin to the top-left of the page.
    crsSetDrawOrigin([0 0]);
    
    for s=1:8
        crsDrawString([10 10+s*42], eval( sprintf('str%i',s)));
    end
    
    %Display the page that the text was drawn onto.
    crsSetZoneDisplayPage(CRS.VIDEOPAGE,2);
    %read button press from response box
[~,~,dev]=cedrus_LR(dev);
    
    %display grey for 5 seconds before starting
    crsSetDrawPage(CRS.VIDEOPAGE,1, backpix);
    crsSetZoneDisplayPage(CRS.VIDEOPAGE,1);
   pause(5);
 
   %determine number of trials and conditions
   %-----------------------------------------
   % we have lower and higher contrasts in 3 mechanisms
     
rng(str2double(subject));
   convector = [];
   ctrials=44; %40 normal trials and 4 target ones per condition, with horizontal orientation
   cnum=12; %conditions as above
   %randomise order of conditions in the block
   crand=randperm(cnum);
   for condnum=1:cnum
   convector = [convector repmat(crand(condnum),1,ctrials)];
   end
   
   ch=exist(sprintf('c:/%s/%s_%s_conds.txt',path_name,subject,num2str(TF)));
if ch == 0		% file doesn't exist, create it
   save([path_name subject '_' num2str(TF) '_conds.txt'],'convector','-ascii');
else
    disp('save file already exists! please recheck participant number or other inputs.')
    return    
 end
   
 %make random diagonal angles to be interspersed with some horizontal
%ones
angs=15:165;
rando=randperm(length(angs));
possible_angles=[angs(rando) angs(rando) angs(rando) angs(rando) angs(rando) angs(rando)];
ntrials=length(convector);  
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PRACTICE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% start training
repeat_training = 0;

%determine practice conditions
pracconds=convector(45:60); %assign some conditions to practice from bl2

%check whether to skip training
%--------------------------------
%Select a page in memory to draw onto.
crsSetDrawPage(CRS.VIDEOPAGE,12, backpix);
% select Pen to draw with
crsSetPen1(255);

crsDrawString([10 82], 'Do training? Left=yes, right=no');

%Display the page that the text was drawn onto.
crsSetZoneDisplayPage(CRS.VIDEOPAGE,12);

[answer,~,dev]=cedrus_LR(dev);

   if answer == 1, repeat_training = 0;
elseif answer == 3, repeat_training = 1;
   end

while repeat_training == 0
    
     %grey adaptation
    %Select a page in memory to draw onto.
    crsSetDrawPage(CRS.VIDEOPAGE,6, backpix);
    crsSetZoneDisplayPage(CRS.VIDEOPAGE,6);
    pause(4);
    
       %DECide which of the 16 practice trials will be the two targets
    targets=randperm(length(pracconds));
    targets=targets(1:2); %TAKe out 2 of them
    
    feedback_corr =0; %initialise feedback
    feedback_rt=0;
    numfor_rt=0;

    % start presentation-loop
    for j = 1:length(pracconds)

     %if this is meant to be a target trial, overrule the angle to
        %horizontal
        if ismember(j,targets) %check if it should be a target
            gabor_angle = 0; 
        else
        gabor_angle=possible_angles(j);
        end
        
        cond=pracconds(j);
        
        %%%%%%%%%%%%%%%%%
        %display stimuli
        %%%%%%%%%%%%%%%%%
        % display the overall number of trials so far
        disp('-------------------');
         disp('Overall trial no.:');
        disp(num2str(j));
        disp('Condition');
        disp(num2str(cond));
        
        %display trial
        [dev,res,rt] = wellcome_SSVEP_trial(cond,backpix,Sensors,deviceSPD,WP_RGB,LUTBuff,gabor_angle,TF,relLum_0,relLum_90,relLum_180,relLum_270,Scs,Lumcs,dev);

        if gabor_angle==0 && ~isempty(res)
            hit=1;
            disp('hit!')
        elseif gabor_angle==0 && isempty(res)  %missed
            hit=0;
            disp('missed target!')
                elseif gabor_angle~=0 && isempty(res)  %correct rejection
            hit=1;
            disp('correct rejection!')
            elseif gabor_angle~=0 && ~isempty(res)  %false alarm
            hit=0;
            disp('false alarm -not horizontal!')
        end
        
        if hit == 1, feedback_corr = feedback_corr+1; end
        if hit == 1, feedback_rt = feedback_rt+rt; numfor_rt=numfor_rt+1; end

    end
    
    % generate sound for acoustic feedback - at the end of blocks
    %y=sin([1:1024]);
    y1=sin(0.5*[1:1024]);
    sound([y1 y1 y1 y1])
    
    disp ('!!!! Training finished !!!!');
       disp(' ');
       disp(feedback_corr/length(pracconds)); disp('proportion hits');
       disp(' ');
    disp(feedback_rt/numfor_rt); disp('Reaction Time');
  
    %change centre of drawing back to top left
    crsSetDrawOrigin([0 0]);
    
    %Select a page in memory to draw onto.
    crsSetDrawPage(CRS.VIDEOPAGE,1, backpix);
    
    str1='Training is over!';
    str2='Please wait for the experimenter.';
    
    for s=1:2
        crsDrawString([10 10+s*72], eval([ sprintf('str%i',s)]));
    end
    
    %Display the page that the text was drawn onto.
    crsSetZoneDisplayPage(CRS.VIDEOPAGE,1);
    
[~,~,dev]=cedrus_LR(dev);
    
    %Select a page in memory to draw onto.
    crsSetDrawPage(CRS.VIDEOPAGE,6, backpix);
    
    crsDrawString([10 82], 'Repeat training? Left=yes, right=no');
    
    %Display the page that the text was drawn onto.
    crsSetZoneDisplayPage(CRS.VIDEOPAGE,6);
    
[res,~,dev]=cedrus_LR(dev);
    
    if res == 1, repeat_training = 0;
    elseif res == 3, repeat_training = 1;
    end
    
       
end

   %%%%%%%%%%%%%%%%%%%%%%%%%%
   %EXPERIMENT PROPER
   %%%%%%%%%%%%%%%%%%%%%%%%%%
       %grey adaptation
    %Select a page in memory to draw onto.
    crsSetDrawPage(CRS.VIDEOPAGE,6, backpix);
    crsSetZoneDisplayPage(CRS.VIDEOPAGE,6);
    pause(5);  
   
   %counter for blocks
   block=1;
   
   %reset feedback parameters
feedback_corr=0;
feedback_rt=0;
numfor_rt=0;

   %DECide which of the trials will be the targets
   targets=[];
   for ra=1:cnum
   temp=randperm(ctrials);
   temp=temp(1:floor(ctrials/10))+(ra-1)*ctrials; % randomly permute target positions
    targets=[targets temp]; %add this block's targets to the set
   end

    %go through the trials for each phase
    for trial = 1:ntrials
        
             if ismember(trial,targets) %check if it should be a target
            gabor_angle = 0; 
        else
        gabor_angle=possible_angles(trial);
        end
                   
        cond=convector(trial);
        
        %%%%%%%%%%%%%%%%%
        %display stimuli
        %%%%%%%%%%%%%%%%%
        % display the overall number of trials so far
        disp('-------------------');
         disp('Overall trial no.:');
        disp(num2str(trial));
        disp('Condition');
        disp(num2str(cond));
        
        %display trial
    [dev,res,rt] = wellcome_SSVEP_trial(cond,backpix,Sensors,deviceSPD,WP_RGB,LUTBuff,gabor_angle,TF,relLum_0,relLum_90,relLum_180,relLum_270,dev);
        
        if gabor_angle==0 && ~isempty(res)
            hit=1;
            disp('hit!')
        elseif gabor_angle==0 && isempty(res)  %missed
            hit=0;
            disp('missed target!')
                elseif gabor_angle~=0 && isempty(res)  %correct rejection
            hit=1;
            disp('correct rejection!')
            elseif gabor_angle~=0 && ~isempty(res)  %false alarm
            hit=0;
            disp('false alarm -not horizontal!')
        end
        
        if hit == 1, feedback_corr = feedback_corr+1; end
        if hit == 1, feedback_rt = feedback_rt+rt; numfor_rt=numfor_rt+1; end

        % write to result file - trial,condition,orientation,response,its accuracy, rt
    fprintf(fid1,'%i\t %i\t %i\t %i\t %.5f\n',j,cond,gabor_angle,hit,rt);       

    %%%%%%%%%%%%%%%%%
    %pause between blocks
    %%%%%%%%%%%%%%%%%
    if rem(trial,ctrials)==0 
               
         disp('-------------------');
         disp('participant break');
         disp('-------------------');
     disp(' ');
               disp(feedback_corr/ctrials); disp('proportion hits');
                disp(' ');
    disp(feedback_rt/numfor_rt); disp('Reaction Time');

            %reset feedback parameters
feedback_corr=0;
feedback_rt=0;
numfor_rt=0;

        block=block+1; %used for determining gabor orientation
                 
        % generate sound for acoustic feedback - at the end of blocks
        y1=sin(0.5*[1:1024]);
        sound([y1 y1])
               
        %Select a page in memory to draw onto.
        crsSetDrawPage(CRS.VIDEOPAGE,1, backpix);
        %change centre of drawing back to top left
        crsSetDrawOrigin([0 0]);
        %Select pixel-level(1) to draw with
        crsSetPen1(255);
        crsDrawString([10 82], 'press any button to continue');
        %Display the page that the text was drawn onto.
        crsSetZoneDisplayPage(CRS.VIDEOPAGE,1);
      [~,~,dev]=cedrus_LR(dev);
  %now draw another page to continue
        %Select a page in memory to draw onto.
        crsSetDrawPage(CRS.VIDEOPAGE,8, backpix);
        crsDrawString([10 82],'Press any button to continue');
        %Display the page that the text was drawn onto.
        crsSetZoneDisplayPage(CRS.VIDEOPAGE,8);
[~,~,dev]=cedrus_LR(dev);
        
              %grey adaptation
    %Select a page in memory to draw onto.
    crsSetDrawPage(CRS.VIDEOPAGE,6, backpix);
    crsSetZoneDisplayPage(CRS.VIDEOPAGE,6);
    pause(5);  

    end

        
    end  %end of trial loop
    
disp('end of experiment');

%CLOSE file with beh data
fclose(fid1);

%----------------------------------------------
%draw end text
%Select a page in memory to draw onto.
crsSetDrawPage(CRS.VIDEOPAGE,2, backpix);
%Select pixel-level(1) to draw with
crsSetPen1(255);
%Load the true type font that you want to write with.
crsSetTrueTypeFont('Arial.ttf');
%Set the draw modes for the text i.e. centred, italic, angle, size.
crsSetStringMode([0 ScrHeight/30], CRS.ALIGNLEFTTEXT, CRS.ALIGNTOPTEXT, 0, CRS.FONTNORMAL);
%Change the drawing origin to the top-left of the page.
crsSetDrawOrigin([0 0]);

%Draw some text.
str1='Thank you for participating in this part of the experiment!';
crsDrawString([10 82], eval( sprintf('str1')));

%Display the page that the text was drawn onto.
crsSetZoneDisplayPage(CRS.VIDEOPAGE,2);

    y1=sin(0.5*[1:1024]);
    sound([y1 y1 y1 y1])
