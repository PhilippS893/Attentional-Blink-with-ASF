function TrialInfo = attentional_blink_presentation(atrial, windowPtr, Stimuli, Cfg)
%function TrialInfo = ASF_ShowTrialMultiResponse(atrial, windowPtr, Stimuli, Cfg)
%SHOWTRIAL VERSION THAT ALLOWS MULTIPLE RESPONSES WHILE BEING BETWEEN PAGES
%atrial.startRTonPage:atrial.endRTonPage

if ~isfield(Cfg.responseSettings, 'multiResponse'), Cfg.responseSettings.multiResponse = 'allowSingleResponse'; else end;
if ~isfield(Cfg, 'feedbackResponseNumber'), Cfg.feedbackResponseNumber = 1; else end; %IF YOU WANT TO GIVE FEEDBACK REFER BY DEFAULT TO THE FIRST RESPONSE GIVEN IN THIS TRIAL
%SAVE TIME BY ALLOCATING ALL VARIABLES UPFRONT

% VBLTimestamp system time (in seconds) when the actual flip has happened
% StimulusOnsetTime An estimate of Stimulus-onset time
% FlipTimestamp is a timestamp taken at the end of Flip's execution
VBLTimestamp = 0; StimulusOnsetTime = 0; FlipTimestamp = 0; Missed = 0;
Beampos = 0;

StartRTMeasurement = 0; EndRTMeasurement = 0;
timing = [0, VBLTimestamp, StimulusOnsetTime, FlipTimestamp, Missed, Beampos];
nPages = length(atrial.pageNumber);
timing(nPages, end) = 0;
this_response = [];

%ON PAGES WITH WITH RESPONSE COLLECTION MAKE SURE THE CODE RETURNS IN TIME
%BEFORE THE NEXT VERTICAL BLANK. FOR EXAMPLE IF THE RESPONSE WINDOW IS 1000
%ms TOLERANCE MAKES THE RESPONSE COLLECTION CODE RETURN AFTER 1000ms-0.3
%FRAMES, I.E. AFTER 995 ms AT 60Hz
toleranceSec = Cfg.Screen.monitorFlipInterval*0.2; %was .3

%HOWEVER, THIS MUST NOT BE LONGER THAN ONE FRAME
%DURATION. EXPERIMENTING WITH ONE QUARTER OF A FRAME
responseGiven = 0;
this_response.key = [];   
this_response.RT = [];


%--------------------------------------------------------------------------
%TRIAL PRESENTATION HAS SEVERAL PHASES
% 1) WAIT FOR THE RIGHT TIME TO START TRIAL PRESENTATION. THIS MAY BE
%    IMMEDIATELY OR USER DEFINED (E.G. IN fMRI EXPERIMENTS)
%
% 2) LOOP THROUGH PAGE PRESENTATIONS WITHOUT RESPONSE COLLECTION
%
% 3) LOOP THROUGH PAGE PRESENTATIONS WHILE CHECKING FOR USER INPUT/RESPONSES
%
% 4) LOOP THROUGH PAGE PRESENTATIONS WITHOUT RESPONSE COLLECTION
%    (AFTER RESPONSE HAS BEEN GIVEN)
%
% 5) FEEDBACK
%--------------------------------------------------------------------------

%IF YOU WANT TO DO ANY OFFLINE STIMULUS RENDERING (I.E. BEFORE THE TRIAL
%STARTS), PUT THAT CODE HERE

%%%%%%%% PS CODE %%%%%%%%
% Implementation of a step function according to subject performance
persistent adjustment;
% initialize the persistent variable
if isempty(adjustment)
    adjustment.trial_ctr = 1;
    % proportion of condition 1 trials
    %prop = Cfg.design.n_trials*Cfg.design.condition_proportions(1);
    prop = 70;
    adjustment.correct_rsp = zeros(prop, 2);
    adjustment.this_duration = Cfg.design.timing.stimulus_time;
    adjustment.page_idcs = 2:Cfg.design.pages.stim_per_trial+1;
end

% only change the page duration if it actually varies from the standard
% time
if adjustment.this_duration ~= Cfg.design.timing.stimulus_time
    atrial.pageDuration(adjustment.page_idcs) = adjustment.this_duration;
