function wellcome_VEPs(subject,viewdist)

%presents pattern onset stimuli at two contrast levels and measures VEPs to
%them, testing all 3 retinogeniculate mechanisms and their combinations
%
%this is the VEP experiment for the wellcome funded Helios-BD project
%
%inputs:
%subject - needs to be input as text, so like this: '1' for 1 (the
%          isoluminant settings that get loaded depend on this)
%viewdist - input viewing distance in cm, e.g. 70

%scripted by J Martinovic, 2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%---------------------------------------------------------
% initialise VSG-Card
%---------------------------------------------------------
global CRS;

crsSetVideoMode(CRS.EIGHTBITPALETTEMODE+CRS.GAMMACORRECT); % make sure we are using basic CLUT mode
crsSetDrawMode(CRS.CENTREXY + CRS.SOLIDFILL);    % set draw mode co-ordinate system
crsSetViewDistMM(viewdist*10); %in milimeters
crsSetSpatialUnits( CRS.PIXELUNIT); %for text display, it is in pixel units
%----------------------------------------------------------
%SET COLOUR PARAMETERS
%----------------------------------------------------------
% make a greyscale CLUT - 256x3 matrix, add colours to it
crsSetColourSpace(CRS.CS_RGB);	% use RGB space

%use Stockman & Sharpe (2000) cone fundamentals
Sensors = 'ConeSensitivities_SS_2degELin3908301.mat';
% Define which display device SPD to use.
%deviceSPD = 'DisplayPlusPlus.mat';
deviceSPD = 'ViewsonicP227f.mat';
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

delete(instrfindall);

