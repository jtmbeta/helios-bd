 crsSetDrawMode(CRS.CENTREXY);    % set draw mode co-ordinate system so centre is 0,0
 %export even
 crsImageExport(CRS.BMPPICTURE,[Scrwidth/2,Scrheight/2],[Scrwidth,Scrheight],'LM_1.bmp');
  