end

standard_font_size      = Cfg.txture.standard_font_size;
instruction_font_size   = Cfg.txture.instruction_font_size;
T1_font_size            = Cfg.txture.T1_font_size;
target_color            = Cfg.txture.target_color;
confound_color          = Cfg.txture.confound_color;

atrial.nPages = length(atrial.pageNumber); % how many pages in this trial
responseCounter = 0; % counts the number of responses given
responsePages = atrial.nPages-2:atrial.nPages;  % the last three pages are response pages
[~,n_categories] = size(Cfg.design.target_numbers);

page_idx_t1 = 1 + Cfg.T1_idx(atrial.trialNumber);
%page_idx_t2 = 1 + Cfg.T2_idx(atrial.trialNumber);

% the correct responses for this experiment are 3-fold:
% 1. did you see this image among the ones presented? Yes/No answer
% 2. subjective evaluation of how well one saw the image of (1)
% 3. selecting the correct answer to the math task
atrial.correctResponse(1) = 11;
% since this response 2 is a subjective measure, we don't really care
atrial.correctResponse(2) = 1; 
atrial.correctResponse(3) = 1; % this will get changed within each trial

% create 3 random numbers that are projected onto the stimuli. Numbers can
% occur in two back-to-back presentations but not on the same location. We
% use 'diff' to account for that
% vals = zeros(nPages,3);
% while any(any(diff(vals)==0))
%     vals = randi([2 9],nPages,3);
% end

T2_idx = zeros(atrial.nPages,1);
if any(atrial.code==1:n_categories+1)
    T2_idx(1:end-3) = any(atrial.pageNumber(1:end-3)==Cfg.stimuli.targets);
    pic1 = atrial.pageNumber(logical(T2_idx));
else
    pic1 = randi([Cfg.design.target_numbers(1) Cfg.design.target_numbers(end)],1,1);

end

[~,C] = ind2sub(size(Cfg.design.target_numbers),find(Cfg.design.target_numbers==pic1));

randT2 = randi([Cfg.design.target_numbers(1,C) Cfg.design.target_numbers(end,C)],1,1);
while randT2==pic1
    randT2 = randi([Cfg.design.target_numbers(1,C) Cfg.design.target_numbers(end,C)],1,1);
end

%%%%%%%% PS CODE END %%%%%%%%


%LOG DATE AND TIME OF TRIAL
strDate = datestr(now); %store when trial was presented

%--------------------------------------------------------------------------
% PHASE 1) WAIT FOR THE RIGHT TIME TO START TRIAL PRESENTATION. THIS MAY BE
% IMMEDIATELY OR USER DEFINED (E.G. IN fMRI EXPERIMENTS)
%--------------------------------------------------------------------------

% %JS METHOD: LOOP
% %IF EXTERNAL TIMING REQUESTED (e.g. fMRI JITTERING)
% if Cfg.useTrialOnsetTimes
%     while((GetSecs- Cfg.experimentStart) < atrial.tOnset)
%     end
% end
% %LOG TIME OF TRIAL ONSET WITH RESPECT TO START OF THE EXPERIMENT
% %USEFUL FOR DATA ANALYSIS IN fMRI
% tStart = GetSecs - Cfg.experimentStart;

%SUGGESTED METHOD: TIMED WAIT
%IF EXTERNAL TIMING REQUESTED (e.g. fMRI JITTERING)
if Cfg.useTrialOnsetTimes
    wakeupTime = WaitSecs('UntilTime', Cfg.experimentStart + atrial.tOnset);
else
    wakeupTime = GetSecs;
end
%LOG TIME OF TRIAL ONSET WITH RESPECT TO START OF THE EXPERIMENT
%USEFUL FOR DATA ANALYSIS IN fMRI
tStart = wakeupTime - Cfg.experimentStart;


if Cfg.Eyetracking.doDriftCorrection
    EyelinkDoDriftCorrect(Cfg.Eyetracking.el);
end

%--------------------------------------------------------------------------
%END OF PHASE 1
%--------------------------------------------------------------------------

