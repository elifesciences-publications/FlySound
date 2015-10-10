% Change the voltage command in steps, control steps, stimDurInSec
classdef VoltageStep < FlySoundProtocol

    properties (Constant)
        protocolName = 'VoltageStep';
    end
    
    properties (SetAccess = protected)
        requiredRig = 'BasicEPhysRig';  %CameraEPhysRig BasicEPhysRig
        analyses = {}; %'average', 'dFoverF'
    end

    
    properties (Hidden)
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
    end
    
    events
    end
    
    methods
        
        function obj = VoltageStep(varargin)
            % In case more construction is needed
            obj = obj@FlySoundProtocol(varargin{:});
            if strcmp('off', getpref('AcquisitionHardware','cameraToggle'));
                obj.analyses = obj.analyses(~strcmp(obj.analyses,'dFoverF'));
            end
        end
        
        function varargout = getStimulus(obj,varargin)
            obj.out.voltage = obj.y * obj.params.step;
            varargout = {obj.out};
        end
                        
    end % methods
    
    methods (Access = protected)
                                
        function defineParameters(obj)
            obj.params.sampratein = 50000;
            obj.params.samprateout = 50000;
            obj.params.Vm_id = 0;
            
            obj.params.steps = [-30 -20 -10 0 10 20 30];
            obj.params.step = obj.params.steps(1);
            
            obj.params.stimDurInSec = 0.2;
            obj.params.preDurInSec = .5;
            obj.params.postDurInSec = .5;
            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.params = obj.getDefaults;

        end
        
        function setupStimulus(obj,varargin)
            setupStimulus@FlySoundProtocol(obj);
            obj.params.step = obj.params.steps(1);

            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.x = makeTime(obj);
            obj.y = zeros(size(obj.x));
            obj.y(...
                round(obj.params.samprateout*(obj.params.preDurInSec))+1:...
                round(obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec))) = 1;
            obj.out.voltage = obj.y;
        end
        
        
    end % protected methods
    
    methods (Static)
    end
end % classdef