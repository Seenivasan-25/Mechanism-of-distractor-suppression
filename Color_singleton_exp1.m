% Color singleton coinciding with the
% target in 1/n trials. Placeholder display of 750m duration followed by
% 250ms of appearance of one singleton (color) followed by the
% normal search display without the singleton and just the target with one gap
% to left or right - Exp1_colorsingleton


clear all; clc; sca;
 
subj_name=input('Enter participant name:','s');
subj_id=input('Enter participant id:','s');
 
try
    if IsLinux || IsOSX
        Screen('Preference', 'SkipSyncTests',1);
    end
 
    [wPtr, rect] = Screen('OpenWindow', max(Screen('Screens')), 0);
    [xcenter, ycenter] = RectCenter(rect);
    Screen('TextSize', wPtr, 24); HideCursor();
 
    % Key setup
    KbName('UnifyKeyNames');
    leftKey = KbName('LeftArrow');
    rightKey = KbName('RightArrow');
    quitKey = KbName('q'); escapeKey = KbName('ESCAPE');
   
    filename=sprintf('Results_%s_%s.csv',subj_name,subj_id);
 
    % Load new input file
    conds = readtable("Inputfile.xlsx");    
    conds = conds(randperm(height(conds)),:);
    N = height(conds);
    practice_filename=sprintf('Practice_Results_%s_%s.csv',subj_name,subj_id);
    skip_practice=exist(practice_filename,'file');
    if skip_practice
        fprintf('Practice file found. Starting main experiment directly.\n');
    end
    
 
    % Visual parameters
    radius_6 = 240;  % Radius for 6 items
    radius_12 = 240; % Radius for 12 items
    shapeSize = 40; lineWidth = 2; gapSize = 20;
    thickLineWidth=6;
    box_color = [255 255 255]; fixColor = [255 255 255];
    % Practice data storage variables
    Practice_Subj = []; Practice_TrialNo = []; Practice_TargetIndex = []; Practice_SalientIndex = [];
    Practice_TargetType = []; Practice_SingletonTarget = [];
    Practice_ResponseKey = {}; Practice_feedback = []; Practice_searchRT = []; Practice_NumItems = [];
    Practice_SetSize = []; % Add SetSize to practice data storage
 
    % Data storage
    Subj = []; TrialNo = []; TargetIndex = []; SalientIndex = [];
    PlaceholderType = []; TargetType = []; SingletonTarget = [];
    ResponseKey = {}; feedback = []; searchRT = []; NumItems = [];
    SetSize = []; % Add SetSize to data storage
    if ~skip_practice
 
 
    % DISPLAY INSTRUCTION IMAGE
    try
        % Load the instruction image
        instructionImageFile = 'Presentation1-2.jpg'; % Change this to your image filename
        instructionImage = imread(instructionImageFile);
        
        % Make texture from image
        instructionTexture = Screen('MakeTexture', wPtr, instructionImage);
        
        % Get image dimensions
        [imageHeight, imageWidth, ~] = size(instructionImage);
        
        % Optional: Scale the image if needed
        scaleFactor = 1.5; % Adjust this value to make image smaller/larger
        displayWidth = imageWidth * scaleFactor;
        displayHeight = imageHeight * scaleFactor;
        
        % Center the image on screen
        imageRect = CenterRectOnPointd([0 0 displayWidth displayHeight], xcenter, ycenter);
        
        % Draw the instruction image
        Screen('DrawTexture', wPtr, instructionTexture, [], imageRect);
        
        % Optional: Add text below the image (e.g., "Press any key to continue")
        continueText = 'Press any key to continue...';
       
        DrawFormattedText(wPtr, continueText, 'center',ycenter+displayHeight/2-250, [255 255 255]);
        
        % Display everything
        Screen('Flip', wPtr);
        
        % Wait for key press
        KbStrokeWait;
        
        % Clean up texture
        Screen('Close', instructionTexture);
        
    catch imageError
        % Fallback to text instructions if image loading fails
        fprintf('Error loading instruction image: %s\n', imageError.message);
        fprintf('Falling back to text instructions...\n');
        
        instructions = ['Focus on the central fixation cross on the screen.\nFind the target stimulus which has only one gap.\nPress the right arrow key if the gap is towards right  and the left arrow key if the gap is towards the left direction.\nDo the experient as quickly and as accurately as possible'];
        DrawFormattedText(wPtr, instructions, 'center', 'center', [255 255 255]);
        Screen('Flip', wPtr); 
        KbStrokeWait;
    end
     % PRACTICE TRIALS
     
    practice_instructions = ['Now you will complete 20 practice trials.\n\n'...
                           'Press any key to start practice.'];
   
    DrawFormattedText(wPtr, practice_instructions, 'center', 'center', [255 255 255]);
    Screen('Flip', wPtr); KbStrokeWait;
 
    % Create balanced practice conditions (20 trials)
    practice_conditions = [];
    
    % Create 20 practice trials with balanced conditions
    % Target types: 1=Singleton, 2=Non-Singleton, 3=Absent
    % Set sizes: 0=6 items, 1=12 items
    
    % 7 trials each for Singleton and Non-Singleton, 6 trials for Absent
    % Balanced across set sizes
    target_types = [repmat(1, 7, 1); repmat(2, 7, 1); repmat(3, 6, 1)];
    set_sizes = [repmat([0; 1], 10, 1)]; % Alternating set sizes for 20 trials
    
    % Randomize the order
    practice_order = randperm(20);
    practice_target_types = target_types(practice_order);
    practice_set_sizes = set_sizes(practice_order);
 
    % Practice trial loop
    for practice_trial = 1:20
        % Get condition for this practice trial
        target_type = practice_target_types(practice_trial);
        set_size_code = practice_set_sizes(practice_trial);
        
        if set_size_code == 0
            num_items = 6;
            radius = radius_6;
        else
            num_items = 12;
            radius = radius_12;
        end
       
        % Calculate positions
        angles = linspace(0, 2*pi, num_items+1); angles(end) = [];
        positions = zeros(num_items, 4);
        for j = 1:num_items
            angle = angles(j);
            xpos = xcenter + radius * cos(angle);
            ypos = ycenter + radius * sin(angle);
            positions(j,:) = [xpos-shapeSize/2, ypos-shapeSize/2, xpos+shapeSize/2, ypos+shapeSize/2];
        end
 
        % Determine target and salient indices based on condition (same as main experiment)
        target_index = randi(num_items);
       
        if target_type == 1  % Singleton Target (target = salient)
            salient_index = target_index;
            singletonTarget = 1;
        elseif target_type == 2  % Non-Singleton Target (target != salient)  
            opts = setdiff(1:num_items, target_index);
            salient_index = opts(randi(length(opts)));
            singletonTarget = 0;
        else  % target_type == 3, Singleton Absent (no singleton, target present)
            salient_index = -1; % No salient item (no singleton)
            singletonTarget = 0;
        end
 
        % Fixation
        Screen('FillRect', wPtr, 0);
        Screen('DrawLine', wPtr, fixColor, xcenter-10, ycenter, xcenter+10, ycenter, 2);
        Screen('DrawLine', wPtr, fixColor, xcenter, ycenter-10, xcenter, ycenter+10, 2);
        Screen('Flip', wPtr); WaitSecs(0.15);
 
        % First Placeholder display (only corner brackets)
        Screen('FillRect', wPtr, 0);
        for j = 1:num_items
            % For absent trials (target_type == 3), no singleton appears
            if target_type == 3
                col = [255 255 255]; % All white, no red singleton
            else
                col = [255 255 255] * (j == salient_index) + [255 255 255] * (j ~= salient_index);
            end
            rect_pos = positions(j,:);
           
            % Corner brackets placeholder
            cornerSize = 10;
            % Top-left corner
            Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(2), rect_pos(1)+cornerSize, rect_pos(2), lineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(2), rect_pos(1), rect_pos(2)+cornerSize, lineWidth);
            % Top-right corner
            Screen('DrawLine', wPtr, col, rect_pos(3)-cornerSize, rect_pos(2), rect_pos(3), rect_pos(2), lineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(3), rect_pos(2), rect_pos(3), rect_pos(2)+cornerSize, lineWidth);
            % Bottom-left corner
            Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(4)-cornerSize, rect_pos(1), rect_pos(4), lineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(4), rect_pos(1)+cornerSize, rect_pos(4), lineWidth);
            % Bottom-right corner
            Screen('DrawLine', wPtr, col, rect_pos(3)-cornerSize, rect_pos(4), rect_pos(3), rect_pos(4), lineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(3), rect_pos(4)-cornerSize, rect_pos(3), rect_pos(4), lineWidth);
        end
        Screen('DrawLine', wPtr, fixColor, xcenter-10, ycenter, xcenter+10, ycenter, 2);
        Screen('DrawLine', wPtr, fixColor, xcenter, ycenter-10, xcenter, ycenter+10, 2);
        Screen('Flip', wPtr); WaitSecs(0.75);
       
        % Second Placeholder display (for 250 ms) - with thick lines for salient
        Screen('FillRect', wPtr, 0);
        for j = 1:num_items
            % For absent trials (target_type == 3), no singleton appears
            if target_type == 3
                col = [255 255 255]; % All white, no red singleton
                currentLineWidth = lineWidth; % All same line width
            else
                col = [255 0 0] * (j == salient_index) + [255 255 255] * (j ~= salient_index);
                currentLineWidth = thickLineWidth * (j == salient_index) + lineWidth * (j ~= salient_index);
            end
            rect_pos = positions(j,:);
           
            % Corner brackets placeholder
            cornerSize = 10;
            % Top-left corner
            Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(2), rect_pos(1)+cornerSize, rect_pos(2), currentLineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(2), rect_pos(1), rect_pos(2)+cornerSize, currentLineWidth);
            % Top-right corner
            Screen('DrawLine', wPtr, col, rect_pos(3)-cornerSize, rect_pos(2), rect_pos(3), rect_pos(2), currentLineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(3), rect_pos(2), rect_pos(3), rect_pos(2)+cornerSize, currentLineWidth);
            % Bottom-left corner
            Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(4)-cornerSize, rect_pos(1), rect_pos(4), currentLineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(4), rect_pos(1)+cornerSize, rect_pos(4), currentLineWidth);
            % Bottom-right corner
            Screen('DrawLine', wPtr, col, rect_pos(3)-cornerSize, rect_pos(4), rect_pos(3), rect_pos(4), currentLineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(3), rect_pos(4)-cornerSize, rect_pos(3), rect_pos(4), currentLineWidth);
        end
        Screen('DrawLine', wPtr, fixColor, xcenter-10, ycenter, xcenter+10, ycenter, 2);
        Screen('DrawLine', wPtr, fixColor, xcenter, ycenter-10, xcenter, ycenter+10, 2);
        Screen('Flip', wPtr); WaitSecs(0.25);
       
        % Search display
        Screen('FillRect', wPtr, 0);
       
         % Determine target gap side (left or right only)
        target_gap_side = '';
        if rand < 0.5
            target_gap_side = 'left';
        else
            target_gap_side = 'right';
        end
       
        for j = 1:num_items
            rect_pos = positions(j,:);
            cx = mean(rect_pos([1,3]));
            cy = mean(rect_pos([2,4]));
           
            if j == target_index
                % Draw target with single gap on left or right side
                if strcmp(target_gap_side, 'left')
                    % Gap on left side only
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), rect_pos(2), rect_pos(1), cy-gapSize/2, lineWidth);
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), cy+gapSize/2, rect_pos(1), rect_pos(4), lineWidth);
                    % Complete other sides
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), rect_pos(2), rect_pos(3), rect_pos(2), lineWidth);
                    Screen('DrawLine', wPtr, box_color, rect_pos(3), rect_pos(2), rect_pos(3), rect_pos(4), lineWidth);
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), rect_pos(4), rect_pos(3), rect_pos(4), lineWidth);
                else % right side
                    % Gap on right side only
                    Screen('DrawLine', wPtr, box_color, rect_pos(3), rect_pos(2), rect_pos(3), cy-gapSize/2, lineWidth);
                    Screen('DrawLine', wPtr, box_color, rect_pos(3), cy+gapSize/2, rect_pos(3), rect_pos(4), lineWidth);
                    % Complete other sides
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), rect_pos(2), rect_pos(1), rect_pos(4), lineWidth);
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), rect_pos(2), rect_pos(3), rect_pos(2), lineWidth);
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), rect_pos(4), rect_pos(3), rect_pos(4), lineWidth);
                end
            else
                % Draw distractors - only 2 types
                distractor_type = randi(2);
               
                if distractor_type == 1
                    % Vertical gaps (top and bottom gaps)
                    % Gap on top
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), rect_pos(2), cx-gapSize/2, rect_pos(2), lineWidth);
                    Screen('DrawLine', wPtr, box_color, cx+gapSize/2, rect_pos(2), rect_pos(3), rect_pos(2), lineWidth);
                    % Gap on bottom
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), rect_pos(4), cx-gapSize/2, rect_pos(4), lineWidth);
                    Screen('DrawLine', wPtr, box_color, cx+gapSize/2, rect_pos(4), rect_pos(3), rect_pos(4), lineWidth);
                    % Complete left and right sides
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), rect_pos(2), rect_pos(1), rect_pos(4), lineWidth);
                    Screen('DrawLine', wPtr, box_color, rect_pos(3), rect_pos(2), rect_pos(3), rect_pos(4), lineWidth);
                   
                else % distractor_type == 2
                    % Horizontal gaps (left and right gaps)
                    % Gap on left
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), rect_pos(2), rect_pos(1), cy-gapSize/2, lineWidth);
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), cy+gapSize/2, rect_pos(1), rect_pos(4), lineWidth);
                    % Gap on right
                    Screen('DrawLine', wPtr, box_color, rect_pos(3), rect_pos(2), rect_pos(3), cy-gapSize/2, lineWidth);
                    Screen('DrawLine', wPtr, box_color, rect_pos(3), cy+gapSize/2, rect_pos(3), rect_pos(4), lineWidth);
                    % Complete top and bottom sides
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), rect_pos(2), rect_pos(3), rect_pos(2), lineWidth);
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), rect_pos(4), rect_pos(3), rect_pos(4), lineWidth);
                end
            end
        end
 
        % Fixation cross
        Screen('DrawLine', wPtr, fixColor, xcenter-10, ycenter, xcenter+10, ycenter, 2);
        Screen('DrawLine', wPtr, fixColor, xcenter, ycenter-10, xcenter, ycenter+10, 2);
        Screen('Flip', wPtr); tStart = GetSecs;
 
       % Response collection with time limit
        resp = '';
        timeLimit = 3.0; % 3000ms time limit
        timedOut = false;
        RT=NaN;
        
 
        while GetSecs - tStart < timeLimit
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown
                if keyCode(quitKey) || keyCode(escapeKey)
                    sca; ShowCursor; error('Aborted');
                elseif keyCode(leftKey)
                    resp = 'left'; 
                    RT=(GetSecs-tStart)*1000;
                    break;
                elseif keyCode(rightKey)
                    resp = 'right'; 
                    RT=(GetSecs-tStart)*1000;
                    break;
                end
            end
        end
 
        %%RT = GetSecs - tStart;
 
        % Check if time elapsed
        if isempty(resp)
            timedOut = true;
            resp = 'timeout';
            RT=NaN;
            DrawFormattedText(wPtr, 'Time elapsed!', 'center', 'center', [255 255 0]);
            Screen('Flip', wPtr); 
            WaitSecs(1);
            isCorrect=false;
        else
            correctResp = target_gap_side;
            isCorrect = strcmp(resp, correctResp);
        
         % Feedback
            if isCorrect
                feedback_text = 'Correct!';
                feedback_color = [0 255 0];
            else
                feedback_text = 'Incorrect';
                feedback_color = [255 0 0];
            end
            DrawFormattedText(wPtr, feedback_text, 'center', 'center', feedback_color);
            Screen('Flip', wPtr); WaitSecs(1);
        end
    
   % Store practice trial data
    Practice_Subj = [Practice_Subj; string(subj_name)];
    Practice_TrialNo = [Practice_TrialNo; practice_trial];
    Practice_TargetIndex = [Practice_TargetIndex; target_index];
    if target_type == 3
        Practice_SalientIndex = [Practice_SalientIndex; NaN]; % No salient index for absent trials
    else
        Practice_SalientIndex = [Practice_SalientIndex; salient_index];
    end
    Practice_TargetType = [Practice_TargetType; target_type];
    Practice_SingletonTarget = [Practice_SingletonTarget; singletonTarget];
    Practice_ResponseKey = [Practice_ResponseKey; {resp}];
    Practice_feedback = [Practice_feedback; isCorrect];
    Practice_searchRT = [Practice_searchRT; RT];
    Practice_NumItems = [Practice_NumItems; num_items];
    Practice_SetSize = [Practice_SetSize; set_size_code];
