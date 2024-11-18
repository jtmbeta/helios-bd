function wellcome_SSVEP_trial(cond,backpix,Sensors,deviceSPD,WP_RGB,LUTBuff,gabor_angle,TF,relLum0,relLum90,relLum180,relLum270)

%---------------------------------------------------------
% initialise VSG-Card
%---------------------------------------------------------
global CRS;

% -----------------------------------------------------------------------------
% INITIALISE gabor PARAMETERS
% -----------------------------------------------------------------------------
duration = 2; %in secs  

Scrwidth        = crsGetScreenWidth;  
  Scrheight       = crsGetScreenHeight; 
     FrameRejt = crsGetFrameRate;
            
% Gabor parameters (pixel level functional form)
  gabor_size        = 550; 
         
  %other gabor properties
  gabor_stdev       = 100; % gabor_size/7;
  gabor_phase      = 0;
    gabor_spatfr= 0.8;

% Gabor parameters (palette functional form)
  gabor_pixLow = 1; % Select the range of pixel-levels
  gabor_pixHi  = 100; % to draw the gabor with.
  gabor_background_colour = WP_RGB;

%   %set the gabor colour
%   %--------------------
%logarithmically spaced L-M contrast, as used in salience matching
minLM=0.008;% should be just about visible
maxLM=0.045; %should be high contrast but not too close to gamut limit
LMcs=logspace(log10(minLM),log10(maxLM),4); %get 4 contrast levels in this range logarithmically spacced

if cond==1 %lowest lum
         relLum1=90; th1=0;
        relLum2=-90; th2=0;
        stimint=0.04;
elseif cond==2 %lower lum
         relLum1=90; th1=0;
        relLum2=-90; th2=0;
        stimint=0.08;
elseif cond==3 %mid lum
         relLum1=90; th1=0;
        relLum2=-90; th2=0;
        stimint=0.12;
elseif cond==4 %high lum
         relLum1=90; th1=0;
        relLum2=-90; th2=0;
        stimint=0.16;
elseif cond==5  %lowest L-M
         relLum1=relLum0; th1=0;
        relLum2=relLum180; th2=180;
        stimint=LMcs(1);
elseif cond==6  %low L-M
         relLum1=relLum0; th1=0;
        relLum2=relLum180; th2=180;
        stimint=LMcs(2);
elseif cond==7 %mid L-M
         relLum1=relLum0; th1=0;
        relLum2=relLum180; th2=180;
        stimint=LMcs(3);
elseif cond==8 %high L-M
         relLum1=relLum0; th1=0;
        relLum2=relLum180; th2=180;
        stimint=LMcs(4);
elseif cond==9 %lowest S-(L+M)
         relLum1=relLum90; th1=90;
        relLum2=relLum270; th2=270;
        stimint=0.05;
elseif cond==10 %low S-(L+M)
         relLum1=relLum90; th1=90;
        relLum2=relLum270; th2=270;
        stimint=0.14;
elseif cond==11 %mid S-(L+M)
         relLum1=relLum90; th1=90;
        relLum2=relLum270; th2=270;
        stimint=0.21;
elseif cond==12 %high s-(L+M)
         relLum1=relLum90; th1=90;
        relLum2=relLum270; th2=270;
        stimint=0.28;        
end

%assign colours to pixel levels
%-------------------------------------------------------------     
%if cond> 6 %bipolar Gabor
%     %make empty trivector matrix for stimulus colour in DKL
     STC=zeros(gabor_pixHi,3);
    no_of_steps=gabor_pixHi/2;
     stepsize=stimint/(no_of_steps - 1);
             for i_decr = 1:no_of_steps
                STC((no_of_steps-i_decr+1),:) = [i_decr*stepsize th1 relLum1];
             end
             for i_incr = 1:no_of_steps
                 STC(i_incr+no_of_steps,:) = [i_incr* stepsize th2 relLum2];
             end