%MESSAGE TO EYELINK
Cfg = ASF_sendMessageToEyelink(Cfg, 'TRIALSTART');

%--------------------------------------------------------------------------
% PHASE 2) LOOP THROUGH PAGE PRESENTATIONS WITHOUT RESPONSE COLLECTION
%--------------------------------------------------------------------------
%CYCLE THROUGH PAGES FOR THIS TRIAL
for i = 1:atrial.startRTonPage-1
    if (i > atrial.nPages)
        break;
    else

        %PUT THE APPROPRIATE TEXTURE ON THE BACK BUFFER
        Screen('DrawTexture', windowPtr, Stimuli.tex(atrial.pageNumber(i)));
        
        %%%%%%%% PS CODE %%%%%%%%
        % We want to superimpose numbers ontop of the stimuli
        if i > 1 && i ~= page_idx_t1 && ...
                ~any( ismember( atrial.pageNumber(i), Cfg.stimuli.targets ) )
            
%             msg = sprintf('%d',vals(i,:));
%             Screen('TextSize',windowPtr, instruction_font_size);
%             DrawFormattedText(windowPtr, msg,'center','center',confound_color);
%             Screen('TextSize',windowPtr, standard_font_size);
                        
        elseif i == page_idx_t1
            
%             math_result = vals(i,1)+vals(i,3);
%             msg = sprintf('%d+%d',vals(i,1),vals(i,3));
            msg = char(Cfg.arrow_for_T1(adjustment.trial_ctr,:));
            Screen('TextSize',windowPtr, T1_font_size);
            DrawFormattedText(windowPtr, msg,'center','center',target_color);
            Screen('TextSize',windowPtr, standard_font_size);
            
        end
        
        %%%%%%%% PS CODE END %%%%%%%%
        
        %PRESERVE BACK BUFFER IF THIS TEXTURE IS TO BE SHOWN
        %AGAIN AT THE NEXT FLIP
        bPreserveBackBuffer = atrial.pageDuration(i) > 1;
        
        %FLIP THE CONTENT OF THIS PAGE TO THE DISPLAY AND PRESERVE IT IN THE
        %BACKBUFFER IN CASE THE SAME IMAGE IS TO BE FLIPPED AGAIN TO THE SCREEN
        [VBLTimestamp StimulusOnsetTime FlipTimestamp Missed Beampos] =...
            ASF_xFlip(windowPtr, Stimuli.tex(atrial.pageNumber(i)),...
            Cfg, bPreserveBackBuffer);
        
        %SET TRIGGER (PARALLEL PORT AND EYELINK)
        ASF_setTrigger(Cfg, atrial.pageNumber(i));
        
        
        %LOG WHEN THIS PAGE APPEARED
        timing(i, 1:6) = [atrial.pageDuration(i), VBLTimestamp,...
            StimulusOnsetTime FlipTimestamp Missed Beampos];
        
        
        %WAIT OUT STIMULUS DURATION IN FRAMES. WE USE PAGE FLIPPING RATHER
        %THAN A TIMER WHENEVER POSSIBLE BECAUSE GRAPHICS BOARDS PROVIDE
        %EXCELLENT TIMING; THIS IS THE REASON WHY WE MAY WANT TO KEEP A
        %STIMULUS IN THE BACKBUFFER (NONDESTRUCTIVE PAGE FLIPPING)
        %NOT ALL GRAPHICS CARDS CAN DO THIS. FOR CARDS WITHOUT AUXILIARY
        %BACKBUFFERS WE COPY THE TEXTURE EXPLICITLY ON THE BACKBUFFER AFTER
        %IT HAS BEEN DESTROYED BY FLIPPING
        nFlips = atrial.pageDuration(i) - 1; %WE ALREADY FLIPPED ONCE
        for FlipNumber = 1:nFlips
            %PRESERVE BACK BUFFER IF THIS TEXTURE IS TO BE SHOWN
            %AGAIN AT THE NEXT FLIP
            bPreserveBackBuffer = FlipNumber < nFlips;
            
            %FLIP THE CONTENT OF THIS PAGE TO THE DISPLAY AND PRESERVE IT
            %IN THE BACKBUFFER IN CASE THE SAME IMAGE IS TO BE FLIPPED
            %AGAIN TO THE SCREEN
            ASF_xFlip(windowPtr, Stimuli.tex(atrial.pageNumber(i)),...
                Cfg, bPreserveBackBuffer);
        end
    end
