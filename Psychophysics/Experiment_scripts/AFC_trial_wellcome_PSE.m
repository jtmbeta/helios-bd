function [colbutt,standardbutt,LUTBuff]=AFC_trial_wellcome_PSE(testh,backpix,locations,size_gaussian,gaussstdev,stimint,L,C,h,WP_xyY,deviceSPD,Sensors_CMF,LUTBuff)
%-------------------------------------------------------------------
%set up the display parameters and draw pages
%-------------------------------------------------------------------
global CRS;

%Read the framerate for the vsg monitor
FrameRate = crsGetSystemAttribute(CRS.FRAMERATE);
%set spatial units
crsSetSpatialUnits( CRS.PIXELUNIT);
%Change the drawing origin to the top-left of the page.
crsSetDrawOrigin([0 0]);
%get screen parameters
ScrHeight=crsGetScreenHeightPixels;
ScrWidth=crsGetScreenWidthPixels;

% To determine which side to put colour on
    side=randi(2,1);
    if side==1
        target=2; %this is the location on which we're drawing the target - left or right
        standard=1;
        standardbutt=3;
        colbutt=1;
        disp('Comparison Colour On Left');
    elseif side==2
        target=1;
        standard=2;
        standardbutt=1;
        colbutt=3;
        disp('Comparison Colour on Right');
    end
    
%---------------------------------------------------------
% set up a blank page for fixation cross
%----------------------------------------------
crosspage = 1;
crsSetDrawPage(CRS.VIDEOPAGE,crosspage,backpix);

fixpix=255; % is white
%set up the fixation cross
CrossCentreX = ScrWidth/2;				% position of centre of cross - centre of screen
CrossCentreY = ScrHeight/2;
CrossLineLength = 20;		% size of horizontal line of fixation cross in pixels
CrossLineWidth = 2;
% select Pen to draw with
crsSetPen1(fixpix);
% horizontal and vertical line
crsDrawRect([CrossCentreX, CrossCentreY], [CrossLineLength, CrossLineWidth]);
crsDrawRect([CrossCentreX, CrossCentreY], [CrossLineWidth, CrossLineLength]);

%-------------------------------------------
% set up a blank page for the stimulus
stimpage = 2;
crsSetDrawPage(CRS.VIDEOPAGE,stimpage,backpix);

    %------------------------------------------
    %STANDARD STIMULUS
    %------------------------------------------
    %set pixel levels for drawing the gaussian of the standard
     gausspixLow=2;
