classdef CurrentSteps < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'CurrentSteps';
        requiredRig = 'BasicEPhysRig';
        analyses = {};
    end
    
    properties (Hidden)
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
    end
    
    events
    end
    
    methods
        
        function obj = CurrentSteps(varargin)
            % In case more construction is needed
            obj = obj@FlySoundProtocol(varargin{:});
        end
        
        function varargout = getStimulus(obj,varargin)
            nA = obj.params.step;
                        
            obj.out.current = obj.y * pA;
            varargout = {obj.out,calstim,commandstim};
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

            obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
            obj.x = makeTime(obj);
            obj.y = zeros(size(obj.x));
            obj.y(...
                obj.params.samprateout*(obj.params.preDurInSec)+1:...
                obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec)) = 1;
            obj.out.current = obj.y;
        end
        
        
    end % protected methods
    
    methods (Static)
    end
end % classdef