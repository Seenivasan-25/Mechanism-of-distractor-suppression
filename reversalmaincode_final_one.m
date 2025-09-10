% ---------- All setup code and practice loop here ----------
 try
 
 clear all; clc; sca;
 subj_name = input('Enter participant name: ', 's');
 subj_id = input('Enter participant id: ', 's');
 % PTB Screen and Input Settings
 Screen('Preference', 'SkipSyncTests', 1);
 [wPtr, rect] = Screen('OpenWindow', max(Screen('Screens')), 0);
 [xcenter, ycenter] = RectCenter(rect);
 Screen('TextSize', wPtr, 24); HideCursor();
 % Define response keys
 KbName('UnifyKeyNames');
 leftKey = KbName('LeftArrow');
 rightKey = KbName('RightArrow');
 quitKey = KbName('q'); 
 escapeKey = KbName('ESCAPE');
 % ----------- Load and Check Input Conditions -----------
 filename = sprintf('Results_%s_%s.csv', subj_name, subj_id);
%  conds = readtable("Input_file_without_reversal.xlsx");
%  conds = conds(randperm(height(conds)), :);
%  if height(conds) ~= 432
%  error('Input file should contain exactly 432 trials. Current file has %d trials.', height(conds));
%  end
 % ----------- Practice Setup -----------
 practice_filename = sprintf('Practice_Results_%s_%s.csv', subj_name, subj_id);
 skip_practice = exist(practice_filename, 'file');
 if skip_practice
 fprintf('Practice file found. Starting main experiment directly.\n');
 end
 % Visual parameters
 radius_6 = 240; radius_12 = 240;
 shapeSize = 40; lineWidth = 2; lineWidth2 = 2.83; gapSize = 20;
 fixColor = [255 255 255];
 % Data storage variables (practice)
 Practice_Subj = []; Practice_TrialNo = []; Practice_TargetIndex = []; Practice_ColorSingletonIndex = [];
 Practice_FlickerSingletonIndex = []; Practice_ColorSingleton = []; Practice_FlickerSingleton = [];
 Practice_ResponseKey = {}; Practice_feedback = []; Practice_searchRT = []; Practice_NumItems = []; Practice_SetSize = [];
 % ----------- Show Instructions -----------
 if ~skip_practice
 try
 % Display instruction image if available
 img = imread('Presentation1-2.jpg');
 instrTexture = Screen('MakeTexture', wPtr, img);
 [h, w, ~] = size(img); scale = 1.5;
 imgRect = CenterRectOnPointd([0 0 w*scale h*scale], xcenter, ycenter);
 Screen('DrawTexture', wPtr, instrTexture, [], imgRect);
 DrawFormattedText(wPtr, 'Press any key to continue...', 'center', ycenter + h*scale/2 - 250, [255 255 255]);
 Screen('Flip', wPtr); KbStrokeWait; Screen('Close', instrTexture);
 catch
 % Fallback to text if image is missing
 instr = ['Focus on the central fixation cross.\nFind the target (one gap only).\n' ...
 'Press LEFT if gap is left, RIGHT if gap is right.\nBe quick and accurate!'];
 DrawFormattedText(wPtr, instr, 'center', 'center', [255 255 255]);
 Screen('Flip', wPtr); KbStrokeWait;
 end
 % Short practice block notification
 DrawFormattedText(wPtr, 'Now you will complete 20 practice trials.\n\nPress any key to start.', 'center', 'center', [255 255 255]);
 Screen('Flip', wPtr); KbStrokeWait;
 % ----------- Generate Practice Trial Conditions -----------
 % Balanced, randomized practice trial combinations
 [color_vals, flicker_vals, setsize_vals] = ndgrid([0 1], [0 1], [0 1]);
 combinations = repmat([color_vals(:), flicker_vals(:), setsize_vals(:)], 3, 1);
 practice_conditions = combinations(randperm(size(combinations,1)), :);
 practice_color_singleton = practice_conditions(:,1);
 practice_flicker_singleton = practice_conditions(:,2);
 practice_set_sizes = practice_conditions(:,3);
 % ----------- Practice Trial Loop -----------
 for trial = 1:24
 % --- TRIAL SETUP ---
 % Set Display Parameters (set size and positions)
 setsize = practice_set_sizes(trial);
 num_items = 6 + 6*setsize; % (6 or 12)
 radius = (setsize==0)*radius_6 + (setsize==1)*radius_12;
 angles = linspace(0, 2*pi, num_items+1); angles(end) = [];
 positions = [xcenter + radius*cos(angles') - shapeSize/2, ...
 ycenter + radius*sin(angles') - shapeSize/2, ...
 xcenter + radius*cos(angles') + shapeSize/2, ...
 ycenter + radius*sin(angles') + shapeSize/2];
 % Assign target index
 target_index = randi(num_items);
 
 % --- NEW LOGIC: Color singleton present/absent, never coincides with target ---
 if practice_color_singleton(trial) == 0
 % No color singleton
 color_singleton_index = -1;
 else
 % Color singleton present but NOT on target
 opts = setdiff(1:num_items, target_index);
 color_singleton_index = opts(randi(length(opts)));
 end
 
%  % --- NEW LOGIC: Flicker singleton always present, can coincide with target ---
%  if practice_color_singleton(trial) == 0
%  % Flicker singleton IS the target
%  color_singleton_index = target_index;
%  else
%  % Flicker singleton is NOT the target
%  % Ensure it's not adjacent to color singleton (if color singleton exists)
%  opts = setdiff(1:num_items, target_index);
%  if color_singleton_index > 0 % Color singleton exists
%  if color_singleton_index == 1
%  adj = [num_items, 2];
%  elseif color_singleton_index == num_items
%  adj = [num_items-1, 1];
%  else
%  adj = [color_singleton_index-1, color_singleton_index+1];
%  end
%  opts = setdiff(opts, [adj, color_singleton_index]);
%  end
%  if isempty(opts)
%  opts = setdiff(1:num_items, target_index);
%  end
%  flicker_singleton_index = opts(randi(length(opts)));
%  end

% First, identify color singleton's neighbors
if color_singleton_index > 0
    if color_singleton_index == 1
        color_neighbors = [num_items, 2];
    elseif color_singleton_index == num_items
        color_neighbors = [num_items-1, 1];
    else
        color_neighbors = [color_singleton_index-1, color_singleton_index+1];
    end
else
    color_neighbors = [];
end

% Now assign flicker singleton
forbidden = [color_singleton_index, color_neighbors];

if practice_flicker_singleton(trial) == 0
    % Flicker singleton IS the target - target may NOT be adjacent to color singleton
    if ismember(target_index, forbidden)
        candidates = setdiff(1:num_items, forbidden);
        target_index = candidates(randi(length(candidates)));
    end
    flicker_singleton_index = target_index;
else
    % Flicker singleton is NOT the target - also never adjacent or on target
    forbidden_flicker = unique([color_singleton_index, color_neighbors, target_index]);
    opts = setdiff(1:num_items, forbidden_flicker);
    if isempty(opts)
        opts = setdiff(1:num_items, [color_singleton_index, color_neighbors]);
    end
    flicker_singleton_index = opts(randi(length(opts)));
end


 % --- FIXATION CROSS ---
 Screen('FillRect',wPtr,0);
 Screen('DrawLine', wPtr, fixColor, xcenter-10, ycenter, xcenter+10, ycenter, 2);
 Screen('DrawLine', wPtr, fixColor, xcenter, ycenter-10, xcenter, ycenter+10, 2);
 Screen('Flip', wPtr); WaitSecs(0.15);
 % --- PLACEHOLDER DISPLAY ---
 Screen('FillRect', wPtr, 0);
 for j = 1:num_items
 draw_four_gap_square(wPtr, positions(j,:), [255 255 255], lineWidth, gapSize);
 end
 Screen('DrawLine', wPtr, fixColor, xcenter-10, ycenter, xcenter+10, ycenter, 2);
 Screen('DrawLine', wPtr, fixColor, xcenter, ycenter-10, xcenter, ycenter+10, 2);
 Screen('Flip',wPtr); WaitSecs(0.76);
 % --- SEARCH DISPLAY WITH CUSTOM FLICKER TIMING ---
 timeLimit = 3.0; % Response window (seconds)
 distractor_types = randi(2, num_items, 1); % random distractor gap pattern
 % Flicker singleton is always present, so always assign type
 flicker_distractor_type = distractor_types(flicker_singleton_index);
 
 tStart = GetSecs; resp = ''; RT = NaN;
 % Choose target gap side
 if rand<0.5, target_gap_side='left'; else, target_gap_side='right'; end
 % Custom flicker timing: Square=60ms, Blank=30ms, Diamond=60ms, Blank=30ms
 square_duration = 0.06; % 60ms
 blank1_duration = 0.06; % 30ms
 diamond_duration = 0.06; % 60ms
 blank2_duration = 0.06; % 30ms
 total_cycle_duration = square_duration + blank1_duration + diamond_duration + blank2_duration;
 while (GetSecs - tStart) < timeLimit && isempty(resp)
 elapsed_time = GetSecs - tStart;
 
 % Calculate flicker state with custom timing
 time_in_cycle = mod(elapsed_time, total_cycle_duration);
 if time_in_cycle < square_duration
 flicker_state = 0; % Square
 elseif time_in_cycle < (square_duration + blank1_duration)
 flicker_state = 1; % Blank after square
 elseif time_in_cycle < (square_duration + blank1_duration + diamond_duration)
 flicker_state = 2; % Diamond
 else
 flicker_state = 3; % Blank after diamond
 end
 
 Screen('FillRect', wPtr, 0);
 % --- Draw All Objects This Frame ---
 for j = 1:num_items
 rect_pos = positions(j,:);
 cx = mean(rect_pos([1 3])); cy = mean(rect_pos([2 4]));
 
 % NEW: Color logic - red only if color singleton exists and j matches it
 if color_singleton_index > 0 && j == color_singleton_index
 item_color = [255 0 0]; % Red color singleton
 else
 item_color = [255 255 255]; % White
 end
 % NEW: Flicker singleton is always present and can be target or distractor
 if j == flicker_singleton_index
 % This item always flickers
 if j == target_index
 % Flicker singleton IS the target - draw target with flicker
 if flicker_state == 0
 % Square state - draw target normally
 if strcmp(target_gap_side,'left')
 draw_one_gap_left(wPtr, rect_pos, item_color, lineWidth, gapSize);
 else
 draw_one_gap_right(wPtr, rect_pos, item_color, lineWidth, gapSize);
 end
 elseif flicker_state == 2
 % Diamond state - draw rotated target
 Screen('glPushMatrix', wPtr);
 Screen('glTranslate', wPtr, cx, cy);
 Screen('glRotate', wPtr, 45, 0, 0, 1);
 Screen('glTranslate', wPtr, -cx, -cy);
 if strcmp(target_gap_side,'left')
 draw_one_gap_left(wPtr, rect_pos, item_color, lineWidth2, gapSize);
 else
 draw_one_gap_right(wPtr, rect_pos, item_color, lineWidth2, gapSize);
 end
 Screen('glPopMatrix', wPtr);
 end
 % States 1 & 3: blank, do nothing
 else
 % Flicker singleton is NOT the target - draw distractor with flicker
 if flicker_state == 0
 % Square state
 if flicker_distractor_type == 1
 draw_two_gap_vertical(wPtr, rect_pos, item_color, lineWidth, gapSize);
 else
 draw_two_gap_horizontal(wPtr, rect_pos, item_color, lineWidth, gapSize);
 end
 elseif flicker_state == 2
 % Diamond state
 Screen('glPushMatrix', wPtr);
 Screen('glTranslate', wPtr, cx, cy);
 Screen('glRotate', wPtr, 45, 0, 0, 1);
 Screen('glTranslate', wPtr, -cx, -cy);
 if flicker_distractor_type == 1
 draw_two_gap_vertical(wPtr, rect_pos, item_color, lineWidth2, gapSize);
 else
 draw_two_gap_horizontal(wPtr, rect_pos, item_color, lineWidth2, gapSize);
 end
 Screen('glPopMatrix', wPtr);
 end
 % States 1 & 3: blank, do nothing
 end
 elseif j == target_index
 % Target that is NOT flickering (static target)
 if strcmp(target_gap_side,'left')
 draw_one_gap_left(wPtr, rect_pos, item_color, lineWidth, gapSize);
 else
 draw_one_gap_right(wPtr, rect_pos, item_color, lineWidth, gapSize);
 end
 else
 % Regular distractors (not flickering, not target)
 if distractor_types(j) == 1
 draw_two_gap_vertical(wPtr, rect_pos, item_color, lineWidth, gapSize);
 else
 draw_two_gap_horizontal(wPtr, rect_pos, item_color, lineWidth, gapSize);
 end
 end
 end
 
 % Draw fixation cross again
 Screen('DrawLine', wPtr, fixColor, xcenter-10, ycenter, xcenter+10, ycenter, 2);
 Screen('DrawLine', wPtr, fixColor, xcenter, ycenter-10, xcenter, ycenter+10, 2);
 Screen('Flip', wPtr);
 % --- Check for Response ---
 [keyIsDown, ~, keyCode] = KbCheck;
 if keyIsDown
 if keyCode(quitKey) || keyCode(escapeKey)
 sca; ShowCursor; error('Aborted');
 elseif keyCode(leftKey)
 resp = 'left';
 RT = (GetSecs-tStart)*1000;
 break;
 elseif keyCode(rightKey)
 resp = 'right';
 RT = (GetSecs-tStart)*1000;
 break;
 end
 end
 WaitSecs(0.01); % maintain timing precision
 end % End search display & response loop
 % --- FEEDBACK & STORE TRIAL DATA ---
 if isempty(resp)
 resp = 'timeout';
 RT = NaN;
 DrawFormattedText(wPtr, 'Time elapsed!', 'center', 'center', [255 255 0]);
 Screen('Flip', wPtr); % FIXED: Added missing Screen('Flip')
 isCorrect = false;
 WaitSecs(1);
 else
 isCorrect = strcmp(resp, target_gap_side);
 if isCorrect
 DrawFormattedText(wPtr, 'Correct!', 'center', 'center', [0 255 0]);
 else
 DrawFormattedText(wPtr, 'Incorrect', 'center', 'center', [255 0 0]);
 end
 Screen('Flip', wPtr); WaitSecs(1);
 end
 % Store data for this practice trial
 Practice_Subj = [Practice_Subj; string(subj_name)];
 Practice_TrialNo = [Practice_TrialNo; trial];
 Practice_TargetIndex = [Practice_TargetIndex; target_index];
 Practice_ColorSingletonIndex = [Practice_ColorSingletonIndex; color_singleton_index];
 Practice_FlickerSingletonIndex = [Practice_FlickerSingletonIndex; flicker_singleton_index];
 Practice_ColorSingleton = [Practice_ColorSingleton; practice_color_singleton(trial)];
 Practice_FlickerSingleton = [Practice_FlickerSingleton; practice_flicker_singleton(trial)];
 Practice_ResponseKey = [Practice_ResponseKey; {resp}];
 Practice_feedback = [Practice_feedback; isCorrect];
 Practice_searchRT = [Practice_searchRT; RT];
 Practice_NumItems = [Practice_NumItems; num_items];
 Practice_SetSize = [Practice_SetSize; setsize];
 end % End practice trial loop
 % ----------- Save Practice Data and Show Performance -----------
 practice_data_table = table(Practice_TrialNo, Practice_TargetIndex, Practice_ColorSingletonIndex, ...
 Practice_FlickerSingletonIndex, Practice_ColorSingleton, Practice_FlickerSingleton, ...
 Practice_ResponseKey, Practice_feedback, Practice_searchRT, Practice_SetSize);
 writetable(practice_data_table, practice_filename);
 % Show accuracy and RT of practice session
 acc = sum(Practice_feedback)/length(Practice_feedback)*100;
 mean_RT = mean(Practice_searchRT(Practice_feedback==1));
 perf_text = sprintf('Practice Complete!\n\nYour Performance:\nAccuracy: %.1f%%\nMean RT (correct): %.2f ms\n\nPress any key to continue.', acc, mean_RT);
 DrawFormattedText(wPtr, perf_text, 'center', 'center', [255 255 255]);
 Screen('Flip', wPtr);
 KbStrokeWait;
 sca; ShowCursor;
 fprintf('Practice trials completed. Results: %s\n', practice_filename);
 fprintf('Run the script again to start the main experiment.\n');
 return;
 end
     % ----------- Load and Check Input Conditions -----------
    filename = sprintf('Results_%s_%s.csv', subj_name, subj_id);
    
    % Load the input file with reversal conditions
    try
        conds = readtable("Input_file_with_reversal.xlsx");
    catch
        % Try alternative file extensions/names
        try
            conds = readtable("Input_file_with_reversal.csv");
        catch
            error('Could not find input_reversal_file.xlsx or input_reversal_file.csv');
        end
    end
    
    % Randomize trial order
    conds = conds(randperm(height(conds)), :);
    
    % Check if file has expected number of trials
    if height(conds) ~= 432
        warning('Input file contains %d trials instead of expected 432 trials.', height(conds));
    end
    
    % ----------- Check Practice Completion -----------
    practice_filename = sprintf('Practice_Results_%s_%s.csv', subj_name, subj_id);
    if ~exist(practice_filename, 'file')
        error('Practice session not found. Please complete practice trials first.');
    end
    
    fprintf('Practice file found. Starting main experiment.\n');
    
    % Visual parameters
    radius_6 = 240; 
    radius_12 = 240;
    shapeSize = 40; 
    lineWidth = 2; 
    lineWidth2 = 2.83; 
    gapSize = 20;
    fixColor = [255 255 255];
    
    % Data storage variables (main experiment) - ALL TRIALS stored now
    Main_Subj = []; 
    Main_AttemptNo = [];        % Sequential number of all attempts
    Main_CorrectTrialNo = [];   % Sequential number of correct trials only (NaN for incorrect)
    Main_TargetIndex = []; 
    Main_ColorSingletonIndex = [];
    Main_FlickerSingletonIndex = []; 
    Main_ColorSingleton = []; 
    Main_FlickerSingleton = [];
    Main_ResponseKey = {}; 
    Main_Accuracy = []; 
    Main_SearchRT = []; 
    Main_NumItems = []; 
    Main_SetSize = [];
    
    % Tracking variables
    total_required_trials = height(conds); % 432 correct trials needed
    correct_trials_completed = 0;
    attempt_count = 0; % Total attempts (for break timing)
    current_trial_index = 1; % Index in the conditions array
    
    % ----------- Show Main Experiment Instructions -----------
    main_instr = ['Main Experiment\n\n' ...
                  'You will complete ' num2str(total_required_trials) ' CORRECT trials.\n\n' ...
                  'IMPORTANT: Only correct responses count toward completion.\n' ...
                  'Incorrect or timeout responses will require you to repeat trials.\n' ...
                  'All attempts (correct and incorrect) will be recorded.\n\n' ...
                  'Remember:\n' ...
                  '- Focus on the central fixation cross\n' ...
                  '- Find the target (square with one gap only)\n' ...
                  '- Press LEFT if gap is on left, RIGHT if gap is on right\n' ...
                  '- Be quick and accurate!\n\n' ...
                  'Press any key to start the main experiment.'];
    
    DrawFormattedText(wPtr, main_instr, 'center', 'center', [255 255 255]);
    Screen('Flip', wPtr); 
    KbStrokeWait;
    
    % ----------- Main Experiment Trial Loop -----------
    while correct_trials_completed < total_required_trials
        
        attempt_count = attempt_count + 1;
        
        % --- TRIAL SETUP ---
        % Get conditions from input file
        setsize = conds.SetSize(current_trial_index);
        color_singleton_present = conds.ColorSingleton(current_trial_index);
        flicker_singleton_present = conds.FlickerSingleton(current_trial_index);
        
        % Set Display Parameters (set size and positions)
        num_items = 6 + 6*setsize; % (6 or 12)
        radius = (setsize==0)*radius_6 + (setsize==1)*radius_12;
        angles = linspace(0, 2*pi, num_items+1); 
        angles(end) = [];
        positions = [xcenter + radius*cos(angles') - shapeSize/2, ...
                     ycenter + radius*sin(angles') - shapeSize/2, ...
                     xcenter + radius*cos(angles') + shapeSize/2, ...
                     ycenter + radius*sin(angles') + shapeSize/2];
        
        % Assign target index
        target_index = randi(num_items);
        
        % --- Color Singleton Logic ---
        if color_singleton_present == 0
            % No color singleton
            color_singleton_index = -1;
        else
            % Color singleton present but NOT on target
            opts = setdiff(1:num_items, target_index);
            color_singleton_index = opts(randi(length(opts)));
        end
        
        % --- Flicker Singleton Logic ---
        % First, identify color singleton's neighbors
        if color_singleton_index > 0
            if color_singleton_index == 1
                color_neighbors = [num_items, 2];
            elseif color_singleton_index == num_items
                color_neighbors = [num_items-1, 1];
            else
                color_neighbors = [color_singleton_index-1, color_singleton_index+1];
            end
        else
            color_neighbors = [];
        end
        
        % Now assign flicker singleton
        forbidden = [color_singleton_index, color_neighbors];
        
        if flicker_singleton_present == 0
            % Flicker singleton IS the target - target may NOT be adjacent to color singleton
            if ismember(target_index, forbidden)
                candidates = setdiff(1:num_items, forbidden);
                target_index = candidates(randi(length(candidates)));
            end
            flicker_singleton_index = target_index;
        else
            % Flicker singleton is NOT the target - also never adjacent or on target
            forbidden_flicker = unique([color_singleton_index, color_neighbors, target_index]);
            opts = setdiff(1:num_items, forbidden_flicker);
            if isempty(opts)
                opts = setdiff(1:num_items, [color_singleton_index, color_neighbors]);
            end
            flicker_singleton_index = opts(randi(length(opts)));
        end
        
        % --- FIXATION CROSS ---
        Screen('FillRect',wPtr,0);
        Screen('DrawLine', wPtr, fixColor, xcenter-10, ycenter, xcenter+10, ycenter, 2);
        Screen('DrawLine', wPtr, fixColor, xcenter, ycenter-10, xcenter, ycenter+10, 2);
        Screen('Flip', wPtr); 
        WaitSecs(0.15);
        
        % --- PLACEHOLDER DISPLAY ---
        Screen('FillRect', wPtr, 0);
        for j = 1:num_items
            draw_four_gap_square(wPtr, positions(j,:), [255 255 255], lineWidth, gapSize);
        end
        Screen('DrawLine', wPtr, fixColor, xcenter-10, ycenter, xcenter+10, ycenter, 2);
        Screen('DrawLine', wPtr, fixColor, xcenter, ycenter-10, xcenter, ycenter+10, 2);
        Screen('Flip',wPtr); 
        WaitSecs(0.76);
        
        % --- SEARCH DISPLAY WITH CUSTOM FLICKER TIMING ---
        timeLimit = 3.0; % Response window (seconds)
        distractor_types = randi(2, num_items, 1); % random distractor gap pattern
        
        % Flicker singleton is always present, so always assign type
        flicker_distractor_type = distractor_types(flicker_singleton_index);
        
        tStart = GetSecs; 
        resp = ''; 
        RT = NaN;
        
        % Choose target gap side
        if rand<0.5
            target_gap_side='left'; 
        else
            target_gap_side='right'; 
        end
        
        % Custom flicker timing: Square=60ms, Blank=30ms, Diamond=60ms, Blank=30ms
        square_duration = 0.06; % 60ms
        blank1_duration = 0.06; % 30ms
        diamond_duration = 0.06; % 60ms
        blank2_duration = 0.06; % 30ms
        total_cycle_duration = square_duration + blank1_duration + diamond_duration + blank2_duration;
        
        while (GetSecs - tStart) < timeLimit && isempty(resp)
            elapsed_time = GetSecs - tStart;
            
            % Calculate flicker state with custom timing
            time_in_cycle = mod(elapsed_time, total_cycle_duration);
            if time_in_cycle < square_duration
                flicker_state = 0; % Square
            elseif time_in_cycle < (square_duration + blank1_duration)
                flicker_state = 1; % Blank after square
            elseif time_in_cycle < (square_duration + blank1_duration + diamond_duration)
                flicker_state = 2; % Diamond
            else
                flicker_state = 3; % Blank after diamond
            end
            
            Screen('FillRect', wPtr, 0);
            
            % --- Draw All Objects This Frame ---
            for j = 1:num_items
                rect_pos = positions(j,:);
                cx = mean(rect_pos([1 3])); 
                cy = mean(rect_pos([2 4]));
                
                % Color logic - red only if color singleton exists and j matches it
                if color_singleton_index > 0 && j == color_singleton_index
                    item_color = [255 0 0]; % Red color singleton
                else
                    item_color = [255 255 255]; % White
                end
                
                % Flicker singleton is always present and can be target or distractor
                if j == flicker_singleton_index
                    % This item always flickers
                    if j == target_index
                        % Flicker singleton IS the target - draw target with flicker
                        if flicker_state == 0
                            % Square state - draw target normally
                            if strcmp(target_gap_side,'left')
                                draw_one_gap_left(wPtr, rect_pos, item_color, lineWidth, gapSize);
                            else
                                draw_one_gap_right(wPtr, rect_pos, item_color, lineWidth, gapSize);
                            end
                        elseif flicker_state == 2
                            % Diamond state - draw rotated target
                            Screen('glPushMatrix', wPtr);
                            Screen('glTranslate', wPtr, cx, cy);
                            Screen('glRotate', wPtr, 45, 0, 0, 1);
                            Screen('glTranslate', wPtr, -cx, -cy);
                            if strcmp(target_gap_side,'left')
                                draw_one_gap_left(wPtr, rect_pos, item_color, lineWidth2, gapSize);
                            else
                                draw_one_gap_right(wPtr, rect_pos, item_color, lineWidth2, gapSize);
                            end
                            Screen('glPopMatrix', wPtr);
                        end
                        % States 1 & 3: blank, do nothing
                    else
                        % Flicker singleton is NOT the target - draw distractor with flicker
                        if flicker_state == 0
                            % Square state
                            if flicker_distractor_type == 1
                                draw_two_gap_vertical(wPtr, rect_pos, item_color, lineWidth, gapSize);
                            else
                                draw_two_gap_horizontal(wPtr, rect_pos, item_color, lineWidth, gapSize);
                            end
                        elseif flicker_state == 2
                            % Diamond state
                            Screen('glPushMatrix', wPtr);
                            Screen('glTranslate', wPtr, cx, cy);
                            Screen('glRotate', wPtr, 45, 0, 0, 1);
                            Screen('glTranslate', wPtr, -cx, -cy);
                            if flicker_distractor_type == 1
                                draw_two_gap_vertical(wPtr, rect_pos, item_color, lineWidth2, gapSize);
                            else
                                draw_two_gap_horizontal(wPtr, rect_pos, item_color, lineWidth2, gapSize);
                            end
                            Screen('glPopMatrix', wPtr);
                        end
                        % States 1 & 3: blank, do nothing
                    end
                elseif j == target_index
                    % Target that is NOT flickering (static target)
                    if strcmp(target_gap_side,'left')
                        draw_one_gap_left(wPtr, rect_pos, item_color, lineWidth, gapSize);
                    else
                        draw_one_gap_right(wPtr, rect_pos, item_color, lineWidth, gapSize);
                    end
                else
                    % Regular distractors (not flickering, not target)
                    if distractor_types(j) == 1
                        draw_two_gap_vertical(wPtr, rect_pos, item_color, lineWidth, gapSize);
                    else
                        draw_two_gap_horizontal(wPtr, rect_pos, item_color, lineWidth, gapSize);
                    end
                end
            end
            
            % Draw fixation cross again
            Screen('DrawLine', wPtr, fixColor, xcenter-10, ycenter, xcenter+10, ycenter, 2);
            Screen('DrawLine', wPtr, fixColor, xcenter, ycenter-10, xcenter, ycenter+10, 2);
            Screen('Flip', wPtr);
            
            % --- Check for Response ---
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown
                if keyCode(quitKey) || keyCode(escapeKey)
                    sca; ShowCursor; error('Experiment aborted by user');
                elseif keyCode(leftKey)
                    resp = 'left';
                    RT = (GetSecs-tStart)*1000;
                    break;
                elseif keyCode(rightKey)
                    resp = 'right';
                    RT = (GetSecs-tStart)*1000;
                    break;
                end
            end
            WaitSecs(0.01); % maintain timing precision
        end % End search display & response loop
        
        % --- PROCESS RESPONSE & SHOW FEEDBACK ---
        if isempty(resp)
            resp = 'timeout';
            RT = NaN;
            DrawFormattedText(wPtr, 'Time elapsed! Try again.', 'center', 'center', [255 255 0]);
            Screen('Flip', wPtr);
            isCorrect = false;
            WaitSecs(1);
        else
            isCorrect = strcmp(resp, target_gap_side);
            if isCorrect
                DrawFormattedText(wPtr, 'Correct!', 'center', 'center', [0 255 0]);
            else
                DrawFormattedText(wPtr, 'Incorrect! Try again.', 'center', 'center', [255 0 0]);
            end
            Screen('Flip', wPtr); 
            WaitSecs(1);
        end
        
        % --- STORE ALL TRIAL DATA (CORRECT AND INCORRECT) ---
        Main_Subj = [Main_Subj; string(subj_name)];
        Main_AttemptNo = [Main_AttemptNo; attempt_count]; % Sequential number of all attempts
        
        % Store correct trial number only if this trial was correct
        if isCorrect
            correct_trials_completed = correct_trials_completed + 1;
            Main_CorrectTrialNo = [Main_CorrectTrialNo; correct_trials_completed];
            
            % Move to next trial condition only if current trial was correct
            current_trial_index = current_trial_index + 1;
            
            % Reset to beginning if we've cycled through all conditions but need more correct trials
            if current_trial_index > total_required_trials
                current_trial_index = 1;
                % Re-randomize the order for the next cycle
                conds = conds(randperm(height(conds)), :);
            end
        else
            Main_CorrectTrialNo = [Main_CorrectTrialNo; NaN]; % Mark incorrect trials with NaN
            % If incorrect, current_trial_index stays the same (repeat the same trial)
        end
        
        Main_TargetIndex = [Main_TargetIndex; target_index];
        Main_ColorSingletonIndex = [Main_ColorSingletonIndex; color_singleton_index];
        Main_FlickerSingletonIndex = [Main_FlickerSingletonIndex; flicker_singleton_index];
        Main_ColorSingleton = [Main_ColorSingleton; color_singleton_present];
        Main_FlickerSingleton = [Main_FlickerSingleton; flicker_singleton_present];
        Main_ResponseKey = [Main_ResponseKey; {resp}];
        Main_Accuracy = [Main_Accuracy; isCorrect];
        Main_SearchRT = [Main_SearchRT; RT];
        Main_NumItems = [Main_NumItems; num_items];
        Main_SetSize = [Main_SetSize; setsize];
        
        % --- BREAK EVERY 72 ATTEMPTS WITH 30-SECOND COUNTDOWN ---
        % --- BREAK EVERY 72 ATTEMPTS WITH 30-SECOND COUNTDOWN ---
if mod(attempt_count, 72) == 0
    progress_text = sprintf(['Break Time!\n\n' ...
                             'Attempts completed: %d\n' ...
                             'Correct trials completed: %d of %d\n' ...
                             'Accuracy so far: %.1f%%\n\n' ...
                             'You have a 30-second break.\n' ...
                             'Please wait for the countdown to end.'], ...
                             attempt_count, correct_trials_completed, total_required_trials, ...
                             (correct_trials_completed/attempt_count)*100);

    % 30-second countdown timer
    break_start_time = GetSecs;
    break_duration = 30; % 30 seconds

    while (GetSecs - break_start_time) < break_duration
        time_remaining = break_duration - (GetSecs - break_start_time);
        countdown_text = sprintf(['%s\n\nTime remaining: %d seconds\n\n' ...
                                  'Please wait...'], ...
                                  progress_text, ceil(time_remaining));

        DrawFormattedText(wPtr, countdown_text, 'center', 'center', [255 255 255]);
        Screen('Flip', wPtr);

        WaitSecs(0.1); % Update every 100ms
    
end

            
            % Final message before continuing
            DrawFormattedText(wPtr, 'Break over! Press any key to continue.', 'center', 'center', [255 255 255]);
            Screen('Flip', wPtr);
            KbStrokeWait;
        else
            % Brief inter-trial interval
            Screen('FillRect', wPtr, 0);
            Screen('DrawLine', wPtr, fixColor, xcenter-10, ycenter, xcenter+10, ycenter, 2);
            Screen('DrawLine', wPtr, fixColor, xcenter, ycenter-10, xcenter, ycenter+10, 2);
            Screen('Flip', wPtr);
            WaitSecs(0.5);
        end
        
    end % End main experiment trial loop
    
    % ----------- Save Main Experiment Data (ALL TRIALS) -----------
    main_data_table = table(Main_AttemptNo, Main_CorrectTrialNo, Main_TargetIndex, ...
                           Main_ColorSingletonIndex, Main_FlickerSingletonIndex, Main_ColorSingleton, ...
                           Main_FlickerSingleton, Main_ResponseKey, Main_Accuracy, Main_SearchRT, ...
                           Main_NumItems, Main_SetSize);
    
    writetable(main_data_table, filename);
    
    % ----------- Show Final Performance -----------
    overall_acc = (correct_trials_completed/attempt_count)*100;
    mean_RT_correct = mean(Main_SearchRT(Main_Accuracy==1));
    
    final_text = sprintf(['Experiment Complete!\n\n' ...
                         'Your Performance:\n' ...
                         'Total Attempts: %d\n' ...
                         'Correct Trials Completed: %d\n' ...
                         'Incorrect Trials: %d\n' ...
                         'Overall Accuracy: %.1f%%\n' ...
                         'Mean RT (correct trials): %.2f ms\n\n' ...
                         'Thank you for participating!\n\n' ...
                         'Press any key to exit.'], ...
                         attempt_count, correct_trials_completed, ...
                         attempt_count - correct_trials_completed, overall_acc, mean_RT_correct);
    
    DrawFormattedText(wPtr, final_text, 'center', 'center', [255 255 255]);
    Screen('Flip', wPtr);
    KbStrokeWait;
    
    % Clean up
    sca; 
    ShowCursor;
    
    fprintf('Main experiment completed successfully!\n');
    fprintf('Results saved to: %s\n', filename);
    fprintf('Total attempts: %d\n', attempt_count);
    fprintf('Correct trials completed: %d\n', correct_trials_completed);
    fprintf('Incorrect trials: %d\n', attempt_count - correct_trials_completed);
    fprintf('Overall accuracy: %.1f%%\n', overall_acc);
    fprintf('Mean RT (correct): %.2f ms\n', mean_RT_correct);
    
catch ME
    % Error handling, screen cleanup
    sca; 
    ShowCursor;
    psychrethrow(ME);
end

% ----------- Modular Stimulus Drawing Functions -----------
function draw_four_gap_square(wPtr, pos, color, lineWidth, gapSize)
    % Draws a square placeholder with gaps on all four sides
    left = pos(1); right = pos(3); top = pos(2); bottom = pos(4);
    cx = mean([left right]); cy = mean([top bottom]);
    Screen('DrawLine', wPtr, color, left, top, cx-gapSize/2, top, lineWidth);
    Screen('DrawLine', wPtr, color, cx+gapSize/2, top, right, top, lineWidth);
    Screen('DrawLine', wPtr, color, left, bottom, cx-gapSize/2, bottom, lineWidth);
    Screen('DrawLine', wPtr, color, cx+gapSize/2, bottom, right, bottom, lineWidth);
    Screen('DrawLine', wPtr, color, left, top, left, cy-gapSize/2, lineWidth);
    Screen('DrawLine', wPtr, color, left, cy+gapSize/2, left, bottom, lineWidth);
    Screen('DrawLine', wPtr, color, right, top, right, cy-gapSize/2, lineWidth);
    Screen('DrawLine', wPtr, color, right, cy+gapSize/2, right, bottom, lineWidth);
end

function draw_two_gap_horizontal(wPtr, pos, color, lineWidth, gapSize)
    % Draws a square with horizontal gaps (left and right sides)
    left = pos(1); right = pos(3); top = pos(2); bottom = pos(4);
    cx = mean([left right]); cy = mean([top bottom]);
    Screen('DrawLine', wPtr, color, left, top, right, top, lineWidth);
    Screen('DrawLine', wPtr, color, left, bottom, right, bottom, lineWidth);
    Screen('DrawLine', wPtr, color, left, top, left, cy-gapSize/2, lineWidth);
    Screen('DrawLine', wPtr, color, left, cy+gapSize/2, left, bottom, lineWidth);
    Screen('DrawLine', wPtr, color, right, top, right, cy-gapSize/2, lineWidth);
    Screen('DrawLine', wPtr, color, right, cy+gapSize/2, right, bottom, lineWidth);
end

function draw_two_gap_vertical(wPtr, pos, color, lineWidth, gapSize)
    % Draws a square with vertical gaps (top and bottom) by rotating the horizontal-gap square by 90°
    cx = mean(pos([1 3])); cy = mean(pos([2 4]));
    Screen('glPushMatrix', wPtr);
    Screen('glTranslate', wPtr, cx, cy);
    Screen('glRotate', wPtr, 90, 0, 0, 1);
    Screen('glTranslate', wPtr, -cx, -cy);
    draw_two_gap_horizontal(wPtr, pos, color, lineWidth, gapSize);
    Screen('glPopMatrix', wPtr);
end

function draw_one_gap_left(wPtr, pos, color, lineWidth, gapSize)
    % Target box with a single gap on the left
    left = pos(1); right = pos(3); top = pos(2); bottom = pos(4); cy = mean([top bottom]);
    Screen('DrawLine', wPtr, color, left, top, right, top, lineWidth);
    Screen('DrawLine', wPtr, color, left, bottom, right, bottom, lineWidth);
    Screen('DrawLine', wPtr, color, right, top, right, bottom, lineWidth);
    Screen('DrawLine', wPtr, color, left, top, left, cy-gapSize/2, lineWidth);
    Screen('DrawLine', wPtr, color, left, cy+gapSize/2, left, bottom, lineWidth);
end

function draw_one_gap_right(wPtr, pos, color, lineWidth, gapSize)
    % Target box with a single gap on the right (created by rotating the left-gap target)
    cx = mean(pos([1 3])); cy = mean(pos([2 4]));
    Screen('glPushMatrix', wPtr);
    Screen('glTranslate', wPtr, cx, cy);
    Screen('glRotate', wPtr, 180, 0, 0, 1);
    Screen('glTranslate', wPtr, -cx, -cy);
    draw_one_gap_left(wPtr, pos, color, lineWidth, gapSize);
    Screen('glPopMatrix', wPtr);
end