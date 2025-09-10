%% flicker singleton present/absent with color singleton coinciding with the
% target in 1/n trials. Placeholder display of 750m duration followed by
% 250ms of appearance of two singletons or one singleton followed by the
% normal search display without singeltons and just the target with one gap
% to left or rightn -Exp2_secondpilot_withflicker

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
 
    % Load new input file - should have 540 rows
    conds = readtable("Input_file_without_reversal.xlsx");    
    conds = conds(randperm(height(conds)),:);
    N = height(conds);
    
    % Check if we have exactly 540 trials
    if N ~= 432
        error('Input file should contain exactly 432 trials. Current file has %d trials.', N);
    end
    
    practice_filename=sprintf('Practice_Results_%s_%s.csv',subj_name,subj_id);
    skip_practice=exist(practice_filename,'file');
    if skip_practice
        fprintf('Practice file found. Starting main experiment directly.\n');
    end
    
    % Visual parameters
    radius_6 = 240;  % Radius for 6 items
    radius_12 = 240; % Radius for 12 items
    shapeSize = 40; lineWidth = 2;LineWidth2=4; gapSize = 20;
    thickLineWidth=6;
    box_color = [255 255 255]; fixColor = [255 255 255];
    
    % Practice data storage variables
    Practice_Subj = []; Practice_TrialNo = []; Practice_TargetIndex = []; Practice_ColorSingletonIndex = [];
    Practice_FlickerSingletonIndex = []; Practice_ColorSingleton = []; Practice_FlickerSingleton = [];
    Practice_ResponseKey = {}; Practice_feedback = []; Practice_searchRT = [];Practice_NumItems = [];
    Practice_SetSize = [];
 
    % Data storage for main experiment
    Subj = []; TrialNo = []; TargetIndex = []; ColorSingletonIndex = []; FlickerSingletonIndex = [];
    ColorSingleton = []; FlipperSingleton = [];
    ResponseKey = {}; feedback = []; searchRT = []; NumItems = [];
    SetSize = [];
    
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
        % For practice, use simple conditions
        color_singleton_vals = [zeros(10,1); ones(10,1)]; % 10 each of 0 and 1
        flicker_singleton_vals = [zeros(10,1); ones(10,1)]; % 10 each of 0 and 1
        set_size_vals = [zeros(10,1); ones(10,1)]; % 10 each of 0 and 1
        
        % Randomize
        practice_order = randperm(20);
        practice_color_singleton = color_singleton_vals(practice_order);
        practice_flicker_singleton = flicker_singleton_vals(practice_order);
        practice_set_sizes = set_size_vals(practice_order);
     
        % Practice trial loop
        for practice_trial = 1:20
            % Get condition for this practice trial
            color_singleton_code = practice_color_singleton(practice_trial);
            flicker_singleton_code = practice_flicker_singleton(practice_trial);
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
     
            % Determine target index (always present)
            target_index = randi(num_items);
            
            % Determine color singleton index
            if color_singleton_code == 0 % Color singleton is target
                color_singleton_index = target_index;
            else % Color singleton is non-target
                opts = setdiff(1:num_items, target_index);
                color_singleton_index = opts(randi(length(opts)));
            end
            
            % Determine shape singleton index (if present)
            if flicker_singleton_code == 1 % Shape singleton present
                % Shape singleton should not be the target
                opts = setdiff(1:num_items, target_index);
               % shape_singleton_index = opts(randi(length(opts)));
                %adjacent_positions=[mod(color_singleton_index-2,num_items)+1,...
                                    %mod(color_singleton_index,num_items)+1];
                if color_singleton_index==1
                    adjacent_positions=[num_items,2];
                elseif color_singleton_index==num_items
                    adjacent_positions=[num_items-1,1];
                else
                    adjacent_positions=[color_singleton_index-1,color_singleton_index+1];
                end
                opts=setdiff(opts,[adjacent_positions,color_singleton_index]);
                if ~isempty(opts)
                    flicker_singleton_index=opts(randi(length(opts)));
               else
                    all_opts=setdiff(1:num_items,[target_index,flicker_singleton_index]);
                    if ~isempty(all_opts)
                        color_singleton_index=all_opts(randi(length(all_opts)));
                    else
                        all_opts=setdiff(1:num_items,target_index);
                        color_singleton_index=all_opts(randi(length(all_opts)));
                        warning('Could not maintain adjacency constraing-very rare edge case');
                    end
                end
            else % Shape singleton absent
                flicker_singleton_index = -1;
            end
     
            % Fixation
            Screen('FillRect', wPtr, 0);
            Screen('DrawLine', wPtr, fixColor, xcenter-10, ycenter, xcenter+10, ycenter, 2);
            Screen('DrawLine', wPtr, fixColor, xcenter, ycenter-10, xcenter, ycenter+10, 2);
            Screen('Flip', wPtr); WaitSecs(0.15);
     
            % First Placeholder display (only corner brackets - all white)
            Screen('FillRect', wPtr, 0);
            for j = 1:num_items
                col = [255 255 255]; % All white in first display
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
            Screen('Flip', wPtr); WaitSecs(0.76);
           
            % Second Placeholder display - alternating pattern if shape singleton present
