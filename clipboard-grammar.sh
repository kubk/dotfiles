#!/bin/bash

set -u

# Resolve symlinks so the config is loaded beside the real script, not its launcher.
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

# Load environment variables from .env file
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/.env"
    set +a
else
    echo "Error: .env file not found in $SCRIPT_DIR"
    exit 1
fi

AI_GATEWAY_BASE_URL="https://ai-gateway.vercel.sh/v1"

show_error() {
    osascript -e "display notification \"$1\" with title \"Grammar Fix Error\" sound name \"Basso\""
    exit 1
}

if [ -z "${AI_GATEWAY_API_KEY:-}" ]; then
    show_error "AI_GATEWAY_API_KEY is not set"
fi

# Get the selected text from clipboard
selected_text=$(pbpaste)

# Check if there's any text selected
if [ -z "$selected_text" ]; then
    show_error "No text selected"
fi

system_prompt="You are a light-touch English copy editor. Correct only grammar, spelling, punctuation, and clearly incorrect word choices. Preserve the exact meaning, every sentence, informal tone, contractions, line breaks, capitalization, and formatting. Do not add, remove, summarize, or explain anything. Return only the corrected text, without quotes or markup."
request_body=$(jq -n \
    --arg system_prompt "$system_prompt" \
    --arg selected_text "$selected_text" \
    '{
        model: "deepseek/deepseek-v4-flash-0731",
        max_tokens: 2048,
        reasoning: {
            effort: "none"
        },
        messages: [
            {
                role: "system",
                content: $system_prompt
            },
            {
                role: "user",
                content: ("<text>\n" + $selected_text + "\n</text>")
            }
        ],
        providerOptions: {
            gateway: {
                sort: "ttft"
            }
        }
    }')

# Make API call through Vercel AI Gateway's OpenAI-compatible API
response=$(curl -sS --connect-timeout 5 --max-time 30 -w '\n%{http_code}' "$AI_GATEWAY_BASE_URL/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $AI_GATEWAY_API_KEY" \
    -d "$request_body")
curl_status=$?

if [ "$curl_status" -ne 0 ]; then
    show_error "Request failed"
fi

http_status="${response##*$'\n'}"
response_body="${response%$'\n'*}"

if [ "$http_status" -lt 200 ] || [ "$http_status" -ge 300 ]; then
    error_message=$(echo "$response_body" | jq -r '.error.message // .message // "HTTP error"')
    show_error "$error_message"
fi

# Check if the response contains an error
if echo "$response_body" | jq -e '.error' > /dev/null; then
    error_message=$(echo "$response_body" | jq -r '.error.message // "API error"')
    show_error "$error_message"
fi

# Extract content and copy to clipboard
fixed_text=$(echo "$response_body" | jq -er '.choices[0].message.content // empty') || show_error "No fixed text returned"
echo "$fixed_text" | pbcopy

# Show success notification
osascript -e "display notification \"Text has been fixed and copied to clipboard\" with title \"Grammar Fix\" sound name \"Glass\""
