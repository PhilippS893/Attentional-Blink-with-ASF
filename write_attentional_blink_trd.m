function [TRD_filename, Cfg] = write_attentional_blink_trd( Cfg, subject_id, run_id )
% this function creates a TRD-file used by the 'A Simple Framework'
% toolbox for an attentional blink experiment.

% if not exist, create a folder for the participant
if ~exist(subject_id,'dir'); mkdir(subject_id); end
% set the file name of the TRD
TRD_filename = sprintf('%s/%s_run%d.trd',subject_id,subject_id,run_id);

[trials, Cfg] = generate_trials( Cfg );

Cfg = write_file(TRD_filename, trials, Cfg);


function Cfg = write_file( filename, trials, Cfg )

[n_trials, n_stimuli] = size(trials.stimuli);

% permute the trials
this_permutation = randperm(n_trials,n_trials);
% we don't want the same trials back to back
while sum( diff(trials.codes(this_permutation))==0 ) > 0
    this_permutation = randperm(n_trials,n_trials);
end

% permutate the necessary variables
trials.stimuli = trials.stimuli(this_permutation, :);
trials.codes = trials.codes(this_permutation);
trials.onset = trials.onset(this_permutation);
Cfg.T1_idx  = Cfg.T1_idx(this_permutation);
Cfg.T2_idx  = Cfg.T2_idx(this_permutation);


% open the file and the the identifier
fID = fopen( filename, 'w' );

% the first line of an ASF TRD file is always the design info
fprintf( fID, '%s ', trials.design_info{1:end} ); fprintf( fID,'\n' );

% now loop over all trials and write the condition ID, trial onset, the
% pages with their duration, and the responses
for iTrial = 1:n_trials
    
    % first column always is the condition ID, second column the trial
    % onset
    fprintf( fID, '%d %d\t', trials.codes(iTrial), trials.onset(iTrial) );
    
    % we want to start with a fixation page first
    fprintf( fID, '%d %d\t', Cfg.stimuli.fixation, trials.fix_page_duration );
    
    % now write each page with its presentation duration (in frames)
    for iStimulus = 1:n_stimuli
        
        if Cfg.design.use_ISI && iTrial~=n_trials
            % a page always comes in a duplet (imagenumber presentation
            % duration)
            fprintf(fID, '%d %d\t%d %d\t', ...
                trials.stimuli(iTrial,iStimulus), trials.stim_page_duration,...
                Cfg.stimuli.blank, Cfg.design.timing.ISI_time);
        else
            fprintf(fID, '%d %d\t',trials.stimuli(iTrial,iStimulus), trials.stim_page_duration);
        end
    end
    
    % write the first response page
    if Cfg.design.use_ISI
        target_for_response = trials.stimuli(iTrial, Cfg.T2_idx(iTrial)/2);
    else
        target_for_response = trials.stimuli(iTrial, Cfg.T2_idx(iTrial));
    end
    fprintf( fID, '%d %d\t', target_for_response, trials.response_page_duration );
    
    % write the second and third response page
    fprintf( fID, '%d %d\t', Cfg.stimuli.blank, trials.response_page_duration );
    fprintf( fID, '%d %d\t', Cfg.stimuli.blank, trials.response_page_duration );
    
    % write the response tripled (startpage endpage correct_response)
    if Cfg.design.use_ISI
        fprintf( fID, '%d %d %d\n', n_stimuli*2+2, n_stimuli*2+4, 1);
    else
        fprintf( fID, '%d %d %d\n', n_stimuli+2, n_stimuli+4, 1);
    end
end

% close the file
fclose( fID );


function [trial, Cfg] = generate_trials( Cfg )

% determine the number of targets and the different categories of targets
[n_targets, n_categories] = size(Cfg.design.target_numbers);

% assign the condition codes to the respective category (each target within
% a category gets the same number)
condition1_codes = repmat(1:n_categories,n_targets,1);

% the codes for the two other experimental conditions are just 
% n_categories + 1 and n_categories + 2
trial.codes = ...
    [condition1_codes(:); ...
    (n_categories+1)*ones(Cfg.design.trials_per_condition(2),1);...
    (n_categories+2)*ones(Cfg.design.trials_per_condition(3),1)];


% second colum of an ASF TRD is the trial onset (here always 0)
trial.onset = zeros(Cfg.design.n_trials, 1);

% draw confounds for the experiment
confounds_in_trial = Cfg.design.pages.stim_per_trial-1;
confounds = randi( [Cfg.stimuli.confounds(1) Cfg.stimuli.confounds(end)], ...
    Cfg.design.n_trials, confounds_in_trial );

