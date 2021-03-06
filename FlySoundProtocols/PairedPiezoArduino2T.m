% Tell an arduino when at trial starts and when a triggered piezo should run
classdef PairedPiezoArduino2T < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'PairedPiezoArduino2T';
    end
    
    properties (SetAccess = protected)
        requiredRig = 'PiezoArduino2TRig';
        analyses = {};
    end
    
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
    end
    
    events
    end
    
    methods
        
        function obj = PairedPiezoArduino2T(varargin)
            obj = obj@FlySoundProtocol(varargin{:});
            p = inputParser;
            p.addParameter('modusOperandi','Run',...
                @(x) any(validatestring(x,{'Run','Stim','Cal'})));
            parse(p,varargin{:});
            
            if strcmp(p.Results.modusOperandi,'Cal')
                notify(obj,'StimulusProblem',StimulusProblemData('CalibratingStimulus'))
            end
        end
        
        function varargout = getStimulus(obj,varargin)            
            % Piezo
            y = obj.y*0;

            stimpnts = (1:round(obj.params.samprateout*obj.params.piezoDurInSec)) + round(obj.params.samprateout*(obj.params.preDurInSec-obj.params.piezoPreInSec));            
            y(stimpnts) = 1;
            obj.out.piezotrigger = y;

            % Arduino            
            obj.out.ttl = obj.y;
            varargout = {obj.out,obj.out.ttl,obj.y+y};
                    
        end
        
    end % methods
    
    methods (Access = protected)
        
        function defineParameters(obj)
            obj.params.sampratein = 50000;
            obj.params.samprateout = 50000;
            
            % Piezo
            obj.params.displacements = 3;
            obj.params.displacement = obj.params.displacements(1);
            obj.params.speeds = 500;
            obj.params.speed = obj.params.speeds(1);
            obj.params.displacementOffset = 0;

            % Timing of Arduino trial stimulus
            obj.params.stimDurInSec = 4;
            obj.params.preDurInSec = .5;
            obj.params.postDurInSec = .5;
            
            obj.params.piezoPreInSec = .3;
            obj.params.piezoDurInSec = .1;

            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;

            obj.params = obj.getDefaults;
                        
        end
        
        function setupStimulus(obj,varargin)
            setupStimulus@FlySoundProtocol(obj);
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.x = makeTime(obj);
            obj.y = zeros(size(obj.x));
            obj.y(round(obj.params.samprateout*(obj.params.preDurInSec)+1): round(obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec))) = 1;
            obj.out.ttl = obj.y;
                        
            if obj.params.preDurInSec<obj.params.piezoPreInSec
                error('Prelight stimulus period must include piezo period')
            end
            stimpnts = (1:round(obj.params.samprateout*obj.params.piezoDurInSec)) + round(obj.params.samprateout*(obj.params.preDurInSec-obj.params.piezoPreInSec));
            
            y = zeros(size(obj.x));
            y(stimpnts) = 1;
            obj.out.piezotrigger = y;

        end
        
    end % protected methods
    
    methods (Static)
    end
end % classdef
