%spectral measurements script

clear all; close all;

global CRS;

% initialise the ViSaGe
crsInit;

% use gamma corrected palette mode
crsSetVideoMode(CRS.EIGHTBITPALETTEMODE + CRS.GAMMACORRECT); 
crsSetColourSpace(CRS.CS_RGB);

%use Stockman & Sharpe (2000) cone fundamentals
Sensors = 'ConeSensitivities_SS_2degELin3908301.mat';
% Define which display device SPD to use.
deviceSPD = 'DisplayPlusPlus.mat';
% Define which colour matching functions to use - CIE 1931 2-deg.
Sensors_CMF = 'CMF_CIE1931_2deg3608301.mat';

%set whitepoint
%load my own whitepoint from a file
%0000000000000000000000000000000000
result1=sprintf('c:/research/WP.mat');
eval(['load ' result1 ]);	% returns WP_xyY

%[WP_RGB,ErrorCode]= crsSpaceToSpace(CRS.CS_CIE1931,WP_xyY,CRS.CS_RGB,0);
%get whitepoint
WP_RGB = ctGetColourTrival('CS_CIE1931xyY','CS_RGB',WP_xyY,deviceSPD,Sensors_CMF);

% make a colour table where everything is set to WP as a default
myLut=repmat(WP_RGB',[256 1]); 
WP_RGB=WP_RGB';

%set background pixel value
backpix=256;

minLM=0.008;% should be just about visible
maxLM=0.045; %should be high contrast but not too close to gamut limit
LMcs=logspace(log10(minLM),log10(maxLM),4); %get 4 contrast levels in this range logarithmically spacced
Scs=[0.0592;0.12583;0.21;0.25083]; %these are the S contrast levels that match to L-M contrasts above
Lumcs=[0.02583;0.07833;0.179167;0.215833]; %lum contrasts that match L-M contrasts above

whiteRGB=[1,1,1];
blackRGB=[0,0,0];

Red_DKL=[LMcs',repmat(0,length(LMcs),1),repmat(0,length(LMcs),1)]; 
Green_DKL=[LMcs',repmat(180,length(LMcs),1),repmat(0,length(LMcs),1)]; 
Blue_DKL=[Scs,repmat(270,length(Scs),1),repmat(0,length(Scs),1)]; 
Yellow_DKL=[Scs,repmat(90,length(Scs),1),repmat(0,length(Scs),1)]; 

%TRANSFORM THESE DKL COLS TO RGB
%from colour needs a vector: whitepoint in rgb & colour in DKL to transform
for n=1:length(LMcs)
[myLut(n,:) ErrorCode] = ctGetColourTrival('CS_DKL','CS_RGB',[WP_RGB,Red_DKL(n,:)],deviceSPD,Sensors);
if ErrorCode == -1
    warning('THE REQUESTED red COLOUR IS OUT OF RANGE');
end
end

for n=1:length(LMcs)
[myLut(n+4,:) ErrorCode] = ctGetColourTrival('CS_DKL','CS_RGB',[WP_RGB,Green_DKL(n,:)],deviceSPD,Sensors);
if ErrorCode == -1
    warning('THE REQUESTED green COLOUR IS OUT OF RANGE');
end
end

for n=1:length(LMcs)
[myLut(n+8,:) ErrorCode] = ctGetColourTrival('CS_DKL','CS_RGB',[WP_RGB,Blue_DKL(n,:)],deviceSPD,Sensors);
if ErrorCode == -1
    warning('THE REQUESTED blue COLOUR IS OUT OF RANGE');
end
end

for n=1:length(LMcs)
[myLut(n+12,:) ErrorCode] = ctGetColourTrival('CS_DKL','CS_RGB',[WP_RGB,Yellow_DKL(n,:)],deviceSPD,Sensors);
if ErrorCode == -1
    warning('THE REQUESTED yellow COLOUR IS OUT OF RANGE');
end
end

crsLUTBUFFERWrite(1, myLut); 
crsLUTBUFFERtoPalette(1);

% set up a blank black page
crsSetDrawPage(CRS.VIDEOPAGE,1,backpix);
crsSetDisplayPage(1);

% set drawing units to mm
%crsSetSpatialUnits(CRS.MMUNIT);
crsSetDrawMode(CRS.SOLIDFILL + CRS.CENTREXY);

% red square
crsSetPen1(17);
crsDrawRect([0,0],[400,400]);