ctr = 0;
% check if the same confounds appear back-to-back or if the same 
while sum( any( diff( confounds,1,2 )==0 ) ) > 0
    
    idx_back2back = sum( diff( confounds,1,2 )==0, 2 )>0;
    n_back2back = sum(idx_back2back);
    filler_confounds = randi( [Cfg.stimuli.confounds(1) Cfg.stimuli.confounds(end)], ...
        n_back2back, confounds_in_trial );
    confounds(idx_back2back,:) = filler_confounds;
    ctr = ctr + 1;
end

fprintf(1,'Number of permutations tried: %d\n', ctr);

% set the times
trial.fix_page_duration      = Cfg.design.timing.fixation_time;
trial.stim_page_duration     = Cfg.design.timing.stimulus_time;
trial.response_page_duration = Cfg.design.timing.response_time;
trial.inter_stimulus_interval= Cfg.design.timing.ISI_time;

trial.design_info = {'3';'condition';'short';'long';'ctrl'};

uni_codes = unique( trial.codes );

% pre allocate some stuff
pre_t1 = cell( length(uni_codes),1 );
trial_counter = 0;
% generate trials for each code
for iCode = 1:length( uni_codes )
    
    % randomize the onset of T1 by drawing random numbers of the range
    % given by the user. No if statement necessary here since with randi we
    % draw the same number every time if imin and imax are equal.
    imin = Cfg.design.pages.pre_target1(1);
    imax = Cfg.design.pages.pre_target1(end);
    
    % the number of trials for a code can be different. Thus we need some
    % way to determine the correct number of trials. We can simply do this
    % by getting a binary vector of trial.codes for every code and sum up
    % the result.
    n_trials_for_code = sum( trial.codes == iCode );
    pre_t1{iCode} = randi( [imin imax], n_trials_for_code, 1 );
    
    % get the number trials for each code
    trials_for_code = sum( trial.codes == iCode );
    
    for iTrial = 1:trials_for_code
        
        trial_counter = trial_counter + 1;
        
        % get the pre-T1 confounds
        cfd_pre_T1 = confounds( trial_counter,1:pre_t1{iCode}(iTrial) );
        % get T1
        T1 = confounds( trial_counter, pre_t1{iCode}(iTrial)+1 );
        % save the index of T1 for each trial such that we know exactly
        % where it is.
        Cfg.T1_idx(trial_counter) = pre_t1{iCode}(iTrial)+1;
        % get the confounds between targets
        % this varies depending on the code. The last two codes are
        % different from the first ones, therefore we have to check for
        % these.
        % Furthermore, in the conditions the T2 differs and we'll make use
        % of the if statement here to assign the respective values
        if iCode == uni_codes(end-1)
            
            tmp = Cfg.T1_idx(trial_counter)+1:Cfg.T1_idx(trial_counter)+Cfg.design.pages.btwn_targets(2);
            % in this case we want a random target
            T2 = randi([Cfg.stimuli.targets(1) Cfg.stimuli.targets(end)],1,1 );

        elseif iCode == uni_codes(end)
            % this is the case for the control condition
            tmp = Cfg.T1_idx(trial_counter)+1:Cfg.T1_idx(trial_counter)+Cfg.design.pages.btwn_targets(3);
            % draw a random confound image.
            T2 = randi( [Cfg.stimuli.confounds(1) Cfg.stimuli.confounds(end)],1,1 );
            % draw until it does not match one that is in this trial
            while any(T2==confounds(trial_counter,:))
                T2 = randi( [Cfg.stimuli.confounds(1) Cfg.stimuli.confounds(end)],1,1 );
            end
        else
            % this is the case for the short lag trials
            tmp = Cfg.T1_idx(trial_counter)+1:Cfg.T1_idx(trial_counter)+Cfg.design.pages.btwn_targets(1);
            T2 = Cfg.design.target_numbers( iTrial, iCode );
        end
        cfd_btw_targets = confounds( trial_counter, tmp );
        Cfg.T2_idx(trial_counter) = tmp(end)+1;
        % get the confounds after T2
        cfd_post_T2 = confounds( iTrial, tmp(end)+1:end );
        
        % combine them into a single vector
        trial.stimuli(trial_counter,:) = [cfd_pre_T1, T1, cfd_btw_targets, T2, cfd_post_T2];
    end 
end

if Cfg.design.use_ISI 
    Cfg.T2_idx = Cfg.T2_idx.*2;
    Cfg.T1_idx = Cfg.T1_idx.*2;
end