function wellcome_PSE(subject,testh,viewdist)

% 2AFC task testing the point of isosalience for a chosen colour
%
% participants compare two simultaneously presented colours
%
%Side 1:    standard, fixed
%Side 2:    comparison, changes based on their responses
%
%input1: test hue, with the following options:
%1 - orange standard, judging redder colour
%2 - turquoise standard, judging bluer colour
%3 - white standard, judging darker colour
%
%input2: viewing distance in cm, e.g. 70
%
%one staircase goes from above, the other from below
%
%written by J Martinovic, 2023

%---------------------------------------------------------
% initialise VSG-Card
%---------------------------------------------------------
global CRS;

crsInit('');                                    % default VSG initialisation
crsSetVideoMode(CRS.EIGHTBITPALETTEMODE+CRS.GAMMACORRECT); % make sure we are using basic CLUT mode
crsSetDrawMode(CRS.CENTREXY + CRS.SOLIDFILL);    % set draw mode co-ordinate system

%Read the framerate for the vsg monitor
FrameRate = crsGetSystemAttribute(CRS.FRAMERATE);
%set spatial units
crsSetSpatialUnits( CRS.PIXELUNIT);
%Change the drawing origin to the top-left of the page.
crsSetDrawOrigin([0 0]);
%get screen parameters
ScrHeight=crsGetScreenHeightPixels;
ScrWidth=crsGetScreenWidthPixels;
%screen size in cm 
horsize=39; versize=29.6; %viewsonic
horpx=horsize/ScrWidth;
verpx=versize/ScrHeight;
pxsize=(horpx+verpx)/2;

delete(instrfindall);

% part of path, where data will be stored:
path='c:/research/wellcome/results/PSE/';

%----------------------------------------------------------
%SET COLOUR PARAMETERS
%----------------------------------------------------------
% make a greyscale CLUT - 256x3 matrix, add colours to it
crsSetColourSpace(CRS.CS_RGB);	% use RGB space
%set whitepoint to equialent of N5
WP_xyY=[0.3101 0.3162 19.27];

%use Stockman & Sharpe (2000) cone fundamentals
Sensors = 'ConeSensitivities_SS_2degELin3908301.mat';
% Define which display device SPD to use.
%deviceSPD = 'DisplayPlusPlus.mat';
deviceSPD = 'ViewsonicP227f.mat';
% Define which colour matching functions to use - CIE 1931 2-deg.
Sensors_CMF = 'CMF_CIE1931_2deg3608301.mat';

%get whitepoint
WP_RGB = ctGetColourTrival('CS_CIE1931xyY','CS_RGB',WP_xyY,deviceSPD,Sensors_CMF);

%now get the whitepoint coordinates in LAB, to build on the L value
xyzWhite=xyy2xyz(WP_xyY);
Whitelab=xyz2lab(xyzWhite,'D65/2');
Whitelch=lab2lch(Whitelab);

L=80; %this is stimulus L - in d15 lanthony it is value =8, equivalent to 57.62 cd nad L of 80
C=10; %this is stimulus C - this will have a range in munsell, as it is not hue independent