end
%--------------------------------------------------------------------------
%END OF PHASE 2
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% PHASE 3) LOOP THROUGH PAGE PRESENTATIONS WHILE CHECKING FOR USER
%          INPUT/RESPONSES
%--------------------------------------------------------------------------
%SPECIAL TREATMENT FOR THE DISPLAY PAGES ON WHICH WE ALLOW REACTIONS
allowResponse = 1;
for i = atrial.startRTonPage:atrial.endRTonPage
    if (i > atrial.nPages)
        break;
    else
        
        %PUT THE APPROPRIATE TEXTURE ON THE BACK BUFFER
        %Screen('DrawTexture', windowPtr, Stimuli.tex(atrial.pageNumber(i)));
        Screen('DrawTexture', windowPtr, Stimuli.tex(1));
        
        %%%%%%%% PS CODE %%%%%%%%
        % DEPENDING ON THE RESPONSE PAGE WE WANT TO PRESENT DIFFERENT
        % THINGS
        if i == responsePages(1)
            
            % WE WANT TO HAVE TWO IMAGES SIDE BY SIDE. FOR THIS WE NEED TO
            % SEPARATE THE SCREEN INTO CERTAIN RECTANGLES TO PLACE THE
            % IMAGES ACCORDINGLY
            x = Cfg.Screen.rect(3) - Cfg.Screen.rect(1);
            y = Cfg.Screen.rect(4) - Cfg.Screen.rect(2);
            
            %Assuming that your pictures have a ratio of 4:3, you can place them nicely
            %on a 15 by 7 grid (count the columns (x) and rows (y) in the graph below
            
            % ---------------
            % ---------------
            % --oooo---oooo--
            % --oooo---oooo--
            % --oooo---oooo--
            % ---------------
            % ---------------
            
            %destinationRectangles  are defined as
            %[UpperLeftX, UpperLeftY, LowerRightX, LowerRightY]
            destinationRect1 = ceil([x/15*5 y/9*4 x/15*7 y/9*6]); %LEFT
            destinationRect2 = ceil([x/15*8 y/9*4 x/15*10 y/9*6]); %RIGHT
            
            
            
            if randi([0,1],1,1) % if this is true, the correct response is left
                atrial.correctResponse(1) = Cfg.enabledKeys(1);
                Screen('DrawTexture', windowPtr, Stimuli.tex(pic1),[],destinationRect1);
                Screen('DrawTexture', windowPtr, Stimuli.tex(randT2),[],destinationRect2);
            else
                atrial.correctResponse(1) = Cfg.enabledKeys(2);
                Screen('DrawTexture', windowPtr, Stimuli.tex(pic1),[],destinationRect2);
                Screen('DrawTexture', windowPtr, Stimuli.tex(randT2),[],destinationRect1);
            end
            
            % set the correct response
%             if ~(atrial.pageNumber(i) == atrial.pageNumber(page_idx_t2))
%                 atrial.correctResponse(1) = Cfg.enabledKeys(2);
%             end
%             
            msg = sprintf('Which image did you see?');
            Screen('TextSize',windowPtr, instruction_font_size);
            DrawFormattedText(windowPtr, msg,'center',350,confound_color);
            Screen('TextSize',windowPtr, standard_font_size);
            
        elseif i == responsePages(2)
            
            msg = sprintf('What was your experience of T2?\n\n none    vague    clear');
            Screen('TextSize',windowPtr, instruction_font_size);
            DrawFormattedText(windowPtr, msg,'center','center',confound_color);
            Screen('TextSize',windowPtr, standard_font_size);
            
        elseif i == responsePages(3)
            
%             % generate 2 random results among which the participant has to
%             % choose the correct one.
%             rnd_results = randi([2 18], 1, 2);
%             % generate them until there are two pseudo results that don't
%             % match the actual result
%             while sum( any( rnd_results == math_result) ) > 0 || ...
%                     length( unique( rnd_results ) ) ~= 2
%                 rnd_results = randi([2 18], 1, 2);
%             end
%             
%             % generate a permutation, such that the actual result is not
%             % always at the same location
%             permutation = randperm(3);
%             for_msg(permutation) = [rnd_results, math_result];
%             
%             % save the correct response for this trial
%             atrial.correctResponse(3) = Cfg.enabledKeys( for_msg == math_result );

            if Cfg.t1_correct_response(adjustment.trial_ctr)
                atrial.correctResponse(3) = Cfg.enabledKeys(2);
            else
                atrial.correctResponse(3) = Cfg.enabledKeys(1);
            end
            
            % print the addition task in red
%             msg = sprintf('What was the result of T1?\n1. %d\n2. %d\n3. %d', for_msg(1), for_msg(2), for_msg(3));
            msg = sprintf('More arrows pointing:\n\nleft     right');
            Screen('TextSize',windowPtr, instruction_font_size);
            DrawFormattedText(windowPtr, msg,'center','center',confound_color);
            Screen('TextSize',windowPtr, standard_font_size);
            
        end
        %%%%%%%% PS CODE END %%%%%%%%

        %DO NOT PUT THIS PAGE AGAIN ON THE BACKBUFFER, WE WILL WAIT IT OUT
        %USING THE TIMER NOT FLIPPING
        bPreserveBackBuffer = 0;
        
        %FLIP THE CONTENT OF THIS PAGE TO THE DISPLAY AND PRESERVE IT
        %IN THE BACKBUFFER IN CASE THE SAME IMAGE IS TO BE FLIPPED
        %AGAIN TO THE SCREEN
        [VBLTimestamp StimulusOnsetTime FlipTimestamp Missed Beampos] =...
            ASF_xFlip(windowPtr, Stimuli.tex(atrial.pageNumber(i)),...
            Cfg, bPreserveBackBuffer);
        
        %SET TRIGGER
        ASF_setTrigger(Cfg, atrial.pageNumber(i));
        
        % changed by PS for the attentional blink experiment
        if ismember(i, atrial.startRTonPage:atrial.endRTonPage)
            StartRTMeasurement = VBLTimestamp;
        end
        
        %STORE TIME OF PAGE FLIPPING FOR DIAGNOSTIC PURPOSES
        timing(i, 1:6) = [atrial.pageDuration(i), VBLTimestamp,...
            StimulusOnsetTime, FlipTimestamp, Missed, Beampos];
        
        pageDuration_in_sec =...
            atrial.pageDuration(i)*Cfg.Screen.monitorFlipInterval;
    
        if allowResponse           
            %---------------------------
            %WITH RESPONSE COLLECTION
            %---------------------------
            
            
            [x, y, buttons, t0, t1] =...
                ASF_waitForResponse(Cfg, pageDuration_in_sec - toleranceSec);
          
            if any(buttons)
                %BUTTON HAS BEEN PRESSED
                %THIS ALSO MEANS THAT THE PAGE MAY HAVE TO BE SHOWN FOR LONGER.
                %IF MULTIPLE RESPONSES ARE ALLOWED EVEN WITH MORE RESPONSE COLLECTION
                
                %INCREASE RESPONSE COUNTER
                responseCounter = responseCounter + 1;

                %FIND WHICH BUTTON IT WAS
                this_response.key(responseCounter) = find(buttons);
                %COMPUTE RESPONSE TIME
                this_response.RT(responseCounter) = (t1 - StartRTMeasurement)*1000;
                switch Cfg.responseSettings.multiResponse
                    case 'responseTerminatesTrial'
                        %NEED TO WORK ON THIS PART
                        break;
                    case 'allowMultipleResponses'
                        %CURRENTLY NO NEED FOR THIS PART IN THE ATTENTIONAL
                        %BLINK EXPERIMENT
                    case 'allowSingleResponse'
                        %A BUTTON HAS BEEN PRESSED BEFORE TIMEOUT
                        %WAIT OUT THE REMAINDER OF THE STIMULUS DURATION WITH
                        %MARGIN OF toleranceSec
%                         wakeupTime = WaitSecs('UntilTime',...
%                             StimulusOnsetTime + pageDuration_in_sec - toleranceSec);
                end
            else
                responseCounter = responseCounter + 1;
                this_response.key(responseCounter) = 0;
                this_response.RT(responseCounter) = NaN;
            end
        else
            %-----------------------------------
            %NO RESPONSE COLLECTION ON THIS PAGE
            %This can occur when
            %response period spans multiple pages, only one response
            %allowed, and response already given on a previous page
            %-----------------------------------
            %MAKE APPROPRIATE NUMBER OF NONDESTRUCTIVE FLIPS
            nFlips = atrial.pageDuration(i) - 1; %WE ALREADY FLIPPED ONCE
            for FlipNumber = 1:nFlips
                %PRESERVE BACK BUFFER IF THIS TEXTURE IS TO BE SHOWN
                %AGAIN AT THE NEXT FLIP
                bPreserveBackBuffer = FlipNumber < nFlips;
                
                %FLIP THE CONTENT OF THIS PAGE TO THE DISPLAY AND PRESERVE IT
                %IN THE BACKBUFFER IN CASE THE SAME IMAGE IS TO BE FLIPPED
                %AGAIN TO THE SCREEN
                ASF_xFlip(windowPtr, Stimuli.tex(atrial.pageNumber(i)),...
                    Cfg, bPreserveBackBuffer);
            end
        end
    end
end
%--------------------------------------------------------------------------
%END OF PHASE 3
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% PHASE 4) LOOP THROUGH PAGE PRESENTATIONS WITHOUT RESPONSE COLLECTION
% (AFTER RESPONSE HAS BEEN GIVEN) SAME AS PHASE 2
%--------------------------------------------------------------------------
%OTHER PICS
for i = (atrial.endRTonPage+1):nPages
    if (i > atrial.nPages)
        break;
    else
        %PUT THE APPROPRIATE TEXTURE ON THE BACK BUFFER
        Screen('DrawTexture', windowPtr, Stimuli.tex(atrial.pageNumber(i)));
        
        %PRESERVE BACK BUFFER IF THIS TEXTURE IS TO BE SHOWN
        %AGAIN AT THE NEXT FLIP
        bPreserveBackBuffer = atrial.pageDuration(i) > 1;
        
        %FLIP THE CONTENT OF THIS PAGE TO THE DISPLAY AND PRESERVE IT
        %IN THE BACKBUFFER IN CASE THE SAME IMAGE IS TO BE FLIPPED
        %AGAIN TO THE SCREEN
        [VBLTimestamp StimulusOnsetTime FlipTimestamp Missed Beampos] =...
            ASF_xFlip(windowPtr, Stimuli.tex(atrial.pageNumber(i)),...
            Cfg, bPreserveBackBuffer);
        
        %SET TRIGGER (PARALLEL PORT AND EYELINK)
        ASF_setTrigger(Cfg, atrial.pageNumber(i));
        
        
        %LOG WHEN THIS PAGE APPEARED
        timing(i, 1:6) = [atrial.pageDuration(i), VBLTimestamp,...
            StimulusOnsetTime FlipTimestamp Missed Beampos];
        
        %WAIT OUT STIMULUS DURATION IN FRAMES.
        nFlips = atrial.pageDuration(i) - 1; %WE ALREADY FLIPPED ONCE
        for FlipNumber = 1:nFlips
            %PRESERVE BACK BUFFER IF THIS TEXTURE IS TO BE SHOWN
            %AGAIN AT THE NEXT FLIP
            bPreserveBackBuffer = FlipNumber < nFlips;
            
            %FLIP THE CONTENT OF THIS PAGE TO THE DISPLAY AND PRESERVE IT
            %IN THE BACKBUFFER IN CASE THE SAME IMAGE IS TO BE FLIPPED
            %AGAIN TO THE SCREEN
            ASF_xFlip(windowPtr, Stimuli.tex(atrial.pageNumber(i)),...
                Cfg, bPreserveBackBuffer);
        end
    end
