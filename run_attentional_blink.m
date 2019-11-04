function ExpInfo = run_attentional_blink( subject_id, howManyRuns )
% this function executes an attentional blink experiment
% IMPORTANT: Before executing this script make sure you adapted the
% "set_design.m" function according to your needs. Then change the
% configuration parameters below (if necessary).
%
% RUN EXPERIMENTS:
%
% 20191009
% ExpInfo = run_attentional_blink( 'philipp', 1 );
%
% 20191011
% ExpInfo = run_attentional_blink( 'fredrik', 1 );

%% DO SOME ERROR CHECKS
error_check();

%% SET ASF CONFIGS
Cfg = [];
Cfg.design = set_design;
Cfg.design.overlay = get_overlay_vector(Cfg);
Cfg.stimuli = get_indices_from_std();
Cfg.responseSettings.multiResponse = 'allowSingleResponse';
Cfg.userSuppliedTrialFunction = @attentional_blink_presentation;
Cfg.Screen.rect = [1,1,860,590];
Cfg.Screen.color = [86,86,86];
% Cfg.responseDevice = 'CEDRUSSERIAL';
% Cfg.serialPortName = '/dev/ttyUSB0';
% Cfg.responseType = 'buttonDownCedrus';
Cfg.responseDevice = 'KEYBOARD';
Cfg.responseType = 'buttonDown';
Cfg.enabledKeys = 11:13;

%%% CHANGE SOMETHING HERE IF YOU WANT TO CHANGE FONT SIZE OR TEXT COLOURS
Cfg.txture.standard_font_size      = 50;
Cfg.txture.instruction_font_size   = 50;
Cfg.txture.T1_font_size            = 80;
Cfg.txture.target_color            = [255 0 0];
Cfg.txture.confound_color          = [255 255 255];

%% RUN THE EXPERIMENT
for iRun = 1:howManyRuns
    % GENERATE NEW TARGET 1 ARROW VECTOR
    [Cfg.arrow_for_T1, Cfg.t1_correct_response] = generate_arrow_vector(Cfg.design.n_trials, 5);
    
    
    % WRITE THE TRD FILE FOR A GIVEN SUBJECT
    [TRD_filename, Cfg] = write_attentional_blink_trd( Cfg, subject_id, iRun );
    
    % RUN THE EXPERIMENT
    output_name = fullfile(subject_id,sprintf('%s_run%d',subject_id,iRun));
    ExpInfo = ASF('stimuli.std', TRD_filename, output_name, Cfg);
    
    % setup the next run with stimulus duration from the last run.
    AB.timing.stimulus_time = ExpInfo.TrialInfo(end).trial.pageDuration(2);
    Cfg.design = AB;
    clear attentional_blink_presentation;
    fprintf(1,'\nPress any key to continue...');
    pause
end


%% HELPER FUNCTIONS
function create_std_file()
% creates an .std file used for ASF

% first line is always the blank. Making use of system is an easy way to
% quickly create or append lines from the console to a file.
% Here, we need to write ./stimuli/<target/confounds>/*.* to the file
% 'stimuli.std'. One can make use of the ls -1 command for this.

warning('"stimuli.std not found! Creating a default...\n');

% By default, we use the first line for the blank images
system('ls -1 ./stimuli/blank.* > stimuli.std');

% By default, we use the second line for the fixation cross
system('ls -1 ./stimuli/fixation.* >> stimuli.std');

% Now, append the confound images
system('ls -1 ./stimuli/confounds/*.* >> stimuli.std');

% Lastly, append the target images
system('ls -1 ./stimuli/targets/*.* >> stimuli.std');


function indices = get_indices_from_std()
% this function returns the indices of the important stimuli conditions

fprintf(1, 'Getting the stimuli indices from stimuli.std...\n');

% load the content of stimuli.std file
content = importdata('stimuli.std');

indices.blank       = find( contains( content, 'blank' ) );
indices.fixation    = find( contains( content, 'fixation' ) );
indices.confounds   = find( contains( content, 'confounds' ) );
indices.targets     = find( contains( content, 'targets' ) );

function error_check()
% This function checks whether a 
% a. stimulus directory
% b. stimulus file
% exists. If the stimulus directory does not exists, throw an error and
% tell the user that a stimulus folder is necessary.

% CLEAR THE EXISTING PERSISTANT VARIABLES
clear attentional_blink_presentation;

if ~exist('stimuli','dir')
    error('Required stimuli folder not found!\nPlease create a "stimuli" folder with a "confounds" and "targets" folder!\nA "blank" and "fixation" image should exist in the "stimuli" directory!\n');
end

% check if a stimulus file exists. If not, create one
if ~exist('stimuli.std','file')
    create_std_file();
end

function overlay = get_overlay_vector(Cfg)

if Cfg.design.use_ISI
    stim_per_trial = 2*Cfg.design.pages.stim_per_trial-1;
else
    stim_per_trial = Cfg.design.pages.stim_per_trial;
end

% the number of pages is equal to 1 blank + stim_per_trial + 3 response
% pages
nPages = 1 + stim_per_trial + 3;

overlay = zeros(nPages,1);
% set a logical vector for the arrows on the confound images
switch Cfg.design.confound_overlay
    case 'none'
        % do nothing
    case 'all'
        if Cfg.design.use_ISI
            overlay(2:2:end-3) = 1;
        else
            overlay(2:end-3) = 1;
        end
    case 'odd'
        if Cfg.design.use_ISI
            overlay(2:4:end-3) = 1;
        else
            overlay(2:2:end-3) = 1;
        end
    case 'even'
        if Cfg.design.use_ISI
            overlay(4:4:end-3) = 1;
        else
            overlay(3:2:end-3) = 1;
        end
    otherwise
        error('wrong option for design.confound_overlay');
end

function [arrows, correct_response] = generate_arrow_vector(n_trials,n_arrows)

% generate zeros and ones (0 = <; 1 = >)
arrow_direction = randi([0;1],n_trials,n_arrows);
while any( sum( arrow_direction, 2 ) ==0 ) || any( sum( arrow_direction, 2 ) == n_arrows )
    arrow_direction = randi([0;1],n_trials,n_arrows);
end
arrows = zeros(n_trials,n_arrows);
arrows(arrow_direction==0) = 60;
arrows(arrow_direction==1) = 62;

correct_response = sum(arrow_direction,2)>=3;