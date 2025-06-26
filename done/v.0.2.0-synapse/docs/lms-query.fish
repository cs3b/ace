function lms-query
    # Parse system, model and debug options
    argparse 's/system=' 'm/model=' 'd/debug' -- $argv

    # Set the prompts directory
    set prompts_dir "$HOME/dotfiles/prompts"

    # If the flag was provided, check if it's an XML path/alias
    if set -q _flag_system
        if string match -q "xml:*" $_flag_system
            set system_message (lms-query-load-from-file $_flag_system)
            if test $status -ne 0
                return 1
            end
        else
            set system_message $_flag_system
        end
    else
        set system_message "You are an assistant that generates concise and informative responses. Only output the response message without any additional commentary."
    end

    # Rest of the function remains the same
    if set -q _flag_model
        set model $_flag_model
    else
        set model "mistral-small-24b-instruct-2501@8bit"
    end

    # Use arguments if provided, otherwise use clipboard content
    if test (count $argv) -eq 0
        set user_prompt (pbpaste)
    else
        set user_prompt (string join " " $argv)
    end
    set user_prompt (string trim $user_prompt)
    set prompt_json (echo "$user_prompt" | jq -Rs .)

    # Escape system message for JSON
    set system_message_json (echo $system_message | jq -Rs .)

    set data "{
    \"model\": \"$model\",
      \"messages\": [
        { \"role\": \"system\", \"content\": $system_message_json },
        { \"role\": \"user\", \"content\": $prompt_json }
      ],
      \"temperature\": 0.7,
      \"max_tokens\": -1,
      \"stream\": false
    }"

    # Pretty print the query for logging if debug is enabled
    if set -q _flag_debug
        echo "Sending query to LMS:"
        echo $data | jq '.'
        echo "---"
    end
    set result (curl -s http://localhost:1234/v1/chat/completions \
      -H "Content-Type: application/json" \
      -d "$data")

      # Use jq with raw output (-r) to get clean content without extra formatting
      echo $result | jq -r '.choices[0].message.content' | string collect
end