% elseif cond<7 %gaussian
%     %draw the grating
%     pixnums=crsDrawGrating([Scrwidth/2,Scrheight/2],gabor_size,[180;180],[1;1]);
%     numlevels=floor(pixnums(1)/2); %get number of pixels needed
%     %select pixel levels for grating
% pixHi=gabor_pixLow+pixnums(1);
%     %set LUT buffers for drawing the gratings
%     pixLow=gabor_pixLow;
% %    pixHi=gabor_pixLow+numlevels-1;
%     gaussian_step=0:stimint/(pixHi-pixLow):stimint;
%     gaussian_step_down=fliplr(gaussian_step);
%     STC=[gaussian_step_down',repmat(th,numlevels,1),repmat(relLum1,numlevels,1)];
% end
            
% %now turn all those colours into RGB and put them into the LUT buffer
 for colnum=1:gabor_pixHi
      [LUTBuff(colnum,:) ErrorCode]= ctGetColourTrival('CS_DKL','CS_RGB',[WP_RGB,STC(colnum,:)],deviceSPD,Sensors);
             if ErrorCode == -1, disp('THE REQUESTED COLOUR IS OUT OF RANGE'); end
 end
 LUTBuff(255,:)=[1 1 1]; %add white for fixation
 crsLUTBUFFERWrite(1,LUTBuff);     % load the CLUT into VSG LUT memory
 crsLUTBUFFERtoPalette(1);           % make the whitepoint CLUT the current palette

 %set up the 2nd LUTbuffer and the flicker parameters
%--------------------------------------------------- 
%Read the framerate for the vsg monitor
desiredFR = TF; %desired flicker rate
LUTBuff2=repmat(WP_RGB,256,1);
LUTBuff2(255,:)=[1 1 1]; %add white for fixation
crsLUTBUFFERWrite(2,LUTBuff2);
%Set up the cycling of the LUT table
crsLUTBUFFERCyclingSetup(0, FrameRejt/desiredFR, 1, 2, 1, 1, -1);
 
% -----------------------------------------------------------------------------
% DRAW THE GABORS
% -----------------------------------------------------------------------------
  crsSetPen1(gabor_pixLow);
  crsSetPen2(gabor_pixHi);

  crsSetBackgroundColour(gabor_background_colour);
  crsSetDrawOrigin([0,0]);

 gabor_page=1;
 
  crsSetDrawPage(CRS.VIDEOPAGE,gabor_page,backpix);
  
        gabor_x_pos = Scrwidth/2;
        gabor_y_pos = Scrheight/2;

        crsDrawGabor([gabor_x_pos,gabor_y_pos], ...
                     [gabor_size, gabor_size],  ...
                      gabor_angle,              ...
                      gabor_spatfr,             ...
                      gabor_stdev,              ...
                      gabor_phase);
                  
%now add a fixation cross
                  
fixpix=255; %256 is white
%set up the fixation cross
CrossCentreX = 0;				% position of centre of cross - centre of screen
CrossCentreY = 0;
CrossLineLengthHor = 5;		% size of horizontal line of fixation cross in pixels
CrossLineLengthVer = 5;		% size of vertical line of fixation cross in pixels

CrossLineWidth = 1;
% select Pen to draw with
crsSetPen1(fixpix);
%change centre of drawing from top left corner to middle
crsSetDrawOrigin([Scrwidth/2 Scrheight/2]);
% horizontal and vertical line
crsDrawRect([CrossCentreX, CrossCentreY], [CrossLineLengthHor, CrossLineWidth]);
crsDrawRect([CrossCentreX, CrossCentreY], [CrossLineWidth, CrossLineLengthVer]);
                  
%==================================
% Set up the page cycling data.
%==================================
%determine maximum trial time (in frames)
MaxTime=duration*FrameRejt;

% -------------------
% Set up page buffer
% -------------------
% page buffer 1: fixation cross
pagebuff(1).Page   = gabor_page + CRS.TRIGGERPAGE;
pagebuff(1).Xpos   = 0;
pagebuff(1).Ypos   = 0;
pagebuff(1).ovPage = 0;
pagebuff(1).ovXpos = 0;
pagebuff(1).ovYpos = 0;
pagebuff(1).Frames = MaxTime;	
pagebuff(1).Stop   = 1;
    
  % load the page cycling array (We can enable and disable later)
  crsPageCyclingSetup(pagebuff);
 
  %we need to have 2 frame length triggers or they won't show  
length=2; %how many frames
crsSetTriggerOptions(CRS.TRIGGER_OPTIONS_PAGECYCLE,0,0,length,0,0,0);



%to do - check if i can trigger through LUT cycling 



% -----------------------------------------------------------------------------
% FINISHED PREPARING OUR STIMULI. NOW WE CAN RUN OUR EXPERIMENT
% -----------------------------------------------------------------------------
tic
crsSetCommand(CRS.CYCLEPAGEENABLE + CRS.CYCLELUTENABLE);
%         crsIOWriteDigitalOut(1); %manual sending of the trigger - it's a fix
%            WaitSecs(0.01);    
crsResetTimer;


%check if the trial is over
timer=crsGetTimer;
while timer <= ((MaxTime/FrameRejt)*1000000) %wait
    % Choose 4 msecs, as PTB would not release the cpu for wait
    % times below 3 msecs (to account for MS-Windows miserable
    % process scheduler).
    timer=crsGetTimer;
   WaitSecs(0.004);
end

% Stop displaying the gabors
crsSetCommand(CRS.CYCLEPAGEDISABLE+CRS.CYCLELUTDISABLE);

toc
 
 %set up the following page(ITI):
   %------------------------------   
        frames3secs=randperm(FrameRate);
        displayITI=1*FrameRejt + frames3secs(1);
        displayITIsecs=displayITI/FrameRejt;
  % Return the draw page to where we started (for neatness)
  crsSetDrawPage(CRS.VIDEOPAGE,1,backpix);
     fixpix=255; %255 is white
        %set up the fixation cross
        CrossCentreX = 0;				% position of centre of cross - centre of screen
        CrossCentreY = 0;
        CrossLineLength = 5;		% size of horizontal line of fixation cross in pixels
        CrossLineWidth = 1;
        % select Pen to draw with
        crsSetPen1(fixpix);
        % horizontal and vertical line
        crsDrawRect([CrossCentreX, CrossCentreY], [CrossLineLength, CrossLineWidth]);
        crsDrawRect([CrossCentreX, CrossCentreY], [CrossLineWidth, CrossLineLength]);
%Display the page
crsSetZoneDisplayPage(CRS.VIDEOPAGE,1);
%wait for a random interval
pause(displayITIsecs);