end

%--------------------------------------------------------------------------
%END OF PHASE 4
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% PHASE 5) FEEDBACK
%--------------------------------------------------------------------------
%IF YOU WANT TO FORCE A RESPONSE
if Cfg.waitUntilResponseAfterTrial && ~responseGiven
    [x, y, buttons, t0, t1] = ASF_waitForResponse(Cfg, 10);
    
    if any(buttons)
        %A BUTTON HAS BEEN PRESSED BEFORE TIMEOUT
        responseGiven = 1;  %#ok<NASGU>
        %FINDO OUT WHICH BUTTON IT WAS
        this_response.key = find(buttons);
        %COMPUTE RESPONSE TIME
        this_response.RT = (t1 - StartRTMeasurement)*1000;
    end
end

%TRIAL BY TRIAL FEEDBACK
if Cfg.feedbackTrialCorrect || Cfg.feedbackTrialError
    ASF_trialFeeback(...
        this_response.key(Cfg.feedbackResponseNumber) == atrial.CorrectResponse, Cfg, windowPtr);
end

%--------------------------------------------------------------------------
%END OF PHASE 5
%--------------------------------------------------------------------------

%%%%%%%% PS CODE %%%%%%%%

% Set some variables based on responses given.
if any(atrial.code==1:n_categories)
    
    if ~isempty(this_response.key)
        if this_response.key(2) ==  Cfg.enabledKeys(2)% for now hardcoded
            adjustment.correct_rsp(adjustment.trial_ctr,1) = 1;
        else
            adjustment.correct_rsp(adjustment.trial_ctr,1) = 0;
        end
        if this_response.key(3) == atrial.correctResponse(3)
            adjustment.correct_rsp(adjustment.trial_ctr,2) = 1;
        else
            adjustment.correct_rsp(adjustment.trial_ctr,2) = 0;
        end
    end
    
    % evaluate after a certain number of trials and adjust the presentation
    % time of the stimuli
    if mod(adjustment.trial_ctr, Cfg.design.evaluation_after_trials) == 0
        % check if the percentage of correct answers that T2 was seen given
        % that the math exercise was correct (T2|math)
        % We can easily compute this by summing the values of the
        % adjustment.correct_rsp matrix, checking for values equal to 2 and
        % then computing the mean. If this mean is <40% increase presentation
        % time, if it is >60% decrease presentation time (but not below 100ms)
        thisTrial = adjustment.trial_ctr;
        corr_rsp_idcs = sort( thisTrial:-1:thisTrial-(Cfg.design.evaluation_after_trials-1) );
        prct_correct = mean( sum( adjustment.correct_rsp(corr_rsp_idcs,:), 2 ) );
        if prct_correct < .4
            % adjust the presentation time of the stimuli pages
            adjustment.this_duration = adjustment.this_duration + Cfg.design.adjust_up;
        elseif prct_correct > .6 && (adjustment.this_duration - 1 > 6)
            % adjust the presentation time of the stimuli pages
            adjustment.this_duration = adjustment.this_duration - Cfg.design.adjust_down;
        end
    end
    
    % only count up when we are in a condition one trial
    adjustment.trial_ctr = adjustment.trial_ctr + 1;
end

%adjustment.correct_rsp

%%%%%%%% PS CODE END %%%%%%%%

%PACK INFORMATION ABOUT THIS TRIAL INTO STRUCTURE TrialInfo (THE RETURN
%ARGUMENT). PLEASE MAKE SURE THAT TrialInfo CONTAINS THE FIELDS:
%   trial
%   datestr
%   tStart
%   Response
%   timing
%   StartRTMeasurement
%   EndRTMeasurement
%OTHERWISE DIAGNOSTIC PROCEDURES OR ROUTINES FOR DATA ANALYSIS MAIGHT FAIL
TrialInfo.trial = atrial;  %REQUESTED PAGE NUMBERS AND DURATIONS
TrialInfo.datestr = strDate; %STORE WHEN THIS HAPPENED
TrialInfo.tStart = tStart; %TIME OF TRIAL-START
TrialInfo.Response = this_response; %KEY AND RT
TrialInfo.timing = timing; %TIMING OF PAGES
TrialInfo.StartRTMeasurement = StartRTMeasurement; %TIMESTAMP START RT
TrialInfo.EndRTMeasurement = EndRTMeasurement; %TIMESTAMP END RT