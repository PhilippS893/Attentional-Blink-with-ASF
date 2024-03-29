function design = set_design
%

design = [];

%% MAKE YOUR CHANGES HERE
design.use_ISI                   = 0;    % set to 1 if you an inter stimulus interval
design.use_step_fx               = 0;    % set to 1 if you want to use a step function
design.use_feedback_color        = 1;    % set to 1 if you want to indicate in-/correct responses with a colour

% This variable contains the number of trials for each experimental
% condition. E.g., 60 short lag (200ms between targets) trials, 18 long lag
% (e.g. > 500ms between targets) trials, and 18 control targets (i.e., no
% target 2 present). 
design.trials_per_condition      = [60,18,18];

%%%% TRIAL INFORMATION
% design.pages.stim_per_trial contains the number of STIMULI presented to a
% participant. Note that in case design.use_ISI = 1 the subsequent
% programs will have (design.pages.stim_per_trial*2)-1 presentations.
design.pages.stim_per_trial      = 22;        
% design.pages.pre_target1 contains the number of pages that can preceed
% the first target. Note that if you want to randomize the onset of T1 this
% variable has to be a vector containing the range of possible confounds
% before target1 
design.pages.pre_target1         = [6:9];         
% design.pages.btwn_targets contains the number of pages between the first
% and second target. This variable should be a vector of equal dimensions
% to design.trials_per_condition
design.pages.btwn_targets        = [2 8 2];    
% NOTE: the pages until the end are computed based on the information above. 

%%% SET VARIABLES FOR STUFF SUPERIMPOSED ON CONFOUNDS
% design.confound_overlay can either be 'none, 'all', 'odd', or 'even'
% This determines whether arrows are shown on all, odd, or even confounds.
% NOTE: By choosing a continuous range for design.pages.pre_target1 = 4:6,
% for example, it can be that arrows appear on confound->T2->confound no
% matter if you choose 'even' or 'odd'. If you want them only to appear on
% even or odd stimuli you have to choose the range of possibile T1 slots
% accordingly.
% Example-1: always on odd stimuli
%   design.pages.pre_target1 = [4 6 8]; 
%   design.confound_overlay = 'odd';
% Example-2; always on even stimuli
%   design.pages.pre_target1 = [5 7 9];
%   design.confound_overlay = 'even';
% remember that T1 is the stimulus AFTER those in design.pages.pre_target1!
design.confound_overlay = 'none';

%%%% SET THE TIMING VARIABLES
% NOTE: page presentation is measured in frames 
% (1 frame = 16.6666ms)
design.timing.stimulus_time      = 6;         
design.timing.fixation_time      = 90;       
design.timing.response_time      = 300;
design.timing.feedback_time      = 18;
design.timing.ISI_time           = 1;

% Provide search strings here that are part of the 'targets' stimuli in the
% './stimuli/targets/*' directory.
search_vals                      = {'AN_', 'FA_', 'FV_', 'IN_', '_P', '_T'};

%%%% STEP FUNCTION STUFF
% design.evaluation_after_trials contains the number of condition 1 trials
% after which performance evaluation is carried out.
design.evaluation_after_trials   = 101;
% design.adjust_down contains a value representing the number of frames to
% down regulate the presentation time of each stimulus (i.e., make it shorter)
design.adjust_down               = 1;
% design.adjust_up contains a value representing the number of frames to
% up regulate the presentation time of each stimulus (i.e., make it longer)
design.adjust_up                 = 1;

%% DO NOT DO CHANGES HERE
design.n_trials                  = sum( design.trials_per_condition );

design.target_numbers            = get_target_matrix( search_vals );
design.condition1_codes          = size( design.target_numbers, 1 );


function targets = get_target_matrix(search_vals)

% load the .std file
std_data = importdata('stimuli.std');

for iSV = 1:length(search_vals)
    theseIdx = find( contains( std_data, search_vals{iSV} ) );
    targets(:,iSV) = theseIdx;
end