%open communication with the cedrus button box
%------------------------------------------------
dev.link = serial('COM14', 'BaudRate', 115200, 'DataBits', 8, 'StopBits', 1,...
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
path_name='C:/research/wellcome/results/vep/';

% read in mean results from HCFP
%---------------------------------
% these will have relLum_90, relLum_270, relLum_0, and relLum_180
result1=sprintf('C:/research/wellcome/results/flicker/%s.mat',subject);
eval(['load ' result1]);

%------------------------------------------------------------------------------------
%instructions
str1='In this part of the study, you will see different patterns';
str2='appearing on the screen. Please fixate the cross in the';
str3='middle of the pattern. You can blink once the pattern';
str4='disappears. The next pattern will appear after a few seconds.';
str5='You do not have to do any specific task, apart from paying';
str6='attention to the patterns.';
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
crsSetStringMode([0 ScrHeight/24], CRS.ALIGNLEFTTEXT, CRS.ALIGNTOPTEXT, 0, CRS.FONTNORMAL);
%Change the drawing origin to the top-left of the page.
crsSetDrawOrigin([0 0]);

for s=1:8
    crsDrawString([10 10+s*42], eval( sprintf('str%i',s)));
end

%Display the page that the text was drawn onto.
crsSetZoneDisplayPage(CRS.VIDEOPAGE,2);
%read button press from response box
[~,~,dev]=cedrus_LR(dev);

%display grey for 2 seconds before starting
crsSetDrawPage(CRS.VIDEOPAGE,1, backpix);
crsSetZoneDisplayPage(CRS.VIDEOPAGE,1);
pause(2);

%determine number of trials and conditions
%-----------------------------------------
% we have low and high contrasts, with 3 mechanisms, measuring unipolar and bipolar Gabors
%this is the design:
%cond 1 - lower lum, gabor
%cond 2 - mid lum, gabor
%cond 3 - higher lum, gabor
%cond 4 - lower L-M , gabor
%cond 5 - mid L-M , gabor
%cond 6 - higher L-M , gabor
%cond 7 - lower S-(L+M) , gabor
%cond 8 - mid S-(L+M), gabor
%cond 9 - higher S-(L+M), gabor

rng('shuffle');
convector = [];
ctrials=60;
cnum=12; %we have conditions as above

%randomise order of conditions in the block
crand=randperm(cnum);
for condnum=1:cnum
    convector = [convector repmat(crand(condnum),1,ctrials)];
end

% if strcmp(subject,'1')
% convector=load([path_name subject '_conds.txt']);
% else
ch=exist(sprintf('c:/%s/%s_conds.txt',path_name,subject));
if ch == 0		% file doesn't exist, create it
save([path_name subject '_conds.txt'],'convector','-ascii');
else
    disp('save file already exists! please recheck participant number or other inputs.')
    return    
 end

%make random angles 
angs=1:360;
rando=randperm(length(angs));
possible_angles=[angs(rando) angs(rando) angs(rando)];
ntrials=length(convector);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PRACTICE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% start training
repeat_training = 0;

%determine practice conditions
pracconds=convector(130:146); %assign some conditions to practice
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
    
    % start presentation-loop
    for j = 1:length(pracconds)
        
        gabor_angle=possible_angles(j);
        
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
        wellcome_VEP_trial(cond,backpix,Sensors,deviceSPD,WP_RGB,LUTBuff,gabor_angle,relLum_0,relLum_90,relLum_180,relLum_270,viewdist);
        
    end
    
    % generate sound for acoustic feedback - at the end of blocks
    %y=sin([1:1024]);
    y1=sin(0.5*[1:1024]);
    sound([y1 y1 y1 y1])
    
    disp ('!!!! Training finished !!!!');
    
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
    
    crsDrawString([10 82], 'Do more training? Left=yes, right=no');
    
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

%go through the trials for each phase
for trial = 1:ntrials
   
    gabor_angle=possible_angles(trial);
    
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
    wellcome_VEP_trial(cond,backpix,Sensors,deviceSPD,WP_RGB,LUTBuff,gabor_angle,relLum_0,relLum_90,relLum_180,relLum_270,viewdist);
    
    %%%%%%%%%%%%%%%%%
    %pause between blocks
    %%%%%%%%%%%%%%%%%
    if rem(trial,ctrials)==0
        
        if block==12 %move forward as there is no block 13
            continue
        end
        
        block=block+1; %used for determining gabor orientation
        
        disp('-------------------');
        disp('participant break');
        disp('-------------------');
        
        % generate sound for acoustic feedback - at the end of blocks
        y1=sin(0.5*[1:1024]);
        sound([y1 y1])
        
        %Select a page in memory to draw onto.
        crsSetDrawPage(CRS.VIDEOPAGE,5, backpix);
        %change centre of drawing back to top left
        crsSetDrawOrigin([0 0]);
        %Select pixel-level(1) to draw with
        crsSetPen1(255);
        crsDrawString([10 82], 'Please wait for experimenter. Break.');
        %Display the page that the text was drawn onto.
        crsSetZoneDisplayPage(CRS.VIDEOPAGE,5);
        [~,~,dev]=cedrus_LR(dev);
        
        %now draw another page to continue
        %Select a page in memory to draw onto.
        crsSetDrawPage(CRS.VIDEOPAGE,8, backpix);
        crsDrawString([10 82],'Press button to continue');
        %Display the page that the text was drawn onto.
        crsSetZoneDisplayPage(CRS.VIDEOPAGE,8);
        [~,~,dev]=cedrus_LR(dev);
        
        %grey adaptation
        %Select a page in memory to draw onto.
        crsSetDrawPage(CRS.VIDEOPAGE,6, backpix);
        crsSetZoneDisplayPage(CRS.VIDEOPAGE,6);
        pause(4);
        
    end
    
end %end of trial loop

disp('end of experiment');

%----------------------------------------------
%draw end text
%Select a page in memory to draw onto.
crsSetDrawPage(CRS.VIDEOPAGE,2, backpix);
%Select pixel-level(1) to draw with
crsSetPen1(255);
%Load the true type font that you want to write with.
crsSetTrueTypeFont('Arial.ttf');
%Set the draw modes for the text i.e. centred, italic, angle, size.
crsSetStringMode([0 ScrHeight/26], CRS.ALIGNLEFTTEXT, CRS.ALIGNTOPTEXT, 0, CRS.FONTNORMAL);
%Change the drawing origin to the top-left of the page.
crsSetDrawOrigin([0 0]);

%Draw some text.
str1='Thank you for participating in the the experiment!';
crsDrawString([10 82], eval( sprintf('str1')));

%Display the page that the text was drawn onto.
crsSetZoneDisplayPage(CRS.VIDEOPAGE,2);