end% End of practice trial loop
 
    % SAVE PRACTICE DATA and CHECK PERFORMANCE
    practice_filename = sprintf('Practice_Results_%s_%s.csv', subj_name, subj_id);
    practice_data_table = table(Practice_TrialNo, Practice_TargetIndex, Practice_SalientIndex, ...
                           Practice_TargetType, Practice_SingletonTarget, Practice_ResponseKey, ...
                           Practice_feedback, Practice_searchRT,  Practice_SetSize);
    writetable(practice_data_table, practice_filename);
 
    % Calculate practice performance
    practice_accuracy = sum(Practice_feedback) / length(Practice_feedback) * 100;
    mean_practice_RT = mean(Practice_searchRT(Practice_feedback == 1)); % RT for correct trials only
 
    % Display practice performance
    performance_text = sprintf('Practice Complete!\n\nYour Performance:\nAccuracy: %.1f%%\nMean RT (correct): %.2f seconds\n\nPress any key to continue to main experiment.', ...
                          practice_accuracy, mean_practice_RT);
 
    DrawFormattedText(wPtr, performance_text, 'center', 'center', [255 255 255]);
    Screen('Flip', wPtr); 
    KbStrokeWait;
    sca;
    ShowCursor;
    fprintf('Practice trials completed.Check the results file:%s\n',practice_filename);
    fprintf('Run the script again to start the main experiment.\n');
    return;
    end
     % MAIN EXPERIMENT INSTRUCTIONS (Always shown before main experiment)
    main_experiment_instructions = ['Main Experiment\n\n'...
                                  'You will now begin the main experiment.\n\n'...
                                  'Press SPACE to start.'];
    
    DrawFormattedText(wPtr, main_experiment_instructions, 'center', 'center', [255 255 255]);
    Screen('Flip', wPtr);
    
    % Wait specifically for spacebar press
    spaceKey = KbName('space');
    while true
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown && keyCode(spaceKey)
            break;
        elseif keyIsDown && (keyCode(quitKey) || keyCode(escapeKey))
            sca; ShowCursor; error('Aborted');
        end
        WaitSecs(0.01); % Small delay to prevent excessive CPU usage
    end
 
 
 
    % MAIN EXPERIMENT LOOP
    for trial = 1:N
        % Check for break every 72 trials
        if mod(trial-1, 72) == 0 && trial > 1
            break_text = sprintf('Break time!\n\nYou have completed %d trials.\n\nTake a 30-second rest.\n\nThe experiment will continue automatically.', trial-1);
            DrawFormattedText(wPtr, break_text, 'center', 'center', [255 255 255]);
            Screen('Flip', wPtr);
            
            % 30-second countdown
            for countdown = 30:-1:1
                countdown_text = sprintf('Break time!\n\nYou have completed %d trials.\n\nTake a 30-second rest.\n\nResuming in: %d seconds', trial-1, countdown);
                DrawFormattedText(wPtr, countdown_text, 'center', 'center', [255 255 255]);
                Screen('Flip', wPtr);
                WaitSecs(1);
            end
            
            % Ready to continue
            continue_text = 'Break over!\n\nPress any key to continue with the experiment.';
            DrawFormattedText(wPtr, continue_text, 'center', 'center', [255 255 255]);
            Screen('Flip', wPtr);
            KbStrokeWait;
        end
        
        % Get condition parameters from input file
        target_type = conds.TargetType(trial);  % 1=Singleton, 2=Non-Singleton, 3=Absent
        set_size_code = conds.SetSize(trial);   % 0 or 1 from input file
       
        % Convert 0/1 encoding to actual number of items
        if set_size_code == 0
            num_items = 6;
            radius = radius_6;
        else  % set_size_code == 1
            num_items = 12;
            radius = radius_12;
        end
       
        % Calculate positions
        angles = linspace(0, 2*pi, num_items+1); angles(end) = [];
        positions = zeros(num_items, 4);
        for j = 1:num_items
            angle = angles(j);
            xpos = xcenter + radius * cos(angle);
            ypos = ycenter + radius * sin(angle);
            positions(j,:) = [xpos-shapeSize/2, ypos-shapeSize/2, xpos+shapeSize/2, ypos+shapeSize/2];
        end
 
        % Determine target and salient indices based on condition
        target_index = randi(num_items);
       
        if target_type == 1  % Singleton Target (target = salient)
            salient_index = target_index;
            singletonTarget = 1;
        elseif target_type == 2  % Non-Singleton Target (target != salient)  
            opts = setdiff(1:num_items, target_index);
            salient_index = opts(randi(length(opts)));
            singletonTarget = 0;
        else  % target_type == 3, Singleton Absent (no singleton, target present)
            salient_index = -1; % No salient item (no singleton)
            singletonTarget = 0;
        end
 
        % Fixation
        Screen('FillRect', wPtr, 0);
        Screen('DrawLine', wPtr, fixColor, xcenter-10, ycenter, xcenter+10, ycenter, 2);
        Screen('DrawLine', wPtr, fixColor, xcenter, ycenter-10, xcenter, ycenter+10, 2);
        Screen('Flip', wPtr); WaitSecs(0.15);
 
        % First Placeholder display (only corner brackets)
        Screen('FillRect', wPtr, 0);
        for j = 1:num_items
            % For absent trials (target_type == 3), no singleton appears
            if target_type == 3
                col = [255 255 255]; % All white, no red singleton
            else
                col = [255 255 255] * (j == salient_index) + [255 255 255] * (j ~= salient_index);
            end
            rect_pos = positions(j,:);
           
            % Corner brackets placeholder
            cornerSize = 10;
            % Top-left corner
            Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(2), rect_pos(1)+cornerSize, rect_pos(2), lineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(2), rect_pos(1), rect_pos(2)+cornerSize, lineWidth);
            % Top-right corner
            Screen('DrawLine', wPtr, col, rect_pos(3)-cornerSize, rect_pos(2), rect_pos(3), rect_pos(2), lineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(3), rect_pos(2), rect_pos(3), rect_pos(2)+cornerSize, lineWidth);
            % Bottom-left corner
            Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(4)-cornerSize, rect_pos(1), rect_pos(4), lineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(4), rect_pos(1)+cornerSize, rect_pos(4), lineWidth);
            % Bottom-right corner
            Screen('DrawLine', wPtr, col, rect_pos(3)-cornerSize, rect_pos(4), rect_pos(3), rect_pos(4), lineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(3), rect_pos(4)-cornerSize, rect_pos(3), rect_pos(4), lineWidth);
        end
        Screen('DrawLine', wPtr, fixColor, xcenter-10, ycenter, xcenter+10, ycenter, 2);
        Screen('DrawLine', wPtr, fixColor, xcenter, ycenter-10, xcenter, ycenter+10, 2);
        Screen('Flip', wPtr); WaitSecs(0.75);
       
        % Second Placeholder display (for 250 ms) - with thick lines for salient
        Screen('FillRect', wPtr, 0);
        for j = 1:num_items
            % For absent trials (target_type == 3), no singleton appears
            if target_type == 3
                col = [255 255 255]; % All white, no red singleton
                currentLineWidth = lineWidth; % All same line width
            else
                col = [255 0 0] * (j == salient_index) + [255 255 255] * (j ~= salient_index);
                currentLineWidth = thickLineWidth * (j == salient_index) + lineWidth * (j ~= salient_index);
            end
            rect_pos = positions(j,:);
           
            % Corner brackets placeholder
            cornerSize = 10;
            % Top-left corner
            Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(2), rect_pos(1)+cornerSize, rect_pos(2), currentLineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(2), rect_pos(1), rect_pos(2)+cornerSize, currentLineWidth);
            % Top-right corner
            Screen('DrawLine', wPtr, col, rect_pos(3)-cornerSize, rect_pos(2), rect_pos(3), rect_pos(2), currentLineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(3), rect_pos(2), rect_pos(3), rect_pos(2)+cornerSize, currentLineWidth);
            % Bottom-left corner
            Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(4)-cornerSize, rect_pos(1), rect_pos(4), currentLineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(4), rect_pos(1)+cornerSize, rect_pos(4), currentLineWidth);
            % Bottom-right corner
            Screen('DrawLine', wPtr, col, rect_pos(3)-cornerSize, rect_pos(4), rect_pos(3), rect_pos(4), currentLineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(3), rect_pos(4)-cornerSize, rect_pos(3), rect_pos(4), currentLineWidth);
        end
        Screen('DrawLine', wPtr, fixColor, xcenter-10, ycenter, xcenter+10, ycenter, 2);
        Screen('DrawLine', wPtr, fixColor, xcenter, ycenter-10, xcenter, ycenter+10, 2);
        Screen('Flip', wPtr); WaitSecs(0.25);
       
        % Search display
        Screen('FillRect', wPtr, 0);
       
        % Target gap side (only relevant for target present trials)
        target_gap_side = '';
        if rand < 0.5
            target_gap_side = 'left';
        else
            target_gap_side = 'right';
        end
       
        for j = 1:num_items
            rect_pos = positions(j,:);
            cx = mean(rect_pos([1,3]));
            cy = mean(rect_pos([2,4]));
           
            if j == target_index
                % Draw target with single gap (target is always present in all conditions)
                if strcmp(target_gap_side, 'left')
                    % Gap on left side only
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), rect_pos(2), rect_pos(1), cy-gapSize/2, lineWidth);
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), cy+gapSize/2, rect_pos(1), rect_pos(4), lineWidth);
                    % Complete other sides
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), rect_pos(2), rect_pos(3), rect_pos(2), lineWidth);
                    Screen('DrawLine', wPtr, box_color, rect_pos(3), rect_pos(2), rect_pos(3), rect_pos(4), lineWidth);
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), rect_pos(4), rect_pos(3), rect_pos(4), lineWidth);
                else % right side
                    % Gap on right side only
                    Screen('DrawLine', wPtr, box_color, rect_pos(3), rect_pos(2), rect_pos(3), cy-gapSize/2, lineWidth);
                    Screen('DrawLine', wPtr, box_color, rect_pos(3), cy+gapSize/2, rect_pos(3), rect_pos(4), lineWidth);
                    % Complete other sides
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), rect_pos(2), rect_pos(1), rect_pos(4), lineWidth);
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), rect_pos(2), rect_pos(3), rect_pos(2), lineWidth);
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), rect_pos(4), rect_pos(3), rect_pos(4), lineWidth);
                end
            else
                % Draw distractors - only 2 types
                distractor_type = randi(2);
               
                if distractor_type == 1
                    % Vertical gaps (top and bottom gaps)
                    % Gap on top
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), rect_pos(2), cx-gapSize/2, rect_pos(2), lineWidth);
                    Screen('DrawLine', wPtr, box_color, cx+gapSize/2, rect_pos(2), rect_pos(3), rect_pos(2), lineWidth);
                    % Gap on bottom
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), rect_pos(4), cx-gapSize/2, rect_pos(4), lineWidth);
                    Screen('DrawLine', wPtr, box_color, cx+gapSize/2, rect_pos(4), rect_pos(3), rect_pos(4), lineWidth);
                    % Complete left and right sides
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), rect_pos(2), rect_pos(1), rect_pos(4), lineWidth);
                    Screen('DrawLine', wPtr, box_color, rect_pos(3), rect_pos(2), rect_pos(3), rect_pos(4), lineWidth);
                   
                else % distractor_type == 2
                    % Horizontal gaps (left and right gaps)
                    % Gap on left
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), rect_pos(2), rect_pos(1), cy-gapSize/2, lineWidth);
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), cy+gapSize/2, rect_pos(1), rect_pos(4), lineWidth);
                    % Gap on right
                    Screen('DrawLine', wPtr, box_color, rect_pos(3), rect_pos(2), rect_pos(3), cy-gapSize/2, lineWidth);
                    Screen('DrawLine', wPtr, box_color, rect_pos(3), cy+gapSize/2, rect_pos(3), rect_pos(4), lineWidth);
                    % Complete top and bottom sides
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), rect_pos(2), rect_pos(3), rect_pos(2), lineWidth);
                    Screen('DrawLine', wPtr, box_color, rect_pos(1), rect_pos(4), rect_pos(3), rect_pos(4), lineWidth);
                end
            end
        end
 
        % Fixation cross
        Screen('DrawLine', wPtr, fixColor, xcenter-10, ycenter, xcenter+10, ycenter, 2);
        Screen('DrawLine', wPtr, fixColor, xcenter, ycenter-10, xcenter, ycenter+10, 2);
        Screen('Flip', wPtr); tStart = GetSecs;
 
        % Response collection with time limit
        resp = '';
        timeLimit = 3.0; % 3000ms time limit
        timedOut = false;
        RT=NaN;
 
        while GetSecs - tStart < timeLimit
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown
                if keyCode(quitKey) || keyCode(escapeKey)
                    sca; ShowCursor; error('Aborted');
                elseif keyCode(leftKey)
                    resp = 'left'; 
                    RT=(GetSecs-tStart)*1000;
                    break;
                elseif keyCode(rightKey)
                    resp = 'right'; 
                    RT=(GetSecs-tStart)*1000;
                    break;
                end
            end
        end
 
        %%RT = GetSecs - tStart;
 
        % Check if time elapsed
        if isempty(resp)
            timedOut = true;
            resp = 'timeout';
            RT=NaN;
            DrawFormattedText(wPtr, 'Time elapsed!', 'center', 'center', [255 255 0]);
            Screen('Flip', wPtr); 
            WaitSecs(1);
            isCorrect=false;
        else
            correctResp = target_gap_side;
            isCorrect = strcmp(resp, correctResp);
        
         % Feedback
            if isCorrect
                feedback_text = 'Correct!';
                feedback_color = [0 255 0];
            else
                feedback_text = 'Incorrect';
                feedback_color = [255 0 0];
            end
            DrawFormattedText(wPtr, feedback_text, 'center', 'center', feedback_color);                                                                                                                     
            Screen('Flip', wPtr); WaitSecs(1);
        end
       
        
    
 
        
        % Store trial data
        Subj = [Subj; string(subj_name)];
        TrialNo = [TrialNo; trial];
        TargetIndex = [TargetIndex; target_index];
        if target_type == 3
            SalientIndex = [SalientIndex; NaN]; % No salient index for absent trials
        else
            SalientIndex = [SalientIndex; salient_index];
        end
        TargetType = [TargetType; target_type];
        SingletonTarget = [SingletonTarget; singletonTarget];
        ResponseKey = [ResponseKey; {resp}];
        feedback = [feedback; isCorrect];
        searchRT = [searchRT; RT];
        NumItems = [NumItems; num_items];
        SetSize=[SetSize; set_size_code];
        SubjName=repmat({subj_name},length(Subj),1);
        SubjID=repmat({subj_id},length(Subj),1);
        
        % Brief pause between trials
        WaitSecs(0.5);
    end
 
    % Save data
    data_table = table(TrialNo, TargetIndex, SalientIndex,TargetType, SingletonTarget, ResponseKey, feedback, searchRT,SetSize);
    writetable(data_table, filename);
    
    % End message
    DrawFormattedText(wPtr, 'Experiment complete!\n\nThank you for participating.\n\nPress any key to exit.', 'center', 'center', [255 255 255]);
    Screen('Flip', wPtr); KbStrokeWait;
    
    sca; ShowCursor;
    
catch ME
    sca; ShowCursor; 
    fprintf('ERROR: %s\n', ME.message);
    if exist('Subj', 'var')
        SubjName=repmat({subj_name},length(Subj),1);
        SubjID=repmat({subj_id},length(Subj),1);
        
        data = table(TrialNo, TargetIndex, SalientIndex, TargetType, SingletonTarget, ResponseKey, feedback, searchRT,SetSize);
        writetable(data, filename);    
    end   
end