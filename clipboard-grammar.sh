#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load environment variables from .env file
if [ -f "$SCRIPT_DIR/.env" ]; then
    export $(cat "$SCRIPT_DIR/.env" | xargs)
else
    echo "Error: .env file not found in $SCRIPT_DIR"
    exit 1
fi

# Function to show error and exit
show_error() {
    osascript -e "display notification \"$1\" with title \"Grammar Fix Error\" sound name \"Basso\""
    exit 1
}

# Get the selected text from clipboard
selected_text=$(pbpaste)

# Check if there's any text selected
if [ -z "$selected_text" ]; then
    show_error "No text selected"
fi

# Escape the selected text for JSON using jq
prompt="Fix grammar of this text. Keep it informal and don't use advanced punctuation or abbreviations. Return ONLY the fixed text without any explanations or meta information: $selected_text"
prompt_escaped=$(echo "$prompt" | jq -R -s '.')

# Make API call to OpenAI
response=$(curl -s https://api.openai.com/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d "{
        \"model\": \"gpt-4\",
        \"messages\": [
            {
                \"role\": \"user\",
                \"content\": ${prompt_escaped}
            }
        ]
    }")

# Check if the response contains an error
if echo "$response" | jq -e '.error' > /dev/null; then
    error_message=$(echo "$response" | jq -r '.error.message')
    show_error "$error_message"
fi

# Extract content and copy to clipboard
echo "$response" | jq -r '.choices[0].message.content' | pbcopy

# Show success notification
osascript -e "display notification \"Text has been fixed and copied to clipboard\" with title \"Grammar Fix\" sound name \"Glass\""
