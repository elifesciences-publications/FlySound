classdef Speaker < Device
    
    properties (Constant)
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
        gaincorrection
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        function obj = Speaker(varargin)
            obj.deviceName = 'Speaker';
            obj.outputLabels = {'speakercommand'};
            obj.outputUnits = {'V'};
            obj.outputPorts = 3;
        end
        
        function in = transformInputs(obj,in)
            %multiply Inputs by micron/volts
        end
        
        function out = transformOutputs(obj,out)
            %multiply outputs by volts/micron
        end
    
    end
    
    methods (Access = protected)
        function setupDevice(obj)
        end
        
        function defineParameters(obj)
            obj.params.units = '';
        end
    end
end