if flicker_singleton_code == 1
    % Alternating display: shape singleton (60ms) -> corners (60ms) -> shape singleton (60ms) -> corners (60ms)
    for cycle = 1:2
        % First: Shape singleton display (60ms)
        Screen('FillRect', wPtr, 0);
        for j = 1:num_items
            if j == color_singleton_index
                col = [255 0 0]; % Red for color singleton
                currentLineWidth = thickLineWidth;
            else
                col = [255 255 255]; % White for others
                currentLineWidth = lineWidth;
            end
            
            rect_pos = positions(j,:);
            
            if j == flicker_singleton_index
                % Draw diamond-shaped corners for shape singleton
                cornerSize = 10;
                rect_center_x = (rect_pos(1) + rect_pos(3)) / 2;
                rect_center_y = (rect_pos(2) + rect_pos(4)) / 2;
                
                % Top diamond
                top_x = rect_center_x;
                top_y = rect_pos(2) - cornerSize;
                Screen('DrawLine', wPtr, col, top_x - cornerSize/2, top_y + cornerSize/2, top_x, top_y, LineWidth2);
                Screen('DrawLine', wPtr, col, top_x, top_y, top_x + cornerSize/2, top_y + cornerSize/2, LineWidth2);
                
                % Right diamond
                right_x = rect_pos(3) + cornerSize;
                right_y = rect_center_y;
                Screen('DrawLine', wPtr, col, right_x - cornerSize/2, right_y - cornerSize/2, right_x, right_y, LineWidth2);
                Screen('DrawLine', wPtr, col, right_x, right_y, right_x - cornerSize/2, right_y + cornerSize/2, LineWidth2);
                
                % Bottom diamond
                bottom_x = rect_center_x;
                bottom_y = rect_pos(4) + cornerSize;
                Screen('DrawLine', wPtr, col, bottom_x - cornerSize/2, bottom_y - cornerSize/2, bottom_x, bottom_y, LineWidth2);
                Screen('DrawLine', wPtr, col, bottom_x, bottom_y, bottom_x + cornerSize/2, bottom_y - cornerSize/2, LineWidth2);
                
                % Left diamond
                left_x = rect_pos(1) - cornerSize;
                left_y = rect_center_y;
                Screen('DrawLine', wPtr, col, left_x + cornerSize/2, left_y - cornerSize/2, left_x, left_y, LineWidth2);
                Screen('DrawLine', wPtr, col, left_x, left_y, left_x + cornerSize/2, left_y + cornerSize/2, LineWidth2);
            else
                % Regular corner brackets
                cornerSize = 10;
                Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(2), rect_pos(1)+cornerSize, rect_pos(2), currentLineWidth);
                Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(2), rect_pos(1), rect_pos(2)+cornerSize, currentLineWidth);
                Screen('DrawLine', wPtr, col, rect_pos(3)-cornerSize, rect_pos(2), rect_pos(3), rect_pos(2), currentLineWidth);
                Screen('DrawLine', wPtr, col, rect_pos(3), rect_pos(2), rect_pos(3), rect_pos(2)+cornerSize, currentLineWidth);
                Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(4)-cornerSize, rect_pos(1), rect_pos(4), currentLineWidth);
                Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(4), rect_pos(1)+cornerSize, rect_pos(4), currentLineWidth);
                Screen('DrawLine', wPtr, col, rect_pos(3)-cornerSize, rect_pos(4), rect_pos(3), rect_pos(4), currentLineWidth);
                Screen('DrawLine', wPtr, col, rect_pos(3), rect_pos(4)-cornerSize, rect_pos(3), rect_pos(4), currentLineWidth);
            end
        end
        Screen('DrawLine', wPtr, fixColor, xcenter-10, ycenter, xcenter+10, ycenter, 2);
        Screen('DrawLine', wPtr, fixColor, xcenter, ycenter-10, xcenter, ycenter+10, 2);
        Screen('Flip', wPtr); WaitSecs(0.06);
        
        % Second: Corner brackets only (60ms)
        Screen('FillRect', wPtr, 0);
        for j = 1:num_items
            if j == color_singleton_index
                col = [255 0 0]; % Red for color singleton
                currentLineWidth = thickLineWidth;
            else
                col = [255 255 255]; % White for others
                currentLineWidth = lineWidth;
            end
            
            rect_pos = positions(j,:);
            
            % All items show regular corner brackets
            cornerSize = 10;
            Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(2), rect_pos(1)+cornerSize, rect_pos(2), currentLineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(2), rect_pos(1), rect_pos(2)+cornerSize, currentLineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(3)-cornerSize, rect_pos(2), rect_pos(3), rect_pos(2), currentLineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(3), rect_pos(2), rect_pos(3), rect_pos(2)+cornerSize, currentLineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(4)-cornerSize, rect_pos(1), rect_pos(4), currentLineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(4), rect_pos(1)+cornerSize, rect_pos(4), currentLineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(3)-cornerSize, rect_pos(4), rect_pos(3), rect_pos(4), currentLineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(3), rect_pos(4)-cornerSize, rect_pos(3), rect_pos(4), currentLineWidth);
        end
        Screen('DrawLine', wPtr, fixColor, xcenter-10, ycenter, xcenter+10, ycenter, 2);
        Screen('DrawLine', wPtr, fixColor, xcenter, ycenter-10, xcenter, ycenter+10, 2);
        Screen('Flip', wPtr); WaitSecs(0.06);
    end
