classdef PiezoCourtshipSong < FlySoundProtocol
    properties (Constant)
        protocolName = 'PiezoCourtshipSong';
        requiredRig = 'PiezoRig';
        analyses = {};
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
        gaincorrection
    end
    
    events
    end
    
    methods
        
        function obj = PiezoCourtshipSong(varargin)
            obj = obj@FlySoundProtocol(varargin{:});
            p = inputParser;
            p.addParamValue('modusOperandi','Run',...
                @(x) any(validatestring(x,{'Run','Stim','Cal'})));
            parse(p,varargin{:});
            obj.modusOperandi = p.Results.modusOperandi;
            if strcmp(p.Results.modusOperandi,'Cal')
                obj.gaincorrection = [];
            else
                correctionfiles = dir('C:\Users\Anthony Azevedo\Code\FlySound\Rig Calibration\PiezoCourtshipCorrection*.mat');
                if ~isempty(correctionfiles)
                    cfdate = correctionfiles(1).date;
                    cf = 1;
                    cfdate = datenum(cfdate);
                    for d = 2:length(correctionfiles)
                        if cfdate < datenum(correctionfiles(d).date)
                            cfdate = datenum(correctionfiles(d).date);
                            cf = d;
                        end
                    end
                    temp = load(correctionfiles(cf).name);
                    obj.gaincorrection = temp.d;
                else
                    obj.gaincorrection = [];
                end
            end
        end
        
        function varargout = getStimulus(obj,varargin)
            if ~isempty(obj.gaincorrection) && isstruct(obj.gaincorrection)
                gain = obj.gaincorrection.gain(...
                    round(obj.gaincorrection.displacement*1e5)/1e5 == round(obj.params.displacement*1e5)/1e5,...
                    round(obj.gaincorrection.freqs*1e5)/1e5 == round(obj.params.freq*1e5)/1e5);
                offset = obj.gaincorrection.offset(...
                    round(obj.gaincorrection.displacement*1e5)/1e5 == round(obj.params.displacement*1e5)/1e5,...
                    round(obj.gaincorrection.freqs*1e5)/1e5 == round(obj.params.freq*1e5)/1e5);
                if isempty(gain) || isempty(offset)
                    gain = 1;
                    offset = 0;
                    notify(obj,'StimulusProblem',StimulusProblemData('UncalibratedStimulus'))
                end
            else gain = 1; offset = 0;
                if strcmp(obj.modusOperandi,'Cal')
                    commandstim = obj.gaincorrection * obj.params.displacement + obj.params.displacementOffset;
                    notify(obj,'StimulusProblem',StimulusProblemData('CalibratingStimulus'));
                end
            end
            if obj.params.displacement*gain + obj.params.displacementOffset + offset >= 10 || ...
                    obj.params.displacementOffset+offset-obj.params.displacement*gain >= 10
                gain = 1;
                offset = 0;
                notify(obj,'StimulusProblem',StimulusProblemData('StimulusOutsideBounds'))
            end
            calstim = obj.y * obj.params.displacement +obj.params.displacementOffset;
            obj.out.piezocommand = calstim;
            varargout = {obj.out,calstim,commandstim};
        end
        
    end % methods
    
    methods (Access = protected)
        
        function defineParameters(obj)
            % rmpref('defaultsPiezoCourtshipSong')
            obj.params.displacementOffset = 5;
            obj.params.sampratein = 40000;
            [stim,obj.params.samprateout] = wavread('CourtshipSong.wav');
            obj.params.sampratein = obj.params.samprateout;
            obj.params.displacements = .1;
            obj.params.displacement = obj.params.displacements(1);

            obj.params.ramptime = 0.04; %sec;
            
            obj.params.stimDurInSec = length(stim)/obj.params.samprateout;
            obj.params.preDurInSec = .4;
            obj.params.postDurInSec = .3;
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            
            obj.params.Vm_id = 0;
            
            obj.params = obj.getDefaults;
        end
        
        function setupStimulus(obj,varargin)
            setupStimulus@FlySoundProtocol(obj);

            [stim,obj.params.samprateout] = wavread('CourtshipSong.wav');
            [standardstim] = wavread('CourtshipSong_Standard.wav');
            obj.params.stimDurInSec = length(stim)/obj.params.samprateout;

            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.x = makeOutTime(obj);
            obj.x = obj.x(:);

            y = makeOutTime(obj);
            y = y(:);
            y(:) = 0;

            stimpnts = round(obj.params.samprateout*obj.params.preDurInSec+1:...
                obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec));
            
            w = window(@triang,2*obj.params.ramptime*obj.params.samprateout);
            w = [w(1:obj.params.ramptime*obj.params.samprateout);...
                ones(length(stimpnts)-length(w),1);...
                w(obj.params.ramptime*obj.params.samprateout+1:end)];
            y(stimpnts) = w.*stim;
            obj.y = y;
            obj.out.piezocommand = y;
            if isempty(obj.gaincorrection)
                if strcmp(obj.modusOperandi,'Cal')
                    obj.gaincorrection = y;
                    obj.gaincorrection(stimpnts) = w.*standardstim;
                    notify(obj,'StimulusProblem',StimulusProblemData('CalibratingStimulus'));
                else
                    notify(obj,'StimulusProblem',StimulusProblemData('UncorrectedStimulus'))
                end
            end
        end
    end % protected methods
    
    methods (Static)
    end
end % classdef

% function displayTrial(obj)
%     figure(1);
%     ax1 = subplot(4,1,[1 2 3]);
%
%     redlines = findobj(1,'Color',[1, 0, 0]);
%     set(redlines,'color',[1 .8 .8]);
%     bluelines = findobj(1,'Color',[0, 0, 1]);
%     set(bluelines,'color',[.8 .8 1]);
%     line(obj.x,obj.y(:,1),'parent',ax1,'color',[1 0 0],'linewidth',1);
%     box off; set(gca,'TickDir','out');
%     switch obj.recmode
%         case 'VClamp'
%             ylabel('I (pA)'); %xlim([0 max(t)]);
%         case 'IClamp'
%             ylabel('V_m (mV)'); %xlim([0 max(t)]);
%     end
%     xlabel('Time (s)'); %xlim([0 max(t)]);
%
%     ax2 = subplot(4,1,4);
%     [~,commandstim] = obj.generateStimulus;
%     line(obj.x,commandstim,'parent',ax2,'color',[.7 .7 .7],'linewidth',1);
%     line(obj.x,obj.sensorMonitor,'parent',ax2,'color',[0 0 1],'linewidth',1);
%     box off; set(gca,'TickDir','out');
%
% end