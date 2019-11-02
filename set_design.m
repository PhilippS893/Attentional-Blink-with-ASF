function design = set_design
%

design = [];

%% MAKE YOUR CHANGES HERE
design.use_ISI                   = 1;    % set to 0 if you do not want an inter stimulus interval
design.use_step_fx               = 0;    % set to 1 if you want to use a step function

% This variable contains the number of trials for each experimental
% condition. E.g., 70 short lag (200ms between targets) trials, 10 long lag
% (e.g. > 500ms between targets) trials, and 10 control targets (i.e., no
% target 2 present). 
design.trials_per_condition      = [60, 10, 10];

%%%% TRIAL INFORMATION
% design.pages.stim_per_trial contains the number of STIMULI presented to a
% participant. Note that in case design.use_ISI = 1 the subsequent
% programs will have (design.pages.stim_per_trial*2)-1 presentations.
design.pages.stim_per_trial      = 18;        
% design.pages.pre_target1 contains the number of pages that can preceed
% the first target. Note that if you want to randomize the onset of T1 this
% variable has to be a vector containing the range of possible confounds
% before target1 
design.pages.pre_target1         = 6;         
% design.pages.btwn_targets contains the number of pages between the first
% and second target. This variable should be a vector of equal dimensions
% to design.trials_per_condition
design.pages.btwn_targets        = [2 7 2];    
% NOTE: the pages until the end are computed based on the information above. 

%%%% SET THE TIMING VARIABLES
% NOTE: page presentation is measured in frames 
% (1 frame = 16.6666ms)
design.timing.stimulus_time      = 6;         
design.timing.fixation_time      = 6;       
design.timing.response_time      = 30;       
design.timing.ISI_time           = 6;

% Provide search strings here that are part of the 'targets' stimuli in the
% './stimuli/targets/*' directory.
search_vals                      = {'AN_', 'FA_', 'FV_', 'IN_', '_P', '_T'};

%%%% STEP FUNCTION STUFF
% design.evaluation_after_trials contains the number of condition 1 trials
% after which performance evaluation is carried out.
design.evaluation_after_trials   = 100;
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