%     gausspixHi=9;

    %set up standard
    standLCh=[L,C,h];
        %now make this Lch colour into xyY
        standlab=lch2lab(standLCh);
    standxyz=lab2xyz(standlab,'D65/2');
    standxyY=ctComputexyYfromXYZ(standxyz);
    %now make a gaussian out of that
 %   stand_gauss=[(WP_xyY(1):(standxyY(1)-WP_xyY(1))/(gausspixHi-gausspixLow):standxyY(1))',(WP_xyY(2):(standxyY(2)-WP_xyY(2))/(gausspixHi-gausspixLow):standxyY(2))',(WP_xyY(3):(standxyY(3)-WP_xyY(3))/(gausspixHi-gausspixLow):standxyY(3))'];
  %  for colnum=1:(gausspixHi-gausspixLow+1)
  %      [LUTBuff((colnum),:) ErrorCode] = ctGetColourTrival('CS_CIE1931xyY','CS_RGB',stand_gauss(colnum,:),deviceSPD,Sensors_CMF);
  %      if ErrorCode == -1, warning('THE standard COLOUR IS OUT OF RANGE'); end
  %  end
        [LUTBuff(gausspixLow,:) ErrorCode] = ctGetColourTrival('CS_CIE1931xyY','CS_RGB',standxyY,deviceSPD,Sensors_CMF);
            
    %set pens for drawing the gaussians of the standard
%    crsSetPen1(gausspixHi);
%    crsSetPen2(gausspixLow);
    %draw the gaussians for standard
%     draw_mode_structure.CentreXY  = true;
%     crsDrawGaussian(locations(standard,:),size_gaussian(standard,:),gaussstdev(standard));
% 
%         %make 80% of the circle filled with colour, with the rest graded
%         edgeRatio=0.20;
%         sqsize=round((1-edgeRatio)*size_gaussian(1));
%         w=0:1/8:1; %spaced weightings for 9 cols, for next step (as we have only 9 pixel levels to fill i.e. 20%
%         %do linear interpolation
%         for n=1:numel(w), siz(n,:)=floor(w(n)*sqsize + (1-w(n))*size_gaussian(1)); end
%     siz=siz';
%     
%        for n=1:length(siz) %the number of squares
%         crsSetPen1(gausspixLow+n-1);
%            crsDrawOval(locations(standard,:),repmat(siz(n),1,2));
%         end
          crsSetPen1(gausspixLow);
            crsDrawOval(locations(standard,:),size_gaussian(standard,:));

    %------------------------------------
    %COMPARISON STIMULUS
    %------------------------------------
    %set pens for drawing the gaussian of the comparison
    targetpixLow=21;
%     targetpixHi=40;
    if testh==3 %for lum condition, we change L
    targetc=[stimint,C,h];     
    else
    targetc=[L,C,stimint]; 
    end
    
        %now make this Lch colour into xyY
    targetlab=lch2lab(targetc);
    targetxyz=lab2xyz(targetlab,'D65/2');
    targetxyY=ctComputexyYfromXYZ(targetxyz);
    %now make a gaussian out of that 
%     target_gauss=[(WP_xyY(1):(targetxyY(1)-WP_xyY(1))/(targetpixHi-targetpixLow):targetxyY(1))',(WP_xyY(2):(targetxyY(2)-WP_xyY(2))/(targetpixHi-targetpixLow):targetxyY(2))',(WP_xyY(3):(targetxyY(3)-WP_xyY(3))/(targetpixHi-targetpixLow):targetxyY(3))'];
%     for colnum=1:(targetpixHi-targetpixLow+1)
%         [LUTBuff((20+colnum),:) ErrorCode] = ctGetColourTrival('CS_CIE1931xyY','CS_RGB',target_gauss(colnum,:),deviceSPD,Sensors_CMF);
%         if ErrorCode == -1, warning('THE comparison COLOUR IS OUT OF RANGE'); end
%     end    
 
        [LUTBuff((targetpixLow),:) ErrorCode] = ctGetColourTrival('CS_CIE1931xyY','CS_RGB',targetxyY,deviceSPD,Sensors_CMF);

    %target pens
     crsSetPen1(targetpixLow);
%     crsSetPen2(targetpixLow);
%     %draw the gabor target
%     draw_mode_structure.CentreXY  = true;
%     crsDrawGaussian(locations(target,:),size_gaussian(target,:),gaussstdev(target));

            crsDrawOval(locations(target,:),size_gaussian(target,:));

    crsLUTBUFFERWrite(1,LUTBuff);     % load the CLUT into VSG LUT memory
    crsLUTBUFFERtoPalette(1);         % make the whitepoint CLUT the current palette
    
    %draw fixation cross
    crsSetPen1(fixpix);
    % horizontal and vertical line
    crsDrawRect([CrossCentreX, CrossCentreY], [CrossLineLength, CrossLineWidth]);
    crsDrawRect([CrossCentreX, CrossCentreY], [CrossLineWidth, CrossLineLength]);

%---------------------------------------------------------
% set up a blank page for fixation cross
%----------------------------------------------
crosspage2 = 3;
crsSetDrawPage(CRS.VIDEOPAGE,crosspage2,backpix);

fixpix=255; % is white
%set up the fixation cross
CrossCentreX = ScrWidth/2;				% position of centre of cross - centre of screen
CrossCentreY = ScrHeight/2;
CrossLineLength = 20;		% size of horizontal line of fixation cross in pixels
CrossLineWidth = 2;
% select Pen to draw with
crsSetPen1(fixpix);
% horizontal and vertical line
crsDrawRect([CrossCentreX, CrossCentreY], [CrossLineLength, CrossLineWidth]);
crsDrawRect([CrossCentreX, CrossCentreY], [CrossLineWidth, CrossLineLength]);

%SAVE LUT BUFFER
%------------------------------
crsLUTBUFFERWrite(1,LUTBuff);     % load the CLUT into VSG LUT memory
crsLUTBUFFERtoPalette(1);           % make the whitepoint CLUT the current palette

%==================================
% Set up the page cycling data.
%==================================
% Set up indexes for pages
%           1 page  for fixation cross (varies in length)
%           1 page for stimulus
%           1 page  for fixation cross

fix1 = 1;
stim = fix1 + 1;
fix2= stim +1;

totalpages = fix2;

% -------------------
% Set up page buffer
% -------------------
% page buffer 1: fixation cross
pagebuff(1).Page   = crosspage;
pagebuff(1).Xpos   = 0;
pagebuff(1).Ypos   = 0;
pagebuff(1).ovPage = 0;
pagebuff(1).ovXpos = 0;
pagebuff(1).ovYpos = 0;
pagebuff(1).Frames = FrameRate;
pagebuff(1).Stop   = 0;

% initialize all pages to first page == fixation cross settings
for k=1:totalpages
    pagebuff(k)=pagebuff(1);
end

pagebuff(fix1).Page = crosspage;
pagebuff(fix1).Frames = FrameRate*0.7;	% 700ms

%stimulus
pagebuff(stim).Page =stimpage;
pagebuff(stim).Frames = FrameRate*0.6;

%         % Set buffer pages at the very end to fixation.
pagebuff(fix2).Page = crosspage2;
pagebuff(fix2).Frames = FrameRate*0.7;

%last page stop, otherwise goes in loop!
pagebuff(totalpages).Stop=[1];	   % end cycling

%---------------------------------------
% Start the page cycling
%---------------------------------------
% Load the page cycling data into the vsg card.
crsPageCyclingSetup(pagebuff);

% Send the command to start the vsg page cycling.
crsSetCommand(CRS.CYCLEPAGEENABLE);

%reset visage timer, for later rt functions:
crsResetTimer;