classdef AxoPatch200B < Device
    
    properties (Constant)
        
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
    end

    properties (Hidden, SetAccess = protected)
        modeSession
        gainSession
    end

    
    events
        BadMode
    end
    
    methods
        function obj = AxoPatch200B(varargin)
            obj = obj@Device(varargin{:});
            obj.deviceName = 'AxoPatch200B';
            
            % This and the transformInputs function are hard coded
            % Currently using the AxoPatch as the extensor EMG, no need for
            % outputs
            obj.inputLabels = {'scaled','current','voltage'};
            obj.inputUnits = {'mV','pA','mV'};
            obj.inputPorts = [0,3,4];
            %             obj.outputLabels = {'scaled'};
            %             obj.outputUnits = {'pA'};
            %             obj.outputPorts = 0;

            obj.setModeSession;
            obj.mode = 'VClamp';
            obj.getmode;
            obj.setGainSession;
            obj.getgain;
            obj.gain = 1;
        end
        
        function varargout = transformOutputs(obj,out)
            outlabels = fieldnames(out);
            for ol = 1:length(outlabels)
                if strcmp(outlabels{ol},'voltage')
                    if sum(strcmp({'IClamp','IClamp_fast'},obj.mode))
                        %warning('In Current Clamp - removing current stim')
                        out = rmfield(out,'voltage');
                    else
                        obj.outputLabels{1} = 'voltage';
                        obj.outputUnits{1} = 'mV';
                        out.voltage = out.voltage/1000;  % mV, convert, this is the desired V injected
                        out.voltage = (out.voltage - obj.params.daqout_to_voltage_offset)/obj.params.daqout_to_voltage;
                        units.voltage = 'mV';
                    end
                end
                if strcmp(outlabels{ol},'current')
                    if sum(strcmp('VClamp',obj.mode))
                        %warning('In Voltage Clamp - removing current stim')
                        out = rmfield(out,'current');
                    else
                        obj.outputLabels{1} = 'current';
                        obj.outputUnits{1} = 'pA';
                        out.current = (out.current - obj.params.daqout_to_current_offset)/obj.params.daqout_to_current;
                        DAQ_V_to_subtract_static_current = obj.params.daqCurrentOffset/obj.params.daqout_to_current;
                        out.current = out.current - DAQ_V_to_subtract_static_current;
                        units.current = 'pA';
                    end
                end
            end
            if isempty(fieldnames(out))
                notify(obj,'BadMode');
                error('Amplifier in %s mode - No appropriate output',obj.mode);
            end
            varargout = {out};
        end
        
        function varargout = transformInputs(obj,inputstruct)
            inlabels = fieldnames(inputstruct);
            units = {};
            for il = 1:length(inlabels)
                switch inlabels{il}
                    case 'voltage'
                        if sum(strcmp({'IClamp','IClamp_fast'},obj.mode))
                            obj.inputLabels{1} = 'voltage';
                            obj.inputUnits{1} = 'mV';
                            inputstruct.voltage = (inputstruct.(inlabels{il})-obj.params.scaledvoltageoffset)*obj.params.scaledvoltagescale_timesgain/obj.gain;
                        else
                            inputstruct.voltage = (inputstruct.(inlabels{il})-obj.params.hardvoltageoffset)*obj.params.hardvoltagescale * 1000;
                        end
                        units{il} = 'mV'; 
                    case 'current'
                        if sum(strcmp('VClamp',obj.mode))
                            obj.inputLabels{1} = 'current';
                            obj.inputUnits{1} = 'pA';
                            inputstruct.current = (inputstruct.(inlabels{il})-obj.params.scaledcurrentoffset)*obj.params.scaledcurrentscale_timesgain/obj.gain;
                        else
                            inputstruct.(inlabels{il}) = (inputstruct.(inlabels{il})-obj.params.hardcurrentoffset)*obj.params.hardcurrentscale * 1000;
                        end
                        units{il} = 'pA';
                end
            end
            varargout = {inputstruct,units};
        end
        
        function setModeSession(obj)
            modeDev = getacqpref('AcquisitionHardware','modeDev');
            obj.modeSession = daq.createSession('ni');
            obj.modeSession.addAnalogInputChannel(modeDev,2, 'Voltage');
            obj.modeSession.Channels(1).TerminalConfig = 'SingleEndedNonReferenced';
            obj.modeSession.Rate = 10000;  % 10 kHz
            obj.modeSession.DurationInSeconds = .01; % 2ms
        end
        
        function setGainSession(obj)
            gainDev = getacqpref('AcquisitionHardware','gainDev');
            obj.gainSession = daq.createSession('ni');
            obj.gainSession.addAnalogInputChannel(gainDev,1, 'Voltage');
            obj.modeSession.Channels(1).TerminalConfig = 'SingleEnded';
            obj.gainSession.Rate = 10000;  % 10 kHz
            obj.gainSession.DurationInSeconds = .02; % 2ms
        end
        
        function newmode = getmode(obj)
            % [voltage,current] = readGain(recMode, durSweep, samprate)
            mode_voltage = obj.modeSession.startForeground; %plot(x); drawnow
            mode_voltage = mean(mode_voltage);
            
            if mode_voltage < 1.75
                newmode = 'IClamp_fast';
            elseif mode_voltage < 2.75
                newmode = 'IClamp';
            elseif mode_voltage < 3.75
                newmode = 'I=0';
            elseif mode_voltage < 4.75
                newmode = 'Track';
            elseif mode_voltage < 6.75
                newmode = 'VClamp';
            end
            obj.mode = newmode;
            
            if sum(strcmp('VClamp',obj.mode))