else
    % No shape singleton - single display (240ms)
    Screen('FillRect', wPtr, 0);
    for j = 1:num_items
        if j == color_singleton_index
            col = [255 0 0]; % Red for color singleton
            currentLineWidth = thickLineWidth;
        else
            col = [255 255 255]; % White for others
            currentLineWidth = lineWidth;
        end
        
        rect_pos = positions(j,:);
        
        % Regular corner brackets only
        cornerSize = 10;
        Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(2), rect_pos(1)+cornerSize, rect_pos(2), currentLineWidth);
        Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(2), rect_pos(1), rect_pos(2)+cornerSize, currentLineWidth);
        Screen('DrawLine', wPtr, col, rect_pos(3)-cornerSize, rect_pos(2), rect_pos(3), rect_pos(2), currentLineWidth);
        Screen('DrawLine', wPtr, col, rect_pos(3), rect_pos(2), rect_pos(3), rect_pos(2)+cornerSize, currentLineWidth);
        Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(4)-cornerSize, rect_pos(1), rect_pos(4), currentLineWidth);
        Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(4), rect_pos(1)+cornerSize, rect_pos(4), currentLineWidth);
        Screen('DrawLine', wPtr, col, rect_pos(3)-cornerSize, rect_pos(4), rect_pos(3), rect_pos(4), currentLineWidth);
        Screen('DrawLine', wPtr, col, rect_pos(3), rect_pos(4)-cornerSize, rect_pos(3), rect_pos(4), currentLineWidth);
    end
    Screen('DrawLine', wPtr, fixColor, xcenter-10, ycenter, xcenter+10, ycenter, 2);
    Screen('DrawLine', wPtr, fixColor, xcenter, ycenter-10, xcenter, ycenter+10, 2);
    Screen('Flip', wPtr); WaitSecs(0.24);
