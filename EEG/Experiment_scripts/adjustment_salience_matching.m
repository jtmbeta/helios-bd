function adjustment_salience_matching(subject,viewdist)

%******************************************************************************
% adjustment to get equal salience of Gabors at different contrast levels
%
% L-M contrasts are fixed and S and lum adjusted to match them 
%
% left button 		increase contrast
% right button 	   decrease contrast
% top button		abort procedure
% bottom button	finish procedure when equality is achieved
%
%written by j martinovic, jan 2024
%******************************************************************************

pathname='\research\wellcome\results\salience\';
hcfppath='\research\wellcome\results\flicker\';

%---------------------------------------------------------
% initialise VSG-Card
%---------------------------------------------------------
global CRS;

crsInit('');                                    % default VSG initialisation
crsSetVideoMode(CRS.EIGHTBITPALETTEMODE+CRS.GAMMACORRECT); % make sure we are using basic CLUT mode
crsSetDrawMode(CRS.CENTREXY + CRS.SOLIDFILL);    % set draw mode co-ordinate system

%Read the framerate for the vsg monitor
vsg_framerate = crsGetSystemAttribute(CRS.FRAMERATE);
%set spatial units
crsSetSpatialUnits( CRS.PIXELUNIT);
%Change the drawing origin to the top-left of the page.
crsSetDrawOrigin([0 0]);
%get screen parameters
ScrHeight=crsGetScreenHeightPixels;
ScrWidth=crsGetScreenWidthPixels;
%screen size in cm
horsize=39.4; versize=39.4;     
horpx=horsize/ScrWidth;
verpx=versize/ScrHeight;
pxsize=(horpx+verpx)/2;
%set viewing distance for subsequent calculations

delete(instrfindall);

%----------------------------------------------------------
%SET COLOUR PARAMETERS
%----------------------------------------------------------
% make a greyscale CLUT - 256x3 matrix, add colours to it
crsSetColourSpace(CRS.CS_RGB);	% use RGB space
%load my own whitepoint from a file
%0000000000000000000000000000000000
%result1=sprintf('c:/research/WP.mat');
%eval(['load ' result1 ]);	% returns WP_xyY

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
LUTBuff(254,:)=[0,0,0]; %black
backpix=256; %set background to 256
whitepix=255;

crsLUTBUFFERWrite(1,LUTBuff);     % load the CLUT into VSG LUT memory
crsLUTBUFFERtoPalette(1);           % make the whitepoint CLUT the current palette

crsSetDrawPage(CRS.VIDEOPAGE,1,backpix);  % clear draw page to grey
crsSetZoneDisplayPage(CRS.VIDEOPAGE,1);   % set display page to draw page

% read in mean results of hcfp
result1=sprintf('c:%s%s.mat',hcfppath,subject);
eval(['load ' result1 ]);

%----------------------------------------
%OPEN FILE FOR RESULTS
%----------------------------------------
% each trial is recorded in a single line in this file
  ch=exist(sprintf(sprintf('c:/research/wellcome/results/salience/%s_matching.result',subject)));
  if ch==0
  fid1=fopen(sprintf('c:/research/wellcome/results/salience/%s_matching.result',subject),'w');
  else
      disp('save file already exists! please recheck participant number or other inputs.')
      return    
  end

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

%-----------------------------------------------------------------
% EXP LIST; setting up the conditions
%-----------------------------------------------------------------
trialscond=6;
cond1=ones(1,trialscond);cond2=repmat(2,1,trialscond); %match S to L-M, 4 levels
cond3=repmat(3,1,trialscond);cond4=repmat(4,1,trialscond); 
cond5=repmat(5,1,trialscond);cond6=repmat(6,1,trialscond); %match lum to L-M, 4 levels
cond7=repmat(7,1,trialscond);cond8=repmat(8,1,trialscond);

