function wellcome_VEP_trial(cond,backpix,Sensors,deviceSPD,WP_RGB,LUTBuff,gabor_angle,relLum0,relLum90,relLum180,relLum270,viewdist)

%---------------------------------------------------------
% initialise VSG-Card
%---------------------------------------------------------
global CRS;

%set spatial units
%crsSetSpatialUnits( CRS.DEGREEUNIT);

% -----------------------------------------------------------------------------
% INITIALISE gabor PARAMETERS
% -----------------------------------------------------------------------------
  Scrwidth        = crsGetScreenWidth;  
  Scrheight       = crsGetScreenHeight; 
     FrameRejt = crsGetFrameRate;

     %screen size in cm 
horsize=39.4; versize=39.4;
horpx=horsize/Scrwidth;
verpx=versize/Scrheight;
pxsize=(horpx+verpx)/2;
   %calculate size of 1 deg in pixels
    visang_rad = 2 * atan(horsize/2/viewdist);
    visang_deg = visang_rad * (180/pi);
    pix_pervisang = round(Scrwidth / visang_deg);

% Gabor parameters (in degrees)
  gabor_size        = 550;     
  gabor_stdev       = 100; %gabor_size - 0.682*gabor_size; %round(gabor_size/7); 
  gabor_phase      = 0;
  gabor_spatfr= 0.8;
  
% Gabor parameters (palette functional form)
  gabor_pixLow = 1; % Select the range of pixel-levels
  gabor_pixHi  = 100; % to draw the gabor with.
  gabor_background_colour = WP_RGB;

%   %set the gabor colour
%   %---------------------
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
     STC=zeros(gabor_pixHi,3);
    no_of_steps=gabor_pixHi/2;
     stepsize=stimint/(no_of_steps - 1);

%if cond> 6 %bipolar Gabor
    %     %make empty trivector matrix for stimulus colour in DKL
             for i_decr = 1:no_of_steps
                STC((no_of_steps-i_decr+1),:) = [i_decr*stepsize th1 relLum1];
             end
             for i_incr = 1:no_of_steps
                 STC(i_incr+no_of_steps,:) = [i_incr* stepsize th2 relLum2];
             end
% elseif cond<7 %unipolar gabor
%     %draw the grating
%  %   pixnums=crsDrawGrating([Scrwidth/2,Scrheight/2],gabor_size,180,1);%180 is angle, 1 is spat freq
%  %   numlevels=floor(pixnums(1)/2); %get number of pixels needed
%     %select pixel levels for grating
% %gabor_pixHi=gabor_pixLow+pixnums(1);
%     %set LUT buffers for drawing the gratings
%  %   pixLow=gabor_pixLow;
% %    gaussian_step=0:stimint/(gabor_pixHi-gabor_pixLow):stimint;
% %    gaussian_step_down=fliplr(gaussian_step);
% %    STC=[gaussian_step_down',repmat(th,numlevels,1),repmat(relLum1,numlevels,1)];
%              for i_decr = 1:no_of_steps
%                 STC((no_of_steps-i_decr+1),:) = [i_decr*stepsize th1 relLum1];
%              end
%              for i_incr = 1:no_of_steps
%                  STC(i_incr+no_of_steps,:) = [0 th2 relLum2];
%              end
% end

% %now turn all those colours into RGB and put them into the LUT buffer
 for colnum=1:gabor_pixHi
      [LUTBuff(colnum,:) ErrorCode]= ctGetColourTrival('CS_DKL','CS_RGB',[WP_RGB,STC(colnum,:)],deviceSPD,Sensors);
             if ErrorCode == -1, disp('THE REQUESTED COLOUR IS OUT OF RANGE'); end
 end
 
 LUTBuff(255,:)=[1 1 1]; %add white for fixation
 crsLUTBUFFERWrite(1,LUTBuff);     % load the CLUT into VSG LUT memory
 crsLUTBUFFERtoPalette(1);           % make the whitepoint CLUT the current palette

% -----------------------------------------------------------------------------
% DRAW THE GABOR
% -----------------------------------------------------------------------------

   %Change the drawing origin to the top-left of the page.
crsSetDrawOrigin([0 0]);

crsSetPen1(gabor_pixLow);
  crsSetPen2(gabor_pixHi);

  crsSetBackgroundColour(gabor_background_colour);

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

%now have a fixation cross page
fixpage=2;  
crsSetDrawPage(CRS.VIDEOPAGE,fixpage,backpix);
% horizontal and vertical line
crsDrawRect([CrossCentreX, CrossCentreY], [CrossLineLengthHor, CrossLineWidth]);
crsDrawRect([CrossCentreX, CrossCentreY], [CrossLineWidth, CrossLineLengthVer]);

%==================================
% Set up the page cycling data.
%==================================
       % Set up indexes for pages
        %           1 page for stimulus
        %           1 page  for fixation cross

        fix1=1;
        stim = fix1+1;
        fix2=stim+1;
        totalpages = fix2;

% -------------------
% Set up page buffer
% -------------------
% page buffer 1: fixation
pagebuff(1).Page   = fixpage;
pagebuff(1).Xpos   = 0;
pagebuff(1).Ypos   = 0;
pagebuff(1).ovPage = 0;
pagebuff(1).ovXpos = 0;
pagebuff(1).ovYpos = 0;
pagebuff(1).Frames = FrameRejt*0.5;	
pagebuff(1).Stop   = 0;
    
       % initialize all pages to first page == fixation cross settings
        for k=1:totalpages
            pagebuff(k)=pagebuff(1);
        end

        pagebuff(stim).Page = gabor_page+CRS.TRIGGERPAGE;
        pagebuff(stim).Frames = FrameRejt*0.5; 

        pagebuff(fix1).Page = fixpage;
        pagebuff(fix1).Frames = FrameRejt*0.5; 

                pagebuff(fix2).Page = fixpage;
        pagebuff(fix2).Frames = FrameRejt*1; 
        
              %last page stop, otherwise goes in loop!
        pagebuff(totalpages).Stop=[1];	   % end cycling

  % load the page cycling array (We can enable and disable later)
  crsPageCyclingSetup(pagebuff);

%we need to have 2 frame length triggers or they won't show  
length=2; %how many frames
crsSetTriggerOptions(CRS.TRIGGER_OPTIONS_PAGECYCLE,0,0,length,0,0,0);

% -----------------------------------------------------------------------------
% FINISHED PREPARING OUR STIMULI. NOW WE CAN RUN OUR EXPERIMENT
% -----------------------------------------------------------------------------        
tic
% Send the command to start the vsg page cycling.
        crsSetCommand(CRS.CYCLEPAGEENABLE);
%       crsIOWriteDigitalOut(1); %manual sending of the trigger - it's a fix
%           WaitSecs(0.01);    
        crsResetTimer;
% 
% %check if the trial is over
 timer=crsGetTimer;
% while timer <= (0.24*1000000) %wait for 0.24 secs
%     % Choose 4 msecs, as PTB would not release the cpu for wait
%     % times below 3 msecs (to account for MS-Windows miserable
%     % process scheduler).
%     timer=crsGetTimer;
%     WaitSecs(0.004);
% end
% 
% crsIOWriteDigitalOut(0); %manual sending of the trigger - it's a fix
% 
while timer <= (2*1000000) %wait 
    % Choose 4 msecs, as PTB would not release the cpu for wait
    % times below 3 msecs (to account for MS-Windows miserable
    % process scheduler).
    timer=crsGetTimer;
    WaitSecs(0.004);
end

%while crsGetPageCyclingState>-1
            %optionally do stuff like check response boxes, or just leave blank
%end
toc
 
 