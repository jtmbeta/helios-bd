function flicker_gabor(subject,viewdist) 

%******************************************************************************
%Gabor patches alternating with the opposite phase patch, flickering
% asking for the subject to adjust the colour to minimize flicker
%
% left button 		increase luminance of col 1, decrease of col 2
% right button 	decrease luminance of col2, increase of col 1
% top button		abort procedure
% bottom button	finish procedure when isoluminance point reached
%
% for Helios-BD project
%
% saves the file for each participant with the angles, to be used by VEP
% scripts (this is the first input)
% the second input is the viewing distance, in cm
%
% adapted by J Martinovic, based on scripts written by Alexa Ruppertsberg
%******************************************************************************
global CRS;

crsInit('');                                    % default VSG initialisation
crsSetVideoMode(CRS.EIGHTBITPALETTEMODE+CRS.GAMMACORRECT); % make sure we are using basic CLUT mode
crsSetDrawMode(CRS.CENTREXY + CRS.SOLIDFILL);    % set draw mode co-ordinate system

%set viewing distance, so degrees are calculated correctly
crsSetViewDistMM(viewdist*10);
%set spatial units
crsSetSpatialUnits( CRS.PIXELUNIT);
%Change the drawing origin to the top-left of the page.
crsSetDrawOrigin([0 0]);
%get screen parameters
ScrHeight=crsGetScreenHeightPixels;
ScrWidth=crsGetScreenWidthPixels;
%screen size in cm 29.9 x 39.2
horsize=39.4; versize=39.4;
horpx=horsize/ScrWidth;
verpx=versize/ScrHeight;
pxsize=(horpx+verpx)/2;

delete(instrfindall);

path='c:/research/wellcome/results/flicker/';

%----------------------------------------------------------
%SET COLOUR PARAMETERS
%----------------------------------------------------------
% make a greyscale CLUT - 256x3 matrix, add colours to it
crsSetColourSpace(CRS.CS_RGB);	% use RGB space

%choose white point
WP_xyY=[0.3127 0.3290 50];

%use Stockman & Sharpe (2000) cone fundamentals
Sensors = 'ConeSensitivities_SS_2degELin3908301.mat';
% Define which display device SPD to use.
deviceSPD = 'DisplayPlusPlus.mat';
% Define which colour matching functions to use - CIE 1931 2-deg.
Sensors_CMF = 'CMF_CIE1931_2deg3608301.mat';

%get whitepoint
WP_RGB = ctGetColourTrival('CS_CIE1931xyY','CS_RGB',WP_xyY,deviceSPD,Sensors_CMF);

