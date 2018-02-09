function varargout = dFoverFMontage(data,params,varargin)
% dFoverF(data,params,montageflag)

if ~isfield(data,'exposure')
    fprintf(1,'No Camera Input: Exiting dFoverF routine\n');
    return
end
fig = findobj('tag',mfilename); 
if isempty(fig);
    if ~isacqpref('AnalysisFigures') ||~isacqpref('AnalysisFigures',mfilename) % rmacqpref('AnalysisFigures','powerSpectrum')
        proplist = {...
            'tag',mfilename,...
            'Position',[1030 181 560 275],...
            'NumberTitle', 'off',...
            'Name', mfilename,... % 'DeleteFcn',@obj.setDisplay);
            };
        setacqpref('AnalysisFigures',mfilename,proplist);
    end
    proplist =  getacqpref('AnalysisFigures',mfilename);
    fig = figure(proplist{:});
end
ax = findobj('tag',[mfilename 'ax']);
if isempty(ax)
    ax = subplot(1,1,1,'parent',fig,'tag',[mfilename 'ax']);
else
    delete(get(ax,'children'));
end

dummyax = findobj('tag',[mfilename 'dummyax']);
if isempty(dummyax)
    dummyax = axes('Position',get(ax,'Position'),...
        'tag',[mfilename 'dummyax'],...
        'parent',fig,...
        'XAxisLocation','top',...
        'Color','none',...
        'Ytick',[],...
        'XColor','k','YColor','k');
else
    delete(get(dummyax,'children'));
end

D ='';
if ~isfield(data,'imageNum')
    fn = varargin{2};
    D = fn(1:regexp(fn,['\\' params.protocol]));
    jnk = load(fn,'imageNum');
    if ~isfield(jnk,'imageNum')
        error('No image number! Not running dFoverF');
    else
        data.imageNum = jnk.imageNum;
    end
end

t = makeInTime(params);
exp_t = t(data.exposure);

%%  Currently, I'm saving images as single files.  Sucks!
%[filename, pathname] = uigetfile('*.tif', 'Select TIF-file');

filebase = [D params.protocol '_Image_' num2str(data.imageNum) '_'];
imagefiles = dir([filebase '*']);
num_frame = length(imagefiles);
im = imread([D imagefiles(1).name]);
num_px = size(im);

I = zeros([num_px(:); 1; num_frame]', 'double');  %preallocate 3-D array
%read in .tif files
for frame=1:num_frame
    [I(:,:,1,frame)] = imread([D imagefiles(frame).name]);
end

%% select ROI (implement at some point)


%% calculates a baseline image from frame bl_start through bl_end 
bsln = exp_t<0;

bl_numframes = sum(bsln);
image_sum = sum(I(:,:,1,bsln),4);
I_F0 = imdivide(image_sum, bl_numframes);

I_trace = mean(mean(I,1),2);
I_trace = reshape(I_trace,1,numel(I_trace));
dFoverF_trace = I_trace/mean(mean(I_F0)) - 1;

line(exp_t(1:length(I_trace)),dFoverF_trace,'parent',ax)
axis(ax,[exp_t(1) exp_t(length(I_trace)) get(ax,'ylim')])
line((1:length(I_trace)),dFoverF_trace,'parent',dummyax,'linestyle','none')
axis(dummyax, [1 length(I_trace) get(ax,'ylim')]);

%calculate change in fluorescence frame by frame relative to baseline
I_dFovF = I;
for frame=1:num_frame
    I_dFovF(:,:,1,frame) = (I(:,:,1,frame) ./ I_F0)-1;
    I_dFovF(I_dFovF(:,:,1,frame) >= 500,1,frame) = 0;
end

%apply Gaussian filter:
%rotationally symmetric Gaussian lowpass filter of size 5x5 with standard deviation
%sigma 2 (positive). 
G = fspecial('gaussian',[3 3],2);
I_dFovF_thr_filt = imfilter(I_dFovF,G);
%I_dFovFmov = imfilter(I,G);

% if montageflag
%     %plot montage of dFoverF images
%     c = [min(min(min(min(I_dFovF)))) max(max(max(max(I_dFovF))))];
%     
%     Idim = size(I);
%     Checkers = ones([Idim(1:3), Idim(4)*2])*c(1);
%     Checkers(:,:,1,2:2:end) = I_dFovF_thr_filt;
%     
%     figure
%     dim1 = floor(sqrt(Idim(4)*2));
%     if ~mod(dim1,2)
%         dim1 = dim1-1;
%     end
%     montage(Checkers,'Size',[NaN dim1])
%     colormap(hot)
%     caxis(c)
%     % t=[num2str(filebase)];
%     % title(t)
%     
% %     figure
% %     mov = immovie(I,hot);
% %     implay(mov);
% end

varargout = {I};