conds=[cond1 cond2 cond3 cond4 cond5 cond6 cond7 cond8];
randconds=randperm(length(conds));
saveconds=conds(randconds);
%now i want to save this order of conditions, for rerunning it if necessary
save([pathname '\' subject '_matching_conds.txt'], 'saveconds', '-ASCII');

% -----------------------------------------------------------------------
% displays a page with instructions for the subject and wait for keypress
% -----------------------------------------------------------------------
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
str1='This is an experiment about contrast matching.';
str2='Fixate the cross.';
str3='You will then see two stripy patches on left and right of';
str4='the screen. They differ in colour. Your task is to adjust';
str5='the contrast of one of the patches labelled "Adjust"';
str6='so that it matches the salience of the other';
str7='patch labelled "Fixed" as close as possible:';
str8='the aim is to get them to be equally "contrasty".';
str9='';
str10='Feel free to move your eyes between the patches ';
str11='while you are comparing them. ';
str12='';
str13='Press the LEFT button to increase the contrast.';
str14='Press the RIGHT button to decrease the contrast.';
str15='';
str16='Press the TOP button when you have completed the';
str17='task.';
str18=' ';
str19='Press the LEFT button to start.';

for s=1:19
    crsDrawString([10 10+s*32], eval( sprintf('str%i',s)));
end
%Display the page that the text was drawn onto.
crsSetZoneDisplayPage(CRS.VIDEOPAGE,2);
%read button press from response box
[answer,~,dev]=cedrus_LR(dev);

%display grey for 5 seconds before starting
crsSetDrawPage(CRS.VIDEOPAGE,1, backpix);
crsSetZoneDisplayPage(CRS.VIDEOPAGE,1);
pause(1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN EXPERIMENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%grey adaptation
%Select a page in memory to draw onto.
crsSetDrawPage(CRS.VIDEOPAGE,6, backpix);
crsSetZoneDisplayPage(CRS.VIDEOPAGE,6);

trials_per_block = 60; 

n = 1; %used to count blocks

% start presentation-loop
for j = 1:length(saveconds)
    
    %Pause
    %-------------------------------
    if j == n * trials_per_block + 1
        % generate sound for acoustic feedback - at the end of blocks
        y1=sin(0.5*[1:1024]);
        sound([y1 y1 y1 y1])
        %Select a page in memory to draw onto.
        crsSetDrawPage(CRS.VIDEOPAGE,5, backpix);
        %change centre of drawing back to top left
        crsSetDrawOrigin([0 0]);
        crsDrawString([10 82],'Pause');
        %Display the page that the text was drawn onto.
        crsSetZoneDisplayPage(CRS.VIDEOPAGE,5);
        disp('!!!!Pause!!!!');
        
        %read button press from response box
        % [~ , ~] = cedrus_CRS;
        %[~ , ~] = CT6collect;
        [~ , ~,dev] = cedrus_LR(dev);
        
        %Select a page in memory to draw onto.
        crsSetDrawPage(CRS.VIDEOPAGE,6, backpix);
        crsDrawString([10 82],'Press any key to continue');
        %Display the page that the text was drawn onto.
        crsSetZoneDisplayPage(CRS.VIDEOPAGE,6);
        
        %read button press from response box
        % [~ , ~] = cedrus_CRS;
        %[~ , ~] = CT6collect;
        [~ , ~,dev] = cedrus_LR(dev);
        
        %grey adaptation
        %Select a page in memory to draw onto.
        crsSetDrawPage(CRS.VIDEOPAGE,5, backpix);
        crsSetZoneDisplayPage(CRS.VIDEOPAGE,5);
        pause(5);
        
        n = n + 1;
    end    %end of pause-loop
    
    currentcond=saveconds(j);
    
    %%%%%%%%%%%%%%%%%
    %display stimuli
    %%%%%%%%%%%%%%%%%
    % display the overall number of trials so far
    disp('-------------------');
    disp('Overall trial no.:');
    disp(num2str(j));
    disp('condition');
    disp(num2str(currentcond));
    %display grey for 2 seconds before starting
    crsSetDrawPage(CRS.VIDEOPAGE,1, backpix);
    crsSetZoneDisplayPage(CRS.VIDEOPAGE,1);
    pause(2);
    
    %set up the colours for the stimuli    

%choose the colour to run 
%---------------------
if currentcond<5 %adjust S to L-M
   delta=0.010; %step size
 %standard
    relLum1=relLum_0; th1=0;
        relLum2=relLum_180; th2=180;        
%comp
        relLum11=relLum_90; th11=90;
        relLum22=relLum_270; th22=270;          
else  %adjust lum to L-M
       delta=0.0050; %step size
%standard
       relLum1=relLum_0; th1=0;
        relLum2=relLum_180; th2=180;
        %comp
       relLum11=90; th11=0;
        relLum22=-90; th22=180;        
end

%now select contrasts to use
minLM=0.008;% should be just about visible
maxLM=0.045; %should be high contrast but not too close to gamut limit
LMcs=logspace(log10(minLM),log10(maxLM),4); %get 4 contrast levels in this range logarithmically spacced

if currentcond==1
        radius=LMcs(1); %for stand      
            testRadius=0.08; %for comp - initial
elseif currentcond==2
    radius =LMcs(2);
    testRadius=0.12; %for comp - initial
elseif currentcond==3            
            radius=0.035;
testRadius=LMcs(3);
elseif currentcond==4
radius=LMcs(4);
testRadius=0.27;
elseif currentcond==5
        radius=LMcs(1); %for stand      
            testRadius=0.04; %for comp - initial
elseif currentcond==6
    radius =LMcs(2);
    testRadius=0.08; %for comp - initial
elseif currentcond==7            
            radius=LMcs(3);
testRadius=0.15;
elseif currentcond==8
radius=LMcs(4);
testRadius=0.2;
end

    %----------------------------------------
    % select a random point off the initial radius
    %----------------------------------------
    draw=XausY(1,9);	% up to delta * draw deg off
    up=XausY(1,3);
    if up ==1 % 1 = contrast increases
        testRadius=testRadius + delta*draw;
    else
        testRadius=testRadius -delta*draw;
    end

    %introduce a check to ensure testRadius never goes below zero
    if testRadius <0
        testRadius=0.005;
    end
    

    %-------------------------------------
    %set up the object drawing
    %-------------------------------------    
% Gabor parameters (palette functional form)
  gabor_pixLow = 1; % Select the range of pixel-levels
  gabor_pixHi  = 100; % to draw the gabor with.
  gabor_background_colour = WP_RGB;

    %first Gabor - standard
    STC1=zeros(gabor_pixHi,3);
    no_of_steps=gabor_pixHi/2;
     stepsize=radius/(no_of_steps - 1);
    %     %make empty trivector matrix for stimulus colour in DKL
             for i_decr = 1:no_of_steps
                STC1((no_of_steps-i_decr+1),:) = [i_decr*stepsize th1 relLum1];
             end
             for i_incr = 1:no_of_steps
                 STC1(i_incr+no_of_steps,:) = [i_incr* stepsize th2 relLum2];
             end
% %now turn all those colours into RGB and put them into the LUT buffer
 for colnum=1:gabor_pixHi
      [LUTBuff(colnum,:) ErrorCode]= ctGetColourTrival('CS_DKL','CS_RGB',[WP_RGB',STC1(colnum,:)],deviceSPD,Sensors);
             if ErrorCode == -1, disp('THE REQUESTED COLOUR IS OUT OF RANGE'); end
 end      
    %second Gabor - comparison
    STC2=zeros(gabor_pixHi,3);
    no_of_steps=gabor_pixHi/2;
     stepsize=testRadius/(no_of_steps - 1);
    %     %make empty trivector matrix for stimulus colour in DKL
             for i_decr = 1:no_of_steps
                STC2((no_of_steps-i_decr+1),:) = [i_decr*stepsize th11 relLum11];
             end
             for i_incr = 1:no_of_steps
                 STC2(i_incr+no_of_steps,:) = [i_incr* stepsize th22 relLum22];
             end
% %now turn all those colours into RGB and put them into the LUT buffer
 for colnum=1:gabor_pixHi
      [LUTBuff(colnum+gabor_pixHi,:) ErrorCode]= ctGetColourTrival('CS_DKL','CS_RGB',[WP_RGB',STC2(colnum,:)],deviceSPD,Sensors);
             if ErrorCode == -1, disp('THE REQUESTED COLOUR IS OUT OF RANGE'); end
 end
 
    crsLUTBUFFERWrite(1,LUTBuff);     % load the CLUT into VSG LUT memory
    crsLUTBUFFERtoPalette(1);           % make the whitepoint CLUT the current palette
        
    %-------------------------------------
    %set up the object drawing
    %-------------------------------------
       
    % Set page no and initialise to background colour
    drawingpage = 1;
    crsSetDrawPage(CRS.VIDEOPAGE, drawingpage, backpix);
    % draw the visual search elements
    %Change the drawing origin to the top-left of the page.
    crsSetDrawOrigin([0 0]);
    
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
  gabor_size        = 500;     
  gabor_angle = randi(360); %get random angle for the gabor
  gabor_stdev       = 100; %gabor_size - 0.682*gabor_size; %round(gabor_size/7); 
  gabor_phase      = 0;
  gabor_spatfr= 0.8;
  
% Gabor parameters (palette functional form)
  gabor_pixLow = 1; % Select the range of pixel-levels
  gabor_pixHi  = 100; % to draw the gabor with.
  gabor_background_colour = WP_RGB;  
    
       %determine on which side of the fixation the adjustment circle should
      %appear, what the distance is and label it as the adjustment or
      %target 
      coin=randperm(2);
   if mod(coin(1),2)==0 %even
        xs=round(ScrWidth/2 + gabor_size/2); %standard goes right
        xc=round(ScrWidth/2 - gabor_size/2); %comp goes left
 elseif mod(coin(1),2)==1 %odd
         xs=round(ScrWidth/2 - gabor_size/2); %standard goes left
        xc=round(ScrWidth/2 + gabor_size/2); %comp goes right  
   end
 
    y=ScrHeight/2; %as stimuli are midline we only require one y input
       
crsSetBackgroundColour(gabor_background_colour);

  crsSetDrawPage(CRS.VIDEOPAGE,drawingpage,backpix);
  
        gabor_y_pos = Scrheight/2;

        crsSetPen1(gabor_pixLow);
  crsSetPen2(gabor_pixHi);

        crsDrawGabor([xs,gabor_y_pos], ...
                     [gabor_size, gabor_size],  ...
                      gabor_angle,              ...
                      gabor_spatfr,             ...
                      gabor_stdev,              ...
                      gabor_phase);

                  %draw comparison
                  crsSetPen1(gabor_pixLow+gabor_pixHi);
  crsSetPen2(gabor_pixHi*2);

        crsDrawGabor([xc,gabor_y_pos], ...
                     [gabor_size, gabor_size],  ...
                      gabor_angle,              ...
                      gabor_spatfr,             ...
                      gabor_stdev,              ...
                      gabor_phase);
    
%        crsSetPen1(254); %black
%  %set drawing parameters to outline the centre of the gabor correctly
%        draw_mode_structure.PaintMode = CRS.COPYMODE;
%     draw_mode_structure.FillMode  = CRS.SOLIDPEN;
%     draw_mode_structure.CentreXY  = true; %CENTREXY means that shape is drawn with its centre at the loc point
%     crsSetDrawMode(draw_mode_structure);      
%        % %outline the centre of the stimulus
%        crsDrawOval([xc gabor_y_pos], [gabor_stdev*5,gabor_stdev*5]);
%         crsDrawOval([xs gabor_y_pos], [gabor_stdev*5,gabor_stdev*5]);

       %set pen for writing words
      crsSetPen1(255);
      crsSetPen2(256);
           crsDrawString([xc 50],'Adjust');
        crsDrawString([xs 50],'Fixed');

    %--------------------------------------
    % start with feedback routine
    start =1;	% controls while-loop
         
    while start
        % start with radius defined in testRadius
        disp('-------------------')
        disp(sprintf('radius = %i ',testRadius))
        
        %Load the contents of the Buff into Look Up Table(LUT)
        crsLUTBUFFERWrite(1,LUTBuff);
        crsLUTBUFFERtoPalette(1);           % make the CLUT the current palette        
        
        %display the page
        crsSetDisplayPage(1);
        
        %   [res]=getResponseLR_newmatlab;	% 0=left, 1=right (-1 =abort, top, 2 = finish, bottom)
        %[res] = cedrus_CRS;
try        [res,rt,dev] = cedrus_LR(dev);
        
        switch res
            case 1
                disp('Button pressed = Left');
                testRadius=testRadius+delta;		%more
            case 2
                disp('Button pressed = middle');
                disp('no action taken!');
            case 3
                disp('Button pressed = Right');
                testRadius=testRadius-delta;		%less
            case 4
                start=0;
            case 5
                break;
        end

        catch %to catch the errors with overly rapid button pressing
       continue
end

            %introduce a check to ensure testRadius never goes below zero
    if testRadius <0
   %might be good to introduce a beep here!    
        testRadius=0.005;
    end

    %second Gabor - comparison
    STC2=zeros(gabor_pixHi,3);
    no_of_steps=gabor_pixHi/2;
     stepsize=testRadius/(no_of_steps - 1);
    %     %make empty trivector matrix for stimulus colour in DKL
             for i_decr = 1:no_of_steps
                STC2((no_of_steps-i_decr+1),:) = [i_decr*stepsize th11 relLum11];
             end
             for i_incr = 1:no_of_steps
                 STC2(i_incr+no_of_steps,:) = [i_incr* stepsize th22 relLum22];
             end
% %now turn all those colours into RGB and put them into the LUT buffer
 for colnum=1:gabor_pixHi
      [LUTBuff(colnum+gabor_pixHi,:) ErrorCode]= ctGetColourTrival('CS_DKL','CS_RGB',[WP_RGB',STC2(colnum,:)],deviceSPD,Sensors);
             if ErrorCode == -1, disp('THE REQUESTED COLOUR IS OUT OF RANGE'); end
 end
 
    crsLUTBUFFERWrite(1,LUTBuff);     % load the CLUT into VSG LUT memory
    crsLUTBUFFERtoPalette(1);           % make the whitepoint CLUT the current palette        

    end
    
    %---------------------------------------------------------------
    % get final radius value of the target colour
    %---------------------------------------------------------------    
    strcurrentcond=num2str(currentcond);
    
    disp('------------------------------')
    disp(sprintf('colour %s has a radius of: %f ',strcurrentcond,testRadius))
    disp('------------------------------')
    fprintf(fid1,'%i\t %i\t %i\t %i\t %i\t %i\n',j,currentcond,th1,th2,xs,testRadius); %th, dist,any other important parameter we might want to analyse data by more easily
    
end

%----------------------------------------------
%draw end text
%Select a page in memory to draw onto.
crsSetDrawPage(CRS.VIDEOPAGE,2, backpix);
%Select pixel-level(1) to draw with
crsSetPen1(255);
crsSetPen2(256);
%Load the true type font that you want to write with.
crsSetTrueTypeFont('Arial.ttf');
%Set the draw modes for the text i.e. centred, italic, angle, size.
crsSetStringMode([0 ScrHeight/30], CRS.ALIGNLEFTTEXT, CRS.ALIGNTOPTEXT, 0, CRS.FONTNORMAL);
%Change the drawing origin to the top-left of the page.
crsSetDrawOrigin([0 0]);

%close file
fclose(fid1);

%Draw some text.
str1='Thank you for participating in the experiment!';
crsDrawString([10 82], eval( sprintf('str1')));

%Display the page that the text was drawn onto.
crsSetZoneDisplayPage(CRS.VIDEOPAGE,2);

close all;

    y1=sin(0.5*[1:1024]);
    sound([y1 y1 y1 y1])