LUTBuff=repmat(WP_RGB',256,1);
white=[1,1,1]; %rgb white, for fixation
LUTBuff(255,:)=white; %white
backpix=256; %set background to 256
whitepix=255;

crsLUTBUFFERWrite(1,LUTBuff);     % load the CLUT into VSG LUT memory
crsLUTBUFFERtoPalette(1);           % make the whitepoint CLUT the current palette

crsSetDrawPage(CRS.VIDEOPAGE,1,backpix);  % clear draw page to grey
crsSetZoneDisplayPage(CRS.VIDEOPAGE,1);   % set display page to draw page

% %open communication with the cedrus button box
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
%-----------------------------------------------

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
    crsSetStringMode([0 ScrHeight/30], CRS.ALIGNLEFTTEXT, CRS.ALIGNTOPTEXT, 0, CRS.FONTNORMAL);
    %Change the drawing origin to the top-left of the page.
    crsSetDrawOrigin([0 0]);
    %Draw some text.
str1='This task involves adjusting the stimulus on the screen ';
str2='until its strength is minimised.';
str3=' ';
str4='You will see two flickering stimulus patches on the';
str5='screen. Your task is to adjust their appearance until';
str6='the percept of flickering is minimised.';
str7=' ';
str8='Press the LEFT button to adjust the stimulus in one direction.';
str9='Press the RIGHT button to go in the opposite direction.';
str10=' ';
str11='Press the TOP button when you are satisfied with the setting.';
str12=' ';
str13='Press the LEFT button to start.';
    
    for s=1:13
        crsDrawString([8 8+s*38], eval( sprintf('str%i',s)));
    end
    
    %Display the page that the text was drawn onto.
    crsSetZoneDisplayPage(CRS.VIDEOPAGE,2);
    %read button press from response box
  [answer,~,dev]=cedrus_LR(dev);
  
    %display grey for 5 seconds before starting
    crsSetDrawPage(CRS.VIDEOPAGE,1, backpix);
    crsSetZoneDisplayPage(CRS.VIDEOPAGE,1);
   pause(2);

%-----------------------------------------------------------------
% EXP LIST loading; setting up the conditions
%-----------------------------------------------------------------
trialscond=8;cond1=ones(1,trialscond);cond2=repmat(2,1,trialscond);
conds=[cond1 cond2];

%---------------------------------------------
% Parameters
%---------------------------------------------
%Read the framerate for the vsg monitor
FrameRate = crsGetSystemAttribute(CRS.FRAMERATE);
%Find out the horizontal resolution of the vsg screen.
ScrWidth=crsGetScreenWidthPixels;
ScrHeight=crsGetScreenHeightPixels;

desiredFR = 20;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN EXPERIMENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%grey adaptation
%Select a page in memory to draw onto.
crsSetDrawPage(CRS.VIDEOPAGE,6, backpix);
crsSetZoneDisplayPage(CRS.VIDEOPAGE,6);

% start presentation-loop
for j = 1:length(conds)
    cond=conds(j);
    
      %%%%%%%%%%%%%%%%%
            %display stimuli
            %%%%%%%%%%%%%%%%%
            % display the overall number of trials so far
            disp('-------------------');
            disp('Overall trial no.:');
            disp(num2str(j));
            disp('Condition');
            disp(num2str(cond));
            
            if cond==1 
                radius=0.2;
                th1=270; %blue
                th2=90; %yellow
            elseif cond==2 %0 and 180
                radius=0.04;
                th1=0; %red
                th2=180; %green
            end
          
            if cond==1
                 delta=1;
            else
                delta = 3;	% stepsize for luminance-changes (in degrees of elevation)
            end

            %fill lut buffers
LUTBuff1=repmat(WP_RGB',256,1);
LUTBuff2=repmat(WP_RGB',256,1);
backpix=256; %set background to 256

%----------------------------------------
% select a random point off iso-luminance
%----------------------------------------
draw=XausY(1,5);	% up to delta * draw deg off
up=XausY(1,3);
if up ==1 % 1 = 1st col up
    relLum1=delta*draw;
    relLum2=-delta*draw;
else
    relLum1=-delta*draw;
    relLum2=delta*draw;
end

%-------------------------------------
%set up the object drawing
%-------------------------------------
%change centre of drawing from top left corner to middle
crsSetDrawOrigin([ScrWidth/2 ScrHeight/2]);

% Set page no and initialise to background colour
drawingpage = 1;
crsSetDrawPage(CRS.VIDEOPAGE, drawingpage, backpix);
% draw the visual search elements
%Change the drawing origin to the top-left of the page.
crsSetDrawOrigin([0 0]);

%set parameters of the Gabor
%-----------------------------------------------
  gabor_size        = 500; %514;       
  %other gabor properties
  gabor_stdev       = 100; %gabor_size/7;
  gabor_phase      = 0;
   gabor_spatfr = 0.8; %2cpd, near peak of cVEP (see Rabin et al., 1994); but 0.8 gives good salience matches
  %randomly generate an angle
  angles=randperm(360);
  gabor_angle =    angles(1); 
% Gabor parameters (palette functional form)
  gabor_pixLow = 1; % Select the range of pixel-levels
  gabor_pixHi  = 100; % to draw the gabor with.
  gabor_background_colour = WP_RGB;

% -----------------------------------------------------------------------------
% DRAW THE GABOR
% -----------------------------------------------------------------------------
  crsSetPen1(gabor_pixLow);
  crsSetPen2(gabor_pixHi);

  crsSetBackgroundColour(gabor_background_colour);
  crsSetDrawOrigin([0,0]);

                      %     %make empty trivector matrix for stimulus colour in DKL
     STC1=zeros(gabor_pixHi,3);
        STC2=zeros(gabor_pixHi,3);
    no_of_steps=gabor_pixHi/2;
     stepsize=radius/(no_of_steps - 1);
             for i_decr = 1:no_of_steps
                STC1((no_of_steps-i_decr+1),:) = [i_decr*stepsize th1 relLum1];
               STC2((no_of_steps-i_decr+1),:) = [i_decr*stepsize th2 relLum2];
             end
             for i_incr = 1:no_of_steps
                 STC1(i_incr+no_of_steps,:) = [i_incr* stepsize th2 relLum2];
                 STC2(i_incr+no_of_steps,:) = [i_incr* stepsize th1 relLum1];
             end
for colnum=1:size(STC1,1)
     [LUTBuff1(gabor_pixLow+colnum,:) ErrorCode] = ctGetColourTrival('CS_DKL','CS_RGB',[WP_RGB',STC1(colnum,:)],deviceSPD,Sensors);    
     if ErrorCode == -1, warning('THE 1st COLOUR IS OUT OF RANGE'); end
     [LUTBuff2(gabor_pixLow+colnum,:) ErrorCode] = ctGetColourTrival('CS_DKL','CS_RGB',[WP_RGB',STC2(colnum,:)],deviceSPD,Sensors);
     if ErrorCode == -1, warning('THE 2nd COLOUR IS OUT OF RANGE'); end
end

%this function is useful when debugging as it immediately switches the
%palette
% crsPaletteSet(LUTBuff1);

 gabor_page=1;
 
  crsSetDrawPage(CRS.VIDEOPAGE,gabor_page,backpix);
  
        gabor_x_pos = ScrWidth/2;
        gabor_y_pos = ScrHeight/2;

        crsDrawGabor([gabor_x_pos,gabor_y_pos], ...
                     [gabor_size, gabor_size],  ...
                      gabor_angle,              ...
                      gabor_spatfr,             ...
                      gabor_stdev,              ...
                      gabor_phase);
        
%--------------------------------------
%initialise output parameters
angle1=relLum1;
angle2=relLum2;

%--------------------------------------
% start with feedback routine
start =1;	% controls while-loop       

while start
    % start with angle value defined in ANGLE
    disp('-------------------')
    disp(sprintf('angle= %i %i',angle1,angle2))
    
    %Load the contents of the Buff into Look Up Table(LUT)
    crsLUTBUFFERWrite(1,LUTBuff1);
    crsLUTBUFFERWrite(2,LUTBuff2);
    
    %Set up the cycling of the LUT table and start it cycling.
    crsLUTBUFFERCyclingSetup(0, FrameRate/desiredFR, 1, 2, 1, 1, -1);
    crsSetCommand(CRS.CYCLELUTENABLE);
    crsSetDisplayPage(1);
   
try    [res,rt,dev] = cedrus_LR(dev);
       
    switch res
        case 1
            disp('Button pressed = Left');
            angle1=angle1+delta;		%lighter
            angle2=angle2-delta;		%darker
        case 2
            disp('Button pressed = middle');
            disp('no action taken!');
        case 3
            disp('Button pressed = Right');
            angle1=angle1-delta;		% darker
            angle2=angle2+delta;		% lighter
        case 4
            crsSetCommand(CRS.CYCLELUTDISABLE);
            break;
        case 5
            crsSetCommand(CRS.CYCLELUTDISABLE);
            start=0;
    end
    
catch %to catch the errors with overly rapid button pressing
       continue
   end

        %store luminance values in Matrix and save matrix in the end to file
    tmp=[angle1 angle2];

    %update colour buffers to the new luminance angle
             for i_decr = 1:no_of_steps
                STC1((no_of_steps-i_decr+1),:) = [i_decr*stepsize th1 angle1];
               STC2((no_of_steps-i_decr+1),:) = [i_decr*stepsize th2 angle2];
             end
             for i_incr = 1:no_of_steps
                 STC1(i_incr+no_of_steps,:) = [i_incr* stepsize th2 angle2];
                 STC2(i_incr+no_of_steps,:) = [i_incr* stepsize th1 angle1];
             end

for colnum=1:size(STC1,1)
     [LUTBuff1(gabor_pixLow+colnum,:) ErrorCode] = ctGetColourTrival('CS_DKL','CS_RGB',[WP_RGB',STC1(colnum,:)],deviceSPD,Sensors);
     if ErrorCode == -1, warning('THE 1st COLOUR IS OUT OF RANGE'); end
     [LUTBuff2(gabor_pixLow+colnum,:) ErrorCode] = ctGetColourTrival('CS_DKL','CS_RGB',[WP_RGB',STC2(colnum,:)],deviceSPD,Sensors);
     if ErrorCode == -1, warning('THE 2nd COLOUR IS OUT OF RANGE'); end
end

end
%---------------------------------------------------------------
% get final luminance value of the two colours, at its top point
%---------------------------------------------------------------
strcol1=num2str(th1);
strcol2=num2str(th2);

if cond==1
    relLum_270(j)=angle1;
    relLum_90(j)=angle2;
elseif cond==2
    relLum_0(j-8)=angle1;
    relLum_180(j-8)=angle2;
end

disp('------------------------------')
disp(sprintf('colour %s has an angle of: %f deg',strcol1,angle1))
disp('------------------------------')
disp(sprintf('colour %s has an angle of: %f deg',strcol2,angle2))
disp('------------------------------')
disp('------------------------------')
disp('negative angle means DARKER')
disp('positive angle means BRIGHTER')

%grey adaptation
%Select a page in memory to draw onto.
crsSetDrawPage(CRS.VIDEOPAGE,6, backpix);
crsSetZoneDisplayPage(CRS.VIDEOPAGE,6);
pause(2);
end

%now calculate the results
relLum_270=relLum_270';
relLum_90=relLum_90';
relLum_0=relLum_0';
relLum_180=relLum_180';

relLum270=relLum_270;
relLum90=relLum_90;
relLum0=relLum_0;
relLum180=relLum_180;

%now reject the lowest and the highest value
[min_270,rowtodelete270_1]=min(relLum_270);
[min_90,rowtodelete90_1]=min(relLum_90);
[min_0,rowtodelete0_1]=min(relLum_0);
[min_180,rowtodelete180_1]=min(relLum_180);
[max_270,rowtodelete270_2]=max(relLum_270);
[max_90,rowtodelete90_2]=max(relLum_90);
[max_0,rowtodelete0_2]=max(relLum_0);
[max_180,rowtodelete180_2]=max(relLum_180);

relLum_270([rowtodelete270_1, rowtodelete270_2], :)=[];
relLum_90([rowtodelete90_1,rowtodelete90_2],:)=[];
relLum_0([rowtodelete0_1,rowtodelete0_2],:)=[];
relLum_180([rowtodelete180_1,rowtodelete180_2],:)=[];

relLum_270=mean(relLum_270);
relLum_90=mean(relLum_90);
relLum_0=mean(relLum_0);
relLum_180=mean(relLum_180);

filename=sprintf('%s.mat', subject);

save(strcat('c:/research/wellcome/results/flicker/',filename),'relLum_270','relLum_90','relLum_0','relLum_180','relLum270','relLum90','relLum0','relLum180');

close all;

    y1=sin(0.5*[1:1024]);
    sound([y1 y1 y1 y1])
