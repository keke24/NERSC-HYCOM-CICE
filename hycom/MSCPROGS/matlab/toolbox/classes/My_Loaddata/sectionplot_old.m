function fig=sectionplot_old(section_number,record_number,varname,varargin)
%function fig=sectionplot(section_number,record_number,varname,varargin)
%A function which plots time record <record_number>
%from section <section_number> - Reads files generated by pak2sec
%
%
% Optional parameter/value pairs:
% 'showgrid'  - turn on(1)/off(0) hycom grid display, default is 0
% 'crange'    - Color range - vector with two values, max and min
% 'contours'  - vector - the values will be shown as contours on the plot
% 'staircase' - turn on(1)/off(0) staircase plot of variable
%
%
% Examples:
%    fig=sectionplot(1,1,'TEM') -- Plots temperature for section 1, time index 1
%    fig=sectionplot(4,1,'TEM') -- Plots temperature for section 4, time index 1
%
% Example with optional values, showing grid overlay and contour lines:
%    fig=sectionplot(1,1,'TEM','showgrid',1,'contours',[ 0 2 4 8 12]) 
%
%
%Function Returns a handle to the figure

%nargin
%size(varargin)
%varargin
grid=0;
prange=[];
staircasebottom=0 ; % in testing :-)
Vcontours=[];
if(nargin>3 ) 
   for i=1:2:size(varargin,2)
      if (strcmp(varargin{i},'showgrid'))
         grid=varargin{i+1};
      end
      if (strcmp(varargin{i},'crange'))
         prange=varargin{i+1};
      end
      if (strcmp(varargin{i},'contours'))
         Vcontours=varargin{i+1};
      end
      if (strcmp(varargin{i},'staircase'))
         staircasebottom=varargin{i+1};
      end
   end
end
   


% Check for section file
csec=num2str(section_number,'%3.3d');
fname=['section' csec '.nc'];
nc=netcdf(fname);
if (isempty(nc))
   disp([' No file ' fname '. I Qui1!']);
   return
end 

if (prod(size(recdim(nc)))<record_number)
   disp([' Record exceeds number of records in netcdf file']);
   return
end 

% We should be set
dist=nc{'distance',1}(:); % Distance along section
if (isempty(dist)) 
   disp(['Could not get cumulative distance ']);
   return
end

% Depthf is variable for corner plotting
depthc=nc{'depthc',1}(record_number,:,:);
if (isempty(depthc)) 
   disp(['Could not get depthc ']);
   return
end

% Depthf is variable for contour plotting
depthf=nc{'depthf',1}(record_number,:,:);
if (isempty(depthf)) 
   disp(['Could not get depthf ']);
   return
end
kdm=size(depthf,1);
dist2=repmat(dist',kdm,1);

% Get variable:
%autonan(nc{varname})
tmp=nc{varname,1}(record_number,:,:); % Distance along section
if (isempty(tmp)) 
   disp(['Could not get variable ' varname]);

   % Show list of variables
    tst=var(nc);
    disp('Names of variables in netcdf file:')
    for i=1:prod(size(tst))
       disp(ncnames(tst(i)));
    end
   return
else
   %Display variable description if available
   tmpatt=nc{varname}.description(:);
   if (~isempty(tmpatt)) ;
      disp(['Short description of variable: ' tmpatt])
   end
end
%tmp=var(nc)
%name(tmp(1))

% Treat empty layer:
for k=2:kdm
   %I=find(abs(depthc(k-1,:)-depthc(k,:)) <=3.);

   I=find(tmp(k,:)<-20000.);
   tmpvar=tmp(k,:);
   tmpvar(I)=tmp(k-1,I);
   tmp(k,:)=tmpvar;
end

%depthc(:,16)




%Mask -- 
tmp2=nc{'DP',1}(record_number,:,:); 
if (isempty(tmp2)) 
   disp(['Could not get variable DP ']);
   return
end

mlim=0.01;
mask=find(tmp2<mlim);
mask2=find(tmp2>=mlim);

med=median(tmp(mask2));
mn=mean(tmp(mask2));
stdev=std(tmp(mask2));
%tmp(mask)=nan;
%whos;


%V holds min/max values
gcf; clf; F=gcf;
if (isempty(prange))
   V=[ mn-3*stdev    mn+3*stdev ];
else
   V=prange;
end
%V



%KAL -- always use pcolor
I=find(tmp>max(V)); 
tmp(I)=max(V);
I=find(tmp<min(V)); 
tmp(I)=min(V);

% This is if you want a "staircase" - type plot
if (staircasebottom==1)
   % Create new staircase arrays
   %size(dist)
   %size(depthf)
   stdist2 =zeros(size(depthf,1),2*prod(size(dist))-1);
   stdepthf=zeros(size(depthf,1),2*prod(size(dist))-1);
   stdepthc=zeros(size(depthc,1),2*prod(size(dist))-1);
   sttmp   =zeros(size(depthf,1),2*prod(size(dist))-1);
   for k=1:prod(size(dist))
      for l=1:size(depthf,1);
         if (k<prod(size(dist)))
            stdist2 (l,2*k-1)    =dist2 (l,k);
            stdist2 (l,2*k  )    =dist2 (l,k+1);
            stdepthf(l,2*k-1:2*k)=depthf(l,k);
            stdepthc(l,2*k-1:2*k)=depthc(l,k);
            sttmp   (l,2*k-1:2*k)=tmp   (l,k);
         else
            stdist2 (l,2*k-1)    =dist2 (l,k);
            stdepthf(l,2*k-1)    =depthf(l,k);
            stdepthc(l,2*k-1)    =depthc(l,k);
            sttmp   (l,2*k-1)    =tmp   (l,k);
         end
      end
   end 
end 


if (staircasebottom==1)
   P=pcolor(stdist2/1000,stdepthc,sttmp);
else
   P=pcolor(dist2/1000,depthc,tmp);
end
set(P,'LineStyle','none')

%end
caxis([min(min(V)) max(max(V))]);
A=gca;
set(A,'Fontweight','bold');
set(A,'FontSize',14)      ;
xlabel('Distance [km]');
ylabel('Depth [m]');
hold on;

%figure(2); clf
%[C,H]=contourf(dist2/1000,depthc,tmp,V);

      

if (staircasebottom==1)
   P=stairs(stdist2(kdm,:)/1000,stdepthc(kdm,:));
   set(P,'color','k');
   set(P,'LineWidth',3);
else
   P=plot(dist/1000,depthc(kdm,:));
   set(P,'color','k');
   set(P,'LineWidth',3);
end

% grid
if (grid==1)
   for k=1:kdm
      P=plot(dist/1000,depthc(k,:));
      set(P,'color',[.7 .7 .7]);
      set(P,'LineWidth',0.5);
   end
end

if (~isempty(Vcontours))
   [C,H]=contour(dist2/1000,depthc,tmp,Vcontours);
   set(H,'EdgeColor','k')
   set(H,'LineWidth',2)
   clabel(C,H,'fontsize',15,'FontWeight','bold','color','k','rotation',0,'LabelSpacing',250)
end




% Return figure handle
colorbar;
%tmp
%whos
close(nc);
if (nargout==1)
   fig=F;
end

hold off;