LUTBuff=repmat(WP_RGB',256,1);
white=[1,1,1]; %rgb white, for fixation
LUTBuff(255,:)=white; %white
backpix=256; %set background to 256
whitepix=255;

crsLUTBUFFERWrite(1,LUTBuff);     % load the CLUT into VSG LUT memory
crsLUTBUFFERtoPalette(1);           % make the whitepoint CLUT the current palette

crsSetDrawPage(CRS.VIDEOPAGE,1,backpix);  % clear draw page to grey
crsSetZoneDisplayPage(CRS.VIDEOPAGE,1);   % set display page to draw page

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
%-------------------------------

if testh==1 %orange
    h=45;
elseif testh==2 %turquoise
    h=225;
elseif testh==3 %luminance
    h=0; %in this case, hue becomes irrelevant as we will also drop C to zero
    C=0;
end

%---------------------------------------------------------
% Display on screen (not stimulus monitor) what this program is about
%---------------------------------------------------------
disp('')
disp('---------------------------------------')
disp('')
disp('This script will run 2 adaptive staircase procedures (one from above, the ')
disp('other from below) to determine the perceptual isosalience points for hue.')
disp('')
disp('This measurement is a part of the HELIOS-BD project.')
disp('')
disp('to abort the procedure')
disp('press the UP button')
disp('on the response box')
disp('')
disp('---------------------------------------')

%----------------------------------------
% open ten Response files 
% each trial is recorded in a single line in this file
fid1=fopen(sprintf('c:/research/wellcome/results/PSE/hue/%s_u_%s_UD.result',subject,num2str(h)),'w');
fid2=fopen(sprintf('c:/research//wellcome/results/PSE/hue/%s_d_%s_UD.result',subject,num2str(h)),'w');

% generate sound for acoustic feedback
%y=sin([1:1024]);
%y1=sin(0.5*[1:1024]);

%----------------------------------------
% Initialise staircases
%----------------------------------------

%-------------------------------------------
%set the values between which the isosalience point may lie

%in CIE LAB, we are giving h values for hue, but L for when luminance is
%tested
%starting values
    if testh==1 %for orange standard
    start_up=55;
        start_down=35;
            Minint=20;    %minimum intensity
    Maxint=70;   %maxi mum intensity    
        step=1;
    elseif testh==2 %for turq standard
    start_up=235;
        start_down=215;
    Minint=200;    %minimum intensity
    Maxint=250;   %maxi mum intensity    
        step=1;
    elseif testh==3 %for L standard
    start_up=L+3;
        start_down=L-3;
    Minint=L-8;    %minimum intensity
    Maxint=L+8;   %maxi mum intensity    
        step=0.25;
    end   

reversals=12; %after how many reversal trials to stop; this determines duration/precision

%first set them up with no parameters
 UD1 = PAL_AMUD_setupUD;
 UD2 = PAL_AMUD_setupUD;

%now update them
 UD1 = PAL_AMUD_setupUD(UD1,'up',1,'down',1,'stepSizeUp',step,'stepSizeDown',step,'stopCriterion','reversals','stopRule',reversals,'startValue',start_up,'xMax',Maxint,'xMin',Minint,'truncate','yes');
 UD2 = PAL_AMUD_setupUD(UD1,'up',1,'down',1,'stepSizeUp',step,'stepSizeDown',step,'stopCriterion','reversals','stopRule',reversals,'startValue',start_down,'xMax',Maxint,'xMin',Minint,'truncate','yes');

%==================================
% Experiment
%==================================
% -----------------------------------------------------------------------
% displays a page with instructions for the subject and wait for keypress
% -----------------------------------------------------------------------
ScrHeight=crsGetScreenHeightPixels;
%Select a page in memory to draw onto.
crsSetDrawPage(CRS.VIDEOPAGE,2, backpix);
%Select pixel-level(1) to draw with - 255 IS WHITE
crsSetPen1(255);
%Load the true type font that you want to write with.
crsSetTrueTypeFont('Arial.ttf');
%Set the draw modes for the text i.e. centred, italic, angle, size.
crsSetStringMode([0 ScrHeight/19], CRS.ALIGNLEFTTEXT, CRS.ALIGNTOPTEXT, 0, CRS.FONTNORMAL);
%Change the drawing origin to the top-left of the page.
crsSetDrawOrigin([0 0]);

%Draw some text.
str1='In this test, you will be asked to compare the colour of';
str2='two stimulus patches. Fixate the central cross. Two '; 
str3='patches will be presented to its left and right.';

if testh==1 
str4='The patches will be between reddish and yellowish-';
    str5='orange in hue. Your task is to judge which of the ';
    str6='two patches is redder than the other.';
elseif testh==2
str4='The patches will be coloured in greenish and bluish hues.';
    str5='Your task is to judge which of the ';
    str6='two patches is greener than the other.';
elseif testh==3
str4='The patches will be achromatic.';
    str5='Your task is to judge which of the ';
    str6='two patches is darker than the other.';
end
str7=' ';
str8='Press the LEFT button if it is the left patch.';
str9='Press the RIGHT button if it is the right patch.';
str10= ' ';
str11='Press the LEFT button to start the experiment.';

% x,y
for s=1:11
    crsDrawString([10 10+s*42], eval( sprintf('str%i',s)));
end

%Display the page that the text was drawn onto.
crsSetZoneDisplayPage(CRS.VIDEOPAGE,2);

[~,~,dev]=cedrus_LR(dev);

%now clear the display page
crsSetDrawPage(CRS.VIDEOPAGE,1,backpix);  % clear draw page to grey
crsSetZoneDisplayPage(CRS.VIDEOPAGE,1);   % set display page to draw page

%--------------------------------------------------------------------------
% The experiment starts to loop until the experiment is finished
trial1=0;	% counter for completed trials in QUEST-procedure 1, set to zero
trial2=0;   % counter for completed trials in QUEST-procedure 2, set to zero

%SET UP FIXED STIMULUS SPATIAL PARAMETERS
%------------------------------------------------
circs=2;
%there are 2 pi radians in a circle- so to divide the circle up evenly you find an interval of 2 pi / n,
%with n being the number of circles
angles=[0 pi];
%distance from centre, in pixels - in Switkes 2008 it is 6.5deg
distCirc=1.5; %in degs
visang_rad = 2 * atan(horsize/2/viewdist);
visang_deg = visang_rad * (180/pi);
pix_pervisang = ScrWidth / visang_deg;
r = round(distCirc * pix_pervisang);

xs=zeros(circs,1);ys=zeros(circs,1);
for numcirc=1:circs
    %formulas:    x = a + r * cos(theta), y = b + r * sin(theta)
    %(a,b) centre of the circle
    %0 <= theta <= 360 degrees.
    xs(numcirc) = round(ScrWidth/2 + r * cos(angles(numcirc)));
    ys(numcirc) = round(ScrHeight/2 + r * sin(angles(numcirc)));
end
locations=[xs ys];
%determine the sizes of each gaussian
%FM caps are 12mm in diameter designed to be viewed from 50cm, which
%produces size of 1.375 deg of visual angle
gaussdegs=1.375;
gaussz = round(gaussdegs * pix_pervisang);
size_gaussian=repmat(gaussz,circs,2);        
%determine the deviation of each gaussian 
lambda=gaussz/gaussdegs; %lambda is in pixels per cycle, so the number of pixels in the patch divided by the number of degrees


%to do: determine which stdev to use for the gaussian


%gaussdev=4*(3*sqrt(log(2)/2)/pi)*lambda;
gaussdev=gaussz/7;
gaussstdev=[round(gaussdev);round(gaussdev)];

startloop=1; % controls the while-loop

while startloop==1
    % display the overall number of trials so far
    trial_number=trial1+trial2;
    disp(sprintf('Overall trial no.: %i', trial_number))
    
    %DETERMINE WHICH COLOUR TO TEST NEXT
    %--------------------------------------------------------
    %FIRST, check markers that indicate which condition is finished    
        coin=7;
        coinmarkers=zeros(1,2);
    
    if UD1.stop==1 % quest 1 finished      
        coinmarkers(1) = 1;	
    end
    if UD2.stop==1 % quest 2 finished 
        coinmarkers(2) = 1;	
    end
    
    %expt is finished if they're all one
    if coinmarkers==ones(1,2)
       coin=6;
    end

    % determine which colour to test next based on which markers are not 1
    % (i.e. finished)
    potConds=[];
    %we will update the number of possible conditions to run based on
    %RF.stop status
    for num=1:size(coinmarkers,2)
        if coinmarkers(num)==1
            continue
        else
            potConds=[potConds num];
        end
    end
    %now generate a random number and pick out a potential condition that
    %corresponds to it
        if coin~=6
            randnum=randi(size(potConds,2));
            coin=potConds(randnum);
        end
    
      % now that we have a value for 'coin'
    % we tell what to do in each of the cases
    switch coin
        case 1
            %==================================
            % up - starts above the standard in hue angle
            %==================================
            disp('up')
            
            stimint1=UD1.xCurrent;
            
            % increase the trial counter for QUEST 2
            trial1=trial1+1;
            
            %display trial
            [col_resp,standard_resp,LUTBuff]=AFC_trial_wellcome_PSE(testh,backpix,locations,size_gaussian,gaussstdev,stimint1,L,C,h,WP_xyY,deviceSPD,Sensors_CMF,LUTBuff);
                        
            % collect response
            [res,rt,dev]=cedrus_LR(dev);
            
            pause(2);
            
            % check response
            if res==standard_resp %	standard response 
                disp('Standard selected - decrease to make comparison redder/greener/darker')                          
                hit=1; %this will decrease
             elseif res==col_resp 	%comparison response 
                disp('Comparison selected - increase to make comparison less red/green/dark')              
                hit=0;
            elseif res== 5	% aborted procedure
                fclose(fid1);
                fclose(fid2);
                break;
            else %wrong button pushed, move the procedure randomly up or down
               rval=randperm(2);
                if rval(1)==1
                    hit=1;
                else
                    hit=0;
                end

                disp('wrong button!')
                %wavplay(y)	% give acoustic feedback
            end
            
            % write to result file
            fprintf(fid1,'%i\t %i\t %i\t %i\t %i\t %i\t %i\t %i\n',trial1,coin,stimint1,hit,col_resp,standard_resp,res,rt);
            % what's the next Stimulus in thies QUEST procedure?
            UD1=PAL_AMUD_updateUD(UD1,hit);

        case 2
            %==================================
            % down 
            %==================================
            disp('down - comp starts below the standard in hue angle')
            
            stimint2=UD2.xCurrent;
            
            % increase the trial counter for QUEST
            trial2=trial2+1;
            
            %display trial
            [col_resp,standard_resp,LUTBuff]=AFC_trial_wellcome_PSE(testh,backpix,locations,size_gaussian,gaussstdev,stimint2,L,C,h,WP_xyY,deviceSPD,Sensors_CMF,LUTBuff);
            
            % collect response
            [res,rt,dev]=cedrus_LR(dev);
            
               pause(2);
               
            % check response
            if res==standard_resp %	standard response 
                disp('Standard selected - increase to make comparison redder/greener/darker')                          
                hit=1; %this will increase 
             elseif res==col_resp 	%comparison response 
                disp('Comparison selected - decrease to make comparison less red/green/dark')              
                hit=0;
            elseif stimint2==h %if they are the same, randomly decide to increase or decrease
                rval=randperm(2);
                if rval(1)==1
                    hit=1;
                else
                    hit=0;
                end
            elseif res== 5	% aborted procedure
                fclose(fid1);
                fclose(fid2);
                break;
            else %wrong button pushed, move the procedure randomly up or down
               rval=randperm(2);
                if rval(1)==1
                    hit=1;
                else
                    hit=0;
                end

                disp('wrong button!')
                %wavplay(y)	% give acoustic feedback
            end
           
            % write to result file
            fprintf(fid2,'%i\t %i\t %i\t %i\t %i\t %i\t %i\t %i\n',trial2,coin,stimint2,hit,col_resp,standard_resp,res,rt);
            % what's the next Stimulus in this  procedure?
           UD2=PAL_AMUD_updateUD(UD2,hit);

        case 6
            %=================================
            % experiment is finished
            %=================================
            % close all files
                fclose(fid1);
                fclose(fid2);
                % play a different sound, so that people know it's finished
            %wavplay([y1 y1 y1 y1]);
            startloop=0; 	% this will end the while-loop
    end	% end for case
end	% end for while-loop

%----------------------------------------------
%draw end text
%----------------------------------------------
%Select a page in memory to draw onto.
crsSetDrawPage(CRS.VIDEOPAGE,2, backpix);
%Select pixel-level(1) to draw with
crsSetPen1(255);
crsSetPen2(256);
%Load the true type font that you want to write with.
crsSetTrueTypeFont('Arial.ttf');
%Set the draw modes for the text i.e. centred, italic, angle, size.
crsSetStringMode([0 ScrHeight/19], CRS.ALIGNLEFTTEXT, CRS.ALIGNTOPTEXT, 0, CRS.FONTNORMAL);
%Change the drawing origin to the top-left of the page.
crsSetDrawOrigin([0 0]);

%Draw some text.
str1='The measurement is over - thank you!';
crsDrawString([10 82], eval( sprintf('str1')));

%Display the page that the text was drawn onto.
crsSetZoneDisplayPage(CRS.VIDEOPAGE,2);

%close communication with the cedrus button box
%------------------------------------------------
% Close serial control link:
fclose(dev.link);
% Delete serial control link object:
delete(dev.link);
clear dev.link;
%-----------------------------------------------

%--------------------------------------
% Analyse data from QUEST procedures
%--------------------------------------
t1= PAL_AMUD_analyzeUD(UD1, 'reversals',6);
% write out onto screen
fprintf('up: Mean isosalience estimate is %4.5f\n',t1);

t2=PAL_AMUD_analyzeUD(UD2, 'reversals',6);
% write out onto screen
fprintf('down: Mean isosalience estimate is %4.5f\n',t2);

%PLOT RESULTS
%---------------------------
%plot for first staircase
to1 = 1:length(UD1.x);
f1=figure('name','Running Fit Adaptive Procedure 1');
plot(to1,UD1.x,'k');
hold on;
plot(to1(UD1.response == 1),UD1.x(UD1.response == 1),'ko', ...
    'MarkerFaceColor','k');
plot(to1(UD1.response == 0),UD1.x(UD1.response == 0),'ko', ...
    'MarkerFaceColor','w');
set(gca,'FontSize',16);
axis([0 max(to1)+1 min(UD1.x)-(max(UD1.x)-min(UD1.x))/10 ...
    max(UD1.x)+(max(UD1.x)-min(UD1.x))/10]);
line([1 length(UD1.x)], [t1],'linewidth', 2, ...
    'linestyle', '--', 'color','k');
xlabel('Trial');
ylabel('Stimulus Intensity');
saveas(f1, [path '/' subject '_1_' num2str(testh) '_UD.fig']);
saveas(f1, [path '/' subject '_1_' num2str(testh) '_UD.png']);

%plot for second staircase
to2 = 1:length(UD2.x);
f2=figure('name','Running Fit Adaptive Procedure 2');
plot(to2,UD2.x,'k');
hold on;
plot(to2(UD2.response == 1),UD2.x(UD2.response == 1),'ko', ...
    'MarkerFaceColor','k');
plot(to2(UD2.response == 0),UD2.x(UD2.response == 0),'ko', ...
    'MarkerFaceColor','w');
set(gca,'FontSize',16);
axis([0 max(to2)+1 min(UD2.x)-(max(UD2.x)-min(UD2.x))/10 ...
    max(UD2.x)+(max(UD2.x)-min(UD2.x))/10]);
line([1 length(UD2.x)], [t2],'linewidth', 2, ...
    'linestyle', '--', 'color','k');
xlabel('Trial');
ylabel('Stimulus Intensity');
saveas(f2, [path '/' subject '_2_' num2str(testh) '_UD.fig']);
saveas(f2, [path '/' subject '_2_' num2str(testh) '_UD.png']);

%close all;