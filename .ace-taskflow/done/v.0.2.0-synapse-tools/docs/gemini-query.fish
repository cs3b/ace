# dotfiles/fish/functions-cs3b/gemini-query.fish
function gemini-query
    # Parse system, model and debug options
    argparse 's/system=' 'm/model=' 'd/debug' -- $argv

    # --- API Key ---
    # Look for .env in the same directory as this script
    set -l script_dir (dirname (status --current-filename))
    set -l env_file "$script_dir/.env"

    if test -f "$env_file"
        source "$env_file" # Expects: set -gx GEMINI_API_KEY "YOUR_KEY" in the .env file
    end

    if not set -q GEMINI_API_KEY; or test -z "$GEMINI_API_KEY"
        echo "Error: GEMINI_API_KEY is not set or empty." >&2
        echo "Please create or check '$env_file' and add a line like:" >&2
        echo 'set -gx GEMINI_API_KEY "YOUR_API_KEY_HERE"' >&2
        return 1
    end

    # --- System Message ---
    set -l system_message
    if set -q _flag_system
        set system_message $_flag_system
    else
        # Default system message, can be adjusted
        set system_message "You are a helpful assistant. Please provide concise and informative responses."
    end

    # --- Model ---
    set -l model "gemini-2.0-flash-lite" # Default to Gemini 2.0 Flash
    if set -q _flag_model
        set model $_flag_model
    end

    # --- User Prompt ---
    set -l user_prompt
    if test (count $argv) -eq 0
        set user_prompt (pbpaste)
    else
        set user_prompt (string join " " $argv)
    end
    set user_prompt (string trim "$user_prompt")

    if test -z "$user_prompt"
        echo "Error: User prompt is empty. Provide a prompt as an argument or copy it to the clipboard." >&2
        return 1
    end

    # --- API URL ---
    set -l api_url "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$GEMINI_API_KEY"

    # --- JSON Payload ---
    # Base structure for the request
    set -l base_payload_jq_string '{
        contents: [ {role: "user", parts: [ {text: $user_prompt_arg} ] } ],
        generationConfig: { temperature: 0.7, maxOutputTokens: 8192 }
    }'

    # Conditionally add systemInstruction if system_message is provided
    set -l data
    if test -n "$system_message"
        set data (jq -n \
            --arg user_prompt_arg "$user_prompt" \
            --arg system_message_arg "$system_message" \
            "
            ($base_payload_jq_string)
            +
            {systemInstruction: {parts: [{text: \$system_message_arg}]}}
            "
        )
    else
        set data (jq -n \
            --arg user_prompt_arg "$user_prompt" \
            "$base_payload_jq_string"
        )
    end


    # --- Debug ---
    if set -q _flag_debug
        echo "Sending query to Gemini API ($model):" >&2
        echo "URL: $api_url" >&2
        echo "Payload:" >&2
        echo $data | jq '.' >&2
        echo "---" >&2
    end

    # --- Curl Request ---
    set -l result (curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$data" \
        "$api_url")
    set -l curl_status $status

    # --- Response Handling ---
    if test $curl_status -ne 0
        echo "Error: curl command failed with status $curl_status." >&2
        if test -n "$result"; echo "Curl output (if any): $result" >&2; end
        return 1
    end

    # Attempt to parse the response for content or error
    set -l output_content (echo $result | jq -r '
        if .candidates and .candidates[0] and .candidates[0].content and .candidates[0].content.parts and .candidates[0].content.parts[0] and .candidates[0].content.parts[0].text then
            .candidates[0].content.parts[0].text
        elif .error and .error.message then
            ("API Error: " + .error.message)
        else
            ("Error: Could not parse response or unexpected format.")
        end
    ')
    set -l jq_status $status

    if test $jq_status -ne 0; or string match -q "Error:*" "$output_content"; or string match -q "API Error:*" "$output_content"
        echo "$output_content" >&2
        if set -q _flag_debug
            echo "Full API response for debugging:" >&2
            echo $result | jq '.' >&2
        end
        return 1
    end

    echo "$output_content" | string collect
end