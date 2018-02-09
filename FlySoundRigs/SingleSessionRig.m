classdef SingleSessionRig < Rig
    % current hierarchy: 7/14/16
    %   Rig -> EPhysRig -> BasicEPhysRig
    %                   -> TwoTrodeRig
    %                   -> PiezoRig 
    %                   -> TwoPhotonRig -> TwoPhotonEPhysRig 
    %                                   -> TwoPhotonPiezoRig     
    %                   -> CameraRig    -> CameraEPhysRig 
    %                                   -> PiezoCameraRig 
    %                   -> PGRCameraRig -> PGREPhysRig
    %                                   -> PGRPiezoRig % This setup is for
    %                                   a digital output that requires same
    %                                   session, and same input and output
    %                                   sample rates
    %       -> SingleSession -> BasicEPhysRigSS
    
    properties (Constant,Abstract)
        rigName;
        IsContinuous;
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        function obj = SingleSessionRig(varargin)
            % setacqpref('AcquisitionHardware','Amplifier','MultiClamp700B') %
            % setacqpref('AcquisitionHardware','Amplifier','AxoPatch200B_2P') %
            % AxoPatch200B % AxoClamp2B % MultiClamp700B % AxoPatch200B_2P

            obj.aiSession = obj.aoSession;

            ampDevices = {'MultiClamp700A','MultiClamp700AAux'};
            p = inputParser;
            p.PartialMatching = 0;
            p.addParameter('amplifier1Device','MultiClamp700A',@ischar);            
            parse(p,varargin{:});
            
            acqhardware = getacqpref('AcquisitionHardware');
            if isfield(acqhardware,'Amplifier') ...
                    && ~strcmp(acqhardware.Amplifier,'MultiClamp700B')...
                    && ~strcmp(acqhardware.Amplifier,'AxoPatch200B_2P');
                obj.addDevice('amplifier',acqhardware.Amplifier);
            elseif ~isfield(acqhardware,'Amplifier')
                ampDevices = {'MultiClamp700A','MultiClamp700AAux'};
                obj.addDevice('amplifier',ampDevices{strcmp(ampDevices,p.Results.amplifier1Device)});
            elseif strcmp(acqhardware.Amplifier,'AxoPatch200B_2P')
                obj.addDevice('amplifier',acqhardware.Amplifier,'Session',obj.aiSession);
            elseif strcmp(acqhardware.Amplifier,'MultiClamp700B')
                obj.addDevice('amplifier',ampDevices{strcmp(ampDevices,p.Results.amplifier1Device)});
            end
            addlistener(obj.devices.amplifier,'ModeChange',@obj.changeSessionsFromMode);
        end
        
        function in = run(obj,protocol,varargin)
            obj.devices.amplifier.getmode;
            obj.devices.amplifier.getgain;
            in = run@Rig(obj,protocol,varargin{:});
        end
    end
    
    methods (Access = protected)
        function changeSessionsFromMode(obj,amplifier,evnt)
            for i = 1:length(amplifier.outputPorts)
                % configure AO
                for c = 1:length(obj.aoSession.Channels)
                    if strcmp(obj.aoSession.Channels(c).ID,['ao' num2str(amplifier.outputPorts(i))])
                        ch = obj.aoSession.Channels(c);
                        break
                    end
                end
                ch.Name = amplifier.outputLabels{i};
                obj.outputs.portlabels{amplifier.outputPorts(i)+1} = amplifier.outputLabels{i};
                obj.outputs.device{amplifier.outputPorts(i)+1} = amplifier;
                % use the current vals to apply to outputs
            end
            % obj.outputs.labels = obj.outputs.portlabels(strncmp(obj.outputs.portlabels,'',0));
            obj.outputs.datavalues = zeros(size(obj.aoSession.Channels));
            obj.outputs.datacolumns = obj.outputs.datavalues;
            
            for i = 1:length(amplifier.inputPorts)
                for c = 1:length(obj.aoSession.Channels)
                    if strcmp(obj.aoSession.Channels(c).ID,['ai' num2str(amplifier.inputPorts(i))])
                        ch = obj.aoSession.Channels(c);
                        break
                    end
                end
                ch.Name = amplifier.inputLabels{i};
                obj.inputs.portlabels{amplifier.inputPorts(i)+1} = amplifier.inputLabels{i};
                obj.inputs.device{amplifier.inputPorts(i)+1} = amplifier;
                obj.inputs.data.(amplifier.inputLabels{i}) = [];
            end
        end
        
        function defineParameters(obj)
            obj.params.sampratein = 50000;
            fprintf('SingleSession Rigs must have identical input and output sampling rates');
            obj.params.samprateout = obj.params.sampratein;
            obj.params.testcurrentstepamp = -5;
            obj.params.testvoltagestepamp = -2.5;
            obj.params.teststep_start = 0.010;
            obj.params.teststep_dur = 0.050;
            obj.params.interTrialInterval = 0;
            
        end

        function setSessions(obj,varargin)
            % Establish all the output channels and input channels in one
            % place
            rigDev = getacqpref('AcquisitionHardware','rigDev');
            
            if nargin>1
                keys = varargin;
            else
                keys = fieldnames(obj.devices);
            end
            for k = 1:length(keys);
                dev = obj.devices.(keys{k});
                for i = 1:length(dev.outputPorts)
                    % configure AO
                    ch = obj.aoSession.addAnalogOutputChannel(rigDev,dev.outputPorts(i), 'Voltage');
                    ch.Name = dev.outputLabels{i};
                    obj.outputs.portlabels{dev.outputPorts(i)+1} = dev.outputLabels{i};
                    obj.outputs.device{dev.outputPorts(i)+1} = dev;
                    % use the current vals to apply to outputs
                end
                % obj.outputs.labels = obj.outputs.portlabels(strncmp(obj.outputs.portlabels,'',0));
                
                for i = 1:length(dev.digitalOutputPorts)
                    ch = obj.aoSession.addDigitalChannel(rigDev,['Port0/Line' num2str(dev.digitalOutputPorts(i))], 'OutputOnly');
                    ch.Name = dev.digitalOutputLabels{i};
                    obj.outputs.digitalPortlabels{dev.digitalOutputPorts(i)+1} = dev.digitalOutputLabels{i};
                    obj.outputs.device{dev.digitalOutputPorts(i)+getacqpref('AcquisitionHardware','AnalogOutN')+1} = dev;
                end
                obj.outputs.datavalues = zeros(size(obj.aoSession.Channels));
                obj.outputs.datacolumns = obj.outputs.datavalues;
                
                for i = 1:length(dev.inputPorts)
                    ch = obj.aoSession.addAnalogInputChannel(rigDev,dev.inputPorts(i), 'Voltage');
                    ch.InputType = 'SingleEnded';
                    ch.Name = dev.inputLabels{i};
                    obj.inputs.portlabels{dev.inputPorts(i)+1} = dev.inputLabels{i};
                    obj.inputs.device{dev.inputPorts(i)+1} = dev;
                    % obj.inputs.data.(dev.inputLabels{i}) = [];
                end
            
                for i = 1:length(dev.digitalInputPorts)
                    ch = obj.aoSession.addDigitalChannel(rigDev,['Port0/Line' num2str(dev.digitalInputPorts(i))], 'InputOnly');
                    ch.Name = dev.digitalInputLabels{i};
                    obj.inputs.digitalPortlabels{dev.digitalInputPorts(i)+1} = dev.digitalInputLabels{i};
                    obj.inputs.device{dev.digitalInputPorts(i)+getacqpref('AcquisitionHardware','AnalogInN')+1} = dev;
                    % obj.inputs.data.(dev.inputLabels{i}) = [];
                end
                
            end
        end

        function chNames = getChannelNames(obj)
            for ch = 1:length(obj.aoSession.Channels)
                chNames.out{ch} = obj.aoSession.Channels(ch).Name;
            end
            for ch = 1:length(obj.aiSession.Channels)
                chNames.in{ch} = obj.aiSession.Channels(ch).Name;
            end
        end
        
    end
end