end
           
            % Search display (third display - same as original)
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
            Practice_ColorSingletonIndex = [Practice_ColorSingletonIndex; color_singleton_index];
            if flicker_singleton_code == 1
                Practice_FlickerSingletonIndex = [Practice_FlickerSingletonIndex; flicker_singleton_index];
            else
                Practice_FlickerSingletonIndex = [Practice_FlickerSingletonIndex; NaN];
            end
            Practice_ColorSingleton = [Practice_ColorSingleton; color_singleton_code];
            Practice_FlickerSingleton = [Practice_FlickerSingleton; flicker_singleton_code];
            Practice_ResponseKey = [Practice_ResponseKey; {resp}];
            Practice_feedback = [Practice_feedback; isCorrect];
            Practice_searchRT = [Practice_searchRT; RT];
           
            Practice_NumItems = [Practice_NumItems; num_items];
            Practice_SetSize = [Practice_SetSize; set_size_code];
        end% End of practice trial loop
     
        % SAVE PRACTICE DATA and CHECK PERFORMANCE
        practice_filename = sprintf('Practice_Results_%s_%s.csv', subj_name, subj_id);
        practice_data_table = table(Practice_TrialNo, Practice_TargetIndex, Practice_ColorSingletonIndex, ...
                               Practice_FlickerSingletonIndex, Practice_ColorSingleton, Practice_FlickerSingleton, ...
                               Practice_ResponseKey, Practice_feedback, Practice_searchRT, Practice_SetSize);
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
        fprintf('Practice trials completed. Check the results file: %s\n', practice_filename);
        fprintf('Run the script again to start the main experiment.\n');
        return;
    end
    
    % MAIN EXPERIMENT INSTRUCTIONS (Always shown before main experiment)
    main_experiment_instructions = ['Main Experiment - 432 Trials\n\n'...
                                  'You will now begin the main experiment.\n\n'...
                                  'ERROR TRIALS WILL BE REPEATED UNTIL ALL 432 TRIALS ARE CORRECT.\n\n'...
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
 
     % MAIN EXPERIMENT LOOP WITH ERROR REPETITION
    trial = 1;
    completed_trials = 0;
    trials_attempted=0;
    
    while completed_trials < 432
        trials_attempted=trials_attempted+1;
        % Check for break every 72 completed trials
        if mod(trials_attempted, 72) == 0 && trials_attempted > 0
            break_text = sprintf('Break time!\n\nYou have attempted %d  trials.\nCorrect trials completed: %d\n\nTake a 30-second rest.\n\nThe experiment will continue automatically.',trials_attempted, completed_trials);
            DrawFormattedText(wPtr, break_text, 'center', 'center', [255 255 255]);
            Screen('Flip', wPtr);
            
            % 30-second countdown
            for countdown = 30:-1:1
                countdown_text = sprintf('Break time!\n\nYou have attempted %d  trials.\nCorrect trials completed: %d\n\nTake a 30-second rest.\n\nResuming in: %d seconds', trials_attempted,completed_trials, countdown);
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
        current_trial_index = mod(completed_trials, N) + 1; % Cycle through conditions if needed
        color_singleton_code = conds.ColorSingleton(current_trial_index);  % 0=target, 1=non-target
        flicker_singleton_code = conds.FlickerSingleton(current_trial_index);  % 0=absent, 1=present
        set_size_code = conds.SetSize(current_trial_index);                % 0=6 items, 1=12 items
       
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
 
        % Determine target index (always present)
        target_index = randi(num_items);
        
        % Determine color singleton index
        if color_singleton_code == 0 % Color singleton is target
            color_singleton_index = target_index;
        else % Color singleton is non-target
            opts = setdiff(1:num_items, target_index);
            color_singleton_index = opts(randi(length(opts)));
        end
        
        % Determine shape singleton index (if present)
            if flicker_singleton_code == 1 % Shape singleton present
                % Shape singleton should not be the target
                opts = setdiff(1:num_items, target_index);
               % shape_singleton_index = opts(randi(length(opts)));
                %adjacent_positions=[mod(color_singleton_index-2,num_items)+1,...
                                    %mod(color_singleton_index,num_items)+1];
                if color_singleton_index==1
                    adjacent_positions=[num_items,2];
                elseif color_singleton_index==num_items
                    adjacent_positions=[num_items-1,1];
                else
                    adjacent_positions=[color_singleton_index-1,color_singleton_index+1];
                end
                opts=setdiff(opts,[adjacent_positions,color_singleton_index]);
                if ~isempty(opts)
                    flicker_singleton_index=opts(randi(length(opts)));
                else
                    all_opts=setdiff(1:num_items,[target_index,flicker_singleton_index]);
                    if ~isempty(all_opts)
                        color_singleton_index=all_opts(randi(length(all_opts)));
                    else
                        all_opts=setdiff(1:num_items,target_index);
                        color_singleton_index=all_opts(randi(length(all_opts)));
                        warning('Could not maintain adjacency constraing-very rare edge case');
                    end
                end
            else % Shape singleton absent
                flicker_singleton_index = -1;
            end
 
        % Fixation
        Screen('FillRect', wPtr, 0);
        Screen('DrawLine', wPtr, fixColor, xcenter-10, ycenter, xcenter+10, ycenter, 2);
        Screen('DrawLine', wPtr, fixColor, xcenter, ycenter-10, xcenter, ycenter+10, 2);
        Screen('Flip', wPtr); WaitSecs(0.15);
 
        % First Placeholder display (only corner brackets - all white)
        Screen('FillRect', wPtr, 0);
        for j = 1:num_items
            col = [255 255 255]; % All white in first display
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
 
  % Second Placeholder display - alternating pattern if shape singleton present
if flicker_singleton_code == 1
    % Alternating display: shape singleton (60ms) -> corners (60ms) -> shape singleton (60ms) -> corners (60ms)
    for cycle = 1:2
        % First: Shape singleton display (60ms)
        Screen('FillRect', wPtr, 0);
        for j = 1:num_items
            if j == color_singleton_index
                col = [255 0 0]; % Red for color singleton
                currentLineWidth = thickLineWidth;
            else
                col = [255 255 255]; % White for others
                currentLineWidth = lineWidth;
            end
            
            rect_pos = positions(j,:);
            
            if j == flicker_singleton_index
                % Draw diamond-shaped corners for shape singleton
                cornerSize = 10;
                rect_center_x = (rect_pos(1) + rect_pos(3)) / 2;
                rect_center_y = (rect_pos(2) + rect_pos(4)) / 2;
                
                % Top diamond
                top_x = rect_center_x;
                top_y = rect_pos(2) - cornerSize;
                Screen('DrawLine', wPtr, col, top_x - cornerSize/2, top_y + cornerSize/2, top_x, top_y, LineWidth2);
                Screen('DrawLine', wPtr, col, top_x, top_y, top_x + cornerSize/2, top_y + cornerSize/2, LineWidth2);
                
                % Right diamond
                right_x = rect_pos(3) + cornerSize;
                right_y = rect_center_y;
                Screen('DrawLine', wPtr, col, right_x - cornerSize/2, right_y - cornerSize/2, right_x, right_y, LineWidth2);
                Screen('DrawLine', wPtr, col, right_x, right_y, right_x - cornerSize/2, right_y + cornerSize/2, LineWidth2);
                
                % Bottom diamond
                bottom_x = rect_center_x;
                bottom_y = rect_pos(4) + cornerSize;
                Screen('DrawLine', wPtr, col, bottom_x - cornerSize/2, bottom_y - cornerSize/2, bottom_x, bottom_y, LineWidth2);
                Screen('DrawLine', wPtr, col, bottom_x, bottom_y, bottom_x + cornerSize/2, bottom_y - cornerSize/2, LineWidth2);
                
                % Left diamond
                left_x = rect_pos(1) - cornerSize;
                left_y = rect_center_y;
                Screen('DrawLine', wPtr, col, left_x + cornerSize/2, left_y - cornerSize/2, left_x, left_y, LineWidth2);
                Screen('DrawLine', wPtr, col, left_x, left_y, left_x + cornerSize/2, left_y + cornerSize/2, LineWidth2);
            else
                % Regular corner brackets
                cornerSize = 10;
                Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(2), rect_pos(1)+cornerSize, rect_pos(2), currentLineWidth);
                Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(2), rect_pos(1), rect_pos(2)+cornerSize, currentLineWidth);
                Screen('DrawLine', wPtr, col, rect_pos(3)-cornerSize, rect_pos(2), rect_pos(3), rect_pos(2), currentLineWidth);
                Screen('DrawLine', wPtr, col, rect_pos(3), rect_pos(2), rect_pos(3), rect_pos(2)+cornerSize, currentLineWidth);
                Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(4)-cornerSize, rect_pos(1), rect_pos(4), currentLineWidth);
                Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(4), rect_pos(1)+cornerSize, rect_pos(4), currentLineWidth);
                Screen('DrawLine', wPtr, col, rect_pos(3)-cornerSize, rect_pos(4), rect_pos(3), rect_pos(4), currentLineWidth);
                Screen('DrawLine', wPtr, col, rect_pos(3), rect_pos(4)-cornerSize, rect_pos(3), rect_pos(4), currentLineWidth);
            end
        end
        Screen('DrawLine', wPtr, fixColor, xcenter-10, ycenter, xcenter+10, ycenter, 2);
        Screen('DrawLine', wPtr, fixColor, xcenter, ycenter-10, xcenter, ycenter+10, 2);
        Screen('Flip', wPtr); WaitSecs(0.06);
        
        % Second: Corner brackets only (60ms)
        Screen('FillRect', wPtr, 0);
        for j = 1:num_items
            if j == color_singleton_index
                col = [255 0 0]; % Red for color singleton
                currentLineWidth = thickLineWidth;
            else
                col = [255 255 255]; % White for others
                currentLineWidth = lineWidth;
            end
            
            rect_pos = positions(j,:);
            
            % All items show regular corner brackets
            cornerSize = 10;
            Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(2), rect_pos(1)+cornerSize, rect_pos(2), currentLineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(2), rect_pos(1), rect_pos(2)+cornerSize, currentLineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(3)-cornerSize, rect_pos(2), rect_pos(3), rect_pos(2), currentLineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(3), rect_pos(2), rect_pos(3), rect_pos(2)+cornerSize, currentLineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(4)-cornerSize, rect_pos(1), rect_pos(4), currentLineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(4), rect_pos(1)+cornerSize, rect_pos(4), currentLineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(3)-cornerSize, rect_pos(4), rect_pos(3), rect_pos(4), currentLineWidth);
            Screen('DrawLine', wPtr, col, rect_pos(3), rect_pos(4)-cornerSize, rect_pos(3), rect_pos(4), currentLineWidth);
        end
        Screen('DrawLine', wPtr, fixColor, xcenter-10, ycenter, xcenter+10, ycenter, 2);
        Screen('DrawLine', wPtr, fixColor, xcenter, ycenter-10, xcenter, ycenter+10, 2);
        Screen('Flip', wPtr); WaitSecs(0.06);
    end
