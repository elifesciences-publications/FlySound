setpref('AcquisitionHardware','cameraToggle','off')

% Start the bitch 
% clear all, close all

clear A, 
A = Acquisition;

%% Sweep - record the break-in

A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',10);
A.tag('break-in')
A.run(1)
A.clearTags

%% Seal
A.setProtocol('SealAndLeak');
A.tag('R_input')
A.run
A.untag('R_input')

% 19951 - 16068


%% Sweep
setpref('AcquisitionHardware','cameraToggle','off')
A.rig.applyDefaults;

A.setProtocol('Sweep2T');
A.protocol.setParams('-q','durSweep',5);
A.run(1)


%% Switch to current clamp

%% Sweep
A.rig.setParams('testcurrentstepamp',0)
A.rig.applyDefaults;
A.setProtocol('Sweep');
A.protocol.setParams('-q','durSweep',5);
A.run(4)


%% Sweep2T
A.rig.setParams('testcurrentstepamp',0)
A.rig.applyDefaults;
A.setProtocol('Sweep2T');
A.protocol.setParams('-q','durSweep',5);
A.run(3)


%% Current Step 
setpref('AcquisitionHardware','cameraToggle','off')
A.rig.applyDefaults;

A.setProtocol('CurrentStep2T');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',1,...
    'stimDurInSec',0.5,...
    'steps', 300* [ -.25 .25 .5 .75 1],... % [3 10]
    'postDurInSec',1);
A.run(2)

%% Current Step -> Movement?
setpref('AcquisitionHardware','cameraToggle','on')
A.rig.applyDefaults;

A.setProtocol('CurrentStep2T');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',1,...
    'stimDurInSec',0.5,...
    'steps', 100* [.15 .25 .5 1],... % [3 10]
    'postDurInSec',1);
A.run(5)


%% EpiFlash2T
setpref('AcquisitionHardware','cameraToggle','off')
A.rig.applyDefaults;

A.setProtocol('EpiFlash2T');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.2,...
    'displacements',[7],...
    'stimDurInSec',.5,...
    'postDurInSec',.2);
% A.tag
A.run(2)
% A.clearTags

%% EpiFlash
setpref('AcquisitionHardware','cameraToggle','on')
A.rig.applyDefaults;

A.setProtocol('EpiFlash');
A.rig.setParams('testcurrentstepamp',0); %A.rig.applyDefaults;
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',1,...
    'displacements',[10],...
    'stimDurInSec',8,...
    'postDurInSec',1);
% A.tag
A.run(6)
% A.clearTags


%% Current Step 
setpref('AcquisitionHardware','cameraToggle','off')
A.rig.applyDefaults;

A.setProtocol('CurrentStep2T');
A.rig.setParams('interTrialInterval',0);
A.protocol.setParams('-q',...
    'preDurInSec',.12,...
    'stimDurInSec',.1,...
    'steps',[100],... % [3 10]
    'postDurInSec',.1);
A.run(4)