%                     obj.outputLabels{1} = 'voltage';
%                     obj.outputUnits{1} = 'mV';
                    obj.inputLabels{1} = 'current';
                    obj.inputUnits{1} = 'pA';
            elseif sum(strcmp({'IClamp','IClamp_fast'},obj.mode)) 
%                     obj.outputLabels{1} = 'current';
%                     obj.outputUnits{1} = 'pA';
                    obj.inputLabels{1} = 'voltage';
                    obj.inputUnits{1} = 'mV';
            end
            notify(obj,'ModeChange');
        end
        function newgain = getgain(obj)
            % [voltage,current] = readGain(recMode, durSweep, samprate)
            
            gain_voltage = obj.gainSession.startForeground; %plot(x); drawnow
            gain_voltage = mean(gain_voltage);
            
            if gain_voltage < 2.2
                newgain = 0.5;
            elseif gain_voltage < 2.7
                newgain = 1;
            elseif gain_voltage < 3.2
                newgain = 2;
            elseif gain_voltage < 3.7
                newgain = 5;
            elseif gain_voltage < 4.2
                newgain = 10;
            elseif gain_voltage < 4.7
                newgain = 20;
            elseif gain_voltage < 5.2
                newgain = 50;
            elseif gain_voltage < 5.7
                newgain = 100;
            elseif gain_voltage < 6.2
                newgain = 200;
            elseif gain_voltage < 6.7
                newgain = 500;
            end
            obj.gain = newgain;
        end
                
    end
    
    methods (Access = protected)
                
        function defineParameters(obj)
            % create an amplifier class that implements these
            obj.params.filter = 1e4;
            obj.params.headstagegain = 1;
            
            obj.params.daqCurrentOffset = 0.0000; 
            obj.params.daqout_to_current = 2/obj.params.headstagegain; % m, multiply DAQ voltage to get nA injected
            obj.params.daqout_to_current_offset = 0;  % b, add to DAQ voltage to get the right offset
            
            obj.params.daqout_to_voltage = .02; % m, multiply DAQ voltage to get mV injected (combines voltage divider and input factor) ie 1 V should give 2mV
            obj.params.daqout_to_voltage_offset = 0;  % b, add to DAQ voltage to get the right offset
            
            obj.params.rearcurrentswitchval = 1; % [V/nA];
            obj.params.hardcurrentscale = 1/(obj.params.rearcurrentswitchval*obj.params.headstagegain); % [V]/current scal gives nA;
            obj.params.hardcurrentoffset = -6.6238/1000;
            obj.params.hardvoltagescale = 1/(10); % reads 10X Vm, mult by 1/10 to get actual reading in V, multiply in code to get mV
            obj.params.hardvoltageoffset = -6.2589/1000; % in V, reads 10X Vm, mult by 1/10 to get actual reading in V, multiply in code to get mV
            
            obj.params.scaledcurrentscale_timesgain = 1000/(obj.params.headstagegain); % [mV/V]/gainsetting gives pA
            obj.params.scaledcurrentoffset = 0; % [mV/V]/gainsetting gives pA
            obj.params.scaledvoltagescale_timesgain = 1000; % mV/gainsetting gives mV
            obj.params.scaledvoltageoffset = 0; % mV/gainsetting gives mV
        end
    end
end