else
    % No shape singleton - single display (240ms)
    Screen('FillRect', wPtr, 0);
    for j = 1:num_items
        if j == color_singleton_index
            col = [255 0 0]; % Red for color singleton
            currentLineWidth = thickLineWidth;
        else
            col = [255 255 255]; % White for others
            currentLineWidth = lineWidth;
        end
        
        rect_pos = positions(j,:);
        
        % Regular corner brackets only
        cornerSize = 10;
        Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(2), rect_pos(1)+cornerSize, rect_pos(2), currentLineWidth);
        Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(2), rect_pos(1), rect_pos(2)+cornerSize, currentLineWidth);
        Screen('DrawLine', wPtr, col, rect_pos(3)-cornerSize, rect_pos(2), rect_pos(3), rect_pos(2), currentLineWidth);
        Screen('DrawLine', wPtr, col, rect_pos(3), rect_pos(2), rect_pos(3), rect_pos(2)+cornerSize, currentLineWidth);
        Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(4)-cornerSize, rect_pos(1), rect_pos(4), currentLineWidth);
        Screen('DrawLine', wPtr, col, rect_pos(1), rect_pos(4), rect_pos(1)+cornerSize, rect_pos(4), currentLineWidth);
        Screen('DrawLine', wPtr, col, rect_pos(3)-cornerSize, rect_pos(4), rect_pos(3), rect_pos(4), currentLineWidth);
        Screen('DrawLine', wPtr, col, rect_pos(3), rect_pos(4)-cornerSize, rect_pos(3), rect_pos(4), currentLineWidth);
    end
    Screen('DrawLine', wPtr, fixColor, xcenter-10, ycenter, xcenter+10, ycenter, 2);
    Screen('DrawLine', wPtr, fixColor, xcenter, ycenter-10, xcenter, ycenter+10, 2);
    Screen('Flip', wPtr); WaitSecs(0.24);
end
           
 
 % Search display (third display)
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
 RT = NaN;
 
 while GetSecs - tStart < timeLimit
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
 end
 
 % Check if time elapsed
 if isempty(resp)
 timedOut = true;
 resp = 'timeout';
 RT = NaN;
 DrawFormattedText(wPtr, 'Time elapsed!\n\nTrial will be repeated.', 'center', 'center', [255 255 0]);
 Screen('Flip', wPtr);
 WaitSecs(1);
 isCorrect = false;
 else
 correctResp = target_gap_side;
 isCorrect = strcmp(resp, correctResp);
   % Feedback
   if isCorrect
       feedback_text = 'Correct!';
       feedback_color = [0 255 0];
       DrawFormattedText(wPtr, feedback_text, 'center', 'center', feedback_color);
       Screen('Flip', wPtr); WaitSecs(1);
   end
 end
 
 % Only store data and advance if response was correct
 if isCorrect
 completed_trials = completed_trials + 1;
 
 % Store trial data
 Subj = [Subj; string(subj_name)];
 TrialNo = [TrialNo; completed_trials];
 TargetIndex = [TargetIndex; target_index];
 ColorSingletonIndex = [ColorSingletonIndex; color_singleton_index];
 if flicker_singleton_code == 1
 FlickerSingletonIndex = [FlickerSingletonIndex; flicker_singleton_index];
 else
 FlickerSingletonIndex = [FlickerSingletonIndex; NaN];
 end
 ColorSingleton = [ColorSingleton; color_singleton_code];
 FlipperSingleton = [FlipperSingleton; flicker_singleton_code];
 ResponseKey = [ResponseKey; {resp}];
 feedback = [feedback; isCorrect];
 searchRT = [searchRT; RT];
 
 NumItems = [NumItems; num_items];
 SetSize = [SetSize; set_size_code];
 
 % Save data every 50 correct trials
 if mod(completed_trials, 50) == 0
 data_table = table(Subj, TrialNo, TargetIndex, ColorSingletonIndex, ...
 FlickerSingletonIndex, ColorSingleton, FlipperSingleton, ...
 ResponseKey, feedback, searchRT, SetSize);
 writetable(data_table, filename);
 fprintf('Progress saved: %d/%d trials completed\n', completed_trials, 540);
 end
 else
 % Incorrect response - show error message and repeat trial
 if ~timedOut
 DrawFormattedText(wPtr, 'Incorrect!\n\nTrial will be repeated.', 'center', 'center', [255 0 0]);
 Screen('Flip', wPtr);
 WaitSecs(1);
 end
 end
 
 trial = trial + 1;
 
 % Brief inter-trial interval
 Screen('FillRect', wPtr, 0);
 Screen('Flip', wPtr);
 WaitSecs(0.5);
 
 end % End of main experiment while loop
 
 % FINAL DATA SAVE
 data_table = table(TrialNo, TargetIndex, ColorSingletonIndex, ...
 FlickerSingletonIndex, ColorSingleton, FlipperSingleton, ...
 ResponseKey, feedback, searchRT, SetSize);
 writetable(data_table, filename);
 
 % Calculate final performance statistics
 final_accuracy = sum(feedback) / length(feedback) * 100;
 mean_RT = mean(searchRT(feedback == 1)); % RT for correct trials only
 
 % End screen
 end_text = sprintf('Experiment Complete!\n\nThank you for participating!\n\nYour Performance:\nAccuracy: %.1f%%\nMean RT: %.2f ms\n\nTotal trials attempted: %d\nCorrect trials completed: %d\n\nPress any key to exit.', ...
 final_accuracy, mean_RT, trial, completed_trials);
 
 DrawFormattedText(wPtr, end_text, 'center', 'center', [255 255 255]);
 Screen('Flip', wPtr);
 KbStrokeWait;
 
 % Cleanup
 sca;
 ShowCursor;
 
 fprintf('\nExperiment completed successfully!\n');
 fprintf('Results saved to: %s\n', filename);
 fprintf('Total trials attempted: %d\n', trial);
 fprintf('Correct trials completed: %d\n', completed_trials);
 fprintf('Final accuracy: %.1f%%\n', final_accuracy);
 fprintf('Mean RT (correct trials): %.2f ms\n', mean_RT);
 
catch ME
 % Error handling
 sca;
 ShowCursor;
 fprintf('\nError occurred: %s\n', ME.message);
 fprintf('Line: %s\n', ME.stack(1).name);
 fprintf('File: %s, Line %d\n', ME.stack(1).file, ME.stack(1).line);
 
 % Try to save any collected data
 if exist('Subj', 'var') && ~isempty(Subj)
 emergency_filename = sprintf('Emergency_Save_%s_%s.csv', subj_name, subj_id);
 try
 data_table = table(TrialNo, TargetIndex, ColorSingletonIndex, ...
 FlickerSingletonIndex, ColorSingleton, FlipperSingleton, ...
 ResponseKey, feedback, searchRT,ColorSingletonIsTarget, SetSize);
 writetable(data_table, emergency_filename);
 fprintf('Emergency data save completed: %s\n', emergency_filename);
 catch
 fprintf('Could not save emergency data\n');
 end
 end
 
 rethrow(ME);
end
