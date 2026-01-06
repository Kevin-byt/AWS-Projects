#!/usr/bin/env python3
"""
Auto Commit - AI-powered Git Commit Message Generator

This script uses AI to generate meaningful commit messages based on git diffs.
It follows conventional commit format and provides various configuration options.
"""

import subprocess
import os
import sys
import argparse
import tempfile
import itertools
import threading
import time
import logging
from pathlib import Path

# Default configuration
MODEL_NAME = "openai/gpt-4.1"  # Alternative: 'mistral-ai/codestral-2501'
COMMIT_MESSAGE_PROMPT = """
Write a meaningful commit message in the conventional commit convention by trying to understand 
what was the benefits the code author wanted to add by his changes to codebase with this commit. 
I'll send you an output of 'git diff --staged' command, and you convert it into a commit message. 

Requirements:
- Lines must not be longer than 74 characters. 
- Use EN language to answer. 
- Try to use line breaks, only after a dot, to help making the commit message easier to read..
- Use bullet points to list the changes (do not mention filename extensions).
- Follow the bullet points with a single sentence explaining the necessity of these changes.
- Be brief and concise throughout.
- Output only the commit message."""


def setup_logging():
    """Set up logging for the script."""
    log_dir = os.path.expanduser("~/.autocommit")
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)
        
    logging.basicConfig(
        filename=os.path.join(log_dir, "autocommit.log"),
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )
    
    return logging.getLogger("autocommit")
    

def load_config():
    """Load configuration from .autocommit.yaml if it exists."""
    try:
        import yaml
    except ImportError:
        print("PyYAML not installed. Using default configuration.")
        return {
            "model": MODEL_NAME,
            "prompt": COMMIT_MESSAGE_PROMPT,
            "auto_push": False,
            "allow_edit": True
        }
    
    config_path = os.path.expanduser("~/.autocommit.yaml")
    default_config = {
        "model": MODEL_NAME,
        "prompt": COMMIT_MESSAGE_PROMPT,
        "auto_push": False,
        "allow_edit": True
    }
    
    if os.path.exists(config_path):
        try:
            with open(config_path, 'r') as f:
                config = yaml.safe_load(f)
                return {**default_config, **(config or {})}
        except Exception as e:
            print(f"Error loading config: {e}")
    
    return default_config


def parse_arguments():
    """Parse command line arguments."""
    config = load_config()
    
    parser = argparse.ArgumentParser(description='Generate AI-powered commit messages')
    parser.add_argument('--model', type=str, default=config["model"],
                        help=f'AI model to use (default: {config["model"]})')
    parser.add_argument('--no-push', action='store_true',
                        help='Skip the push confirmation prompt')
    parser.add_argument('--edit', action='store_true', default=config["allow_edit"],
                        help='Allow editing the generated commit message')
    parser.add_argument('--help-config', action='store_true',
                        help='Show configuration help')
    return parser.parse_args()


def show_help_config():
    """Show configuration help information."""
    help_text = """
    Auto Commit - Configuration Help
    
    You can create a configuration file at ~/.autocommit.yaml with the following options:
    
    model: openai/gpt-4.1
    prompt: |
      Write a meaningful commit message in the conventional commit convention...
    auto_push: false
    allow_edit: true
    
    Example:
    ```yaml
    model: openai/gpt-3.5-turbo
    auto_push: true
    allow_edit: false
    ```
    """
    print(help_text)


def check_git_repo():
    """Check if the current directory is a git repository."""
    try:
        subprocess.run(['git', 'rev-parse', '--is-inside-work-tree'], 
                      check=True, capture_output=True, text=True)
        return True
    except subprocess.CalledProcessError:
        print("Error: Not a git repository. Please run from a git repository.")
        return False


def show_spinner(message):
    """Show a spinner while waiting for a process."""
    spinner = itertools.cycle(['-', '/', '|', '\\'])
    stop_spinner = False
    
    def spin():
        sys.stdout.write(message)
        while not stop_spinner:
            sys.stdout.write(next(spinner))
            sys.stdout.flush()
            time.sleep(0.1)
            sys.stdout.write('\b')
        sys.stdout.write(' Done!\n')
    
    spinner_thread = threading.Thread(target=spin)
    spinner_thread.start()
    
    def stop():
        nonlocal stop_spinner
        stop_spinner = True
        spinner_thread.join()
    
    return stop


def get_git_diff():
    """Get git diff of only staged changes."""
    try:
        # Check if there are any staged changes to commit
        status = subprocess.run(['git', 'status', '--porcelain'],
                               capture_output=True,
                               text=True,
                               check=True)
        
        if not status.stdout.strip():
            print("No changes to commit.")
            return None
            
        # Get only staged diffs
        result = subprocess.run(['git', 'diff', '--staged', '--minimal'],
                                capture_output=True,
                                text=True,
                                check=True)
        
        if not result.stdout.strip():
            print("No staged changes to commit. Use 'git add' to stage changes.")
            return None
            
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"Error getting git diff: {str(e)}")
        return None


def get_commit_message(system_prompt, git_diff_output, model_name):
    """Generate commit message using AI model."""
    logger = logging.getLogger("autocommit")
    logger.info(f"Generating commit message using model: {model_name}")
    
    try:
        # Prepare prompt with git diff
        prompt = f'{system_prompt}"""{git_diff_output}"""'[:8000]
        
        # Show spinner while waiting for AI response
        stop_spinner = show_spinner("Generating commit message ")
        
        # Run GitHub CLI models
        result = subprocess.run(['gh', 'models', 'run', model_name],
                                input=prompt,
                                capture_output=True,
                                text=True,
                                check=True)
        
        # Stop spinner
        stop_spinner()
        
        return result.stdout.replace("```", "").strip()
    except subprocess.CalledProcessError as e:
        print(f"Error running gh models: {str(e)}")
        print(f"stderr: {e.stderr}")
        logger.error(f"Error with model {model_name}: {e.stderr}")
        
        # Fallback to simpler model if available
        if model_name != "openai/gpt-3.5-turbo":
            print("Trying fallback model...")
            logger.info("Falling back to gpt-3.5-turbo")
            return get_commit_message(system_prompt, git_diff_output, "openai/gpt-3.5-turbo")
        return None
    except FileNotFoundError as e:
        print(f"Error: GitHub CLI not found. Please install it with 'brew install gh' or visit https://cli.github.com/")
        logger.error(f"GitHub CLI not found: {e}")
        return None


def edit_commit_message(commit_message):
    """Allow user to edit the generated commit message."""
    # Create a temporary file with the commit message
    with tempfile.NamedTemporaryFile(suffix=".tmp", mode='w+', delete=False) as temp:
        temp.write(commit_message)
        temp_filename = temp.name
    
    # Get the default editor
    editor = os.environ.get('EDITOR', 'nano')
    
    # Open the editor with the temporary file
    try:
        subprocess.run([editor, temp_filename], check=True)
        
        # Read the edited message
        with open(temp_filename, 'r') as temp:
            edited_message = temp.read()
        
        # Clean up
        os.unlink(temp_filename)
        
        return edited_message
    except Exception as e:
        print(f"Error editing commit message: {e}")
        # Clean up in case of error
        if os.path.exists(temp_filename):
            os.unlink(temp_filename)
        return commit_message


def get_user_confirmation_for_commit(commit_message):
    """Ask user to confirm the commit message."""
    print(f"\nProposed commit message:\n{'-' * 50}\n{commit_message}\n{'-' * 50}")
    while True:
        response = input("\nDo you want to proceed with this commit (default y)? (y/n/e for edit): ").lower().strip()
        if response in ['y', 'n','']:
            return response in ['y',''], commit_message
        elif response == 'e':
            edited_message = edit_commit_message(commit_message)
            print(f"\nEdited commit message:\n{'-' * 50}\n{edited_message}\n{'-' * 50}")
            continue_response = input("\nProceed with this edited message? (y/n): ").lower().strip()
            if continue_response in ['y','']:
                return True, edited_message
            elif continue_response == 'n':
                return False, edited_message
        print("Please enter 'y' for yes, 'n' for no, or 'e' to edit.")


def get_user_confirmation_for_push():
    """Ask user to confirm pushing to remote."""
    while True:
        response = input("\nDo you want to push commit(s) to remote (default y)? (y/n): ").lower().strip()
        if response in ['y', 'n','']:
            return response in ['y','']
        print("Please enter 'y' for yes or 'n' for no.")


def main():
    """Main function."""
    # Set up logging
    logger = setup_logging()
    logger.info("Auto Commit started")
    
    # Parse arguments
    args = parse_arguments()
    
    # Show config help if requested
    if hasattr(args, 'help_config') and args.help_config:
        show_help_config()
        return
    
    # Check if we're in a git repo
    if not check_git_repo():
        logger.error("Not in a git repository")
        return
    
    # Get git diff
    git_diff_output = get_git_diff()
    if not git_diff_output:
        logger.info("No changes to commit")
        return

    try:
        # Generate commit message
        commit_message = get_commit_message(
            system_prompt=COMMIT_MESSAGE_PROMPT, 
            git_diff_output=git_diff_output,
            model_name=args.model
        )

        if not commit_message:
            print("Failed to generate commit message. Aborting.")
            logger.error("Failed to generate commit message")
            return
            
        # Ask for user confirmation
        proceed, final_message = get_user_confirmation_for_commit(commit_message)
        
        if proceed:
            # Proceed with git commit
            subprocess.run(['git', 'commit', '-m', final_message], check=True)
            print("Changes committed successfully!")
            logger.info("Commit successful")
            
            # Skip push prompt if --no-push was specified
            if not args.no_push and get_user_confirmation_for_push():
                subprocess.run(['git', 'push'], check=True)
                print("Changes pushed successfully!")
                logger.info("Push successful")
            elif not args.no_push:
                print("Git push cancelled by user.")
                logger.info("Push cancelled by user")
        else:
            print("Commit cancelled by user.")
            logger.info("Commit cancelled by user")

    except subprocess.CalledProcessError as e:
        print(f"Error during git operations: {e}")
        print(f"Error output: {e.stderr}")
        logger.error(f"Git operation error: {e.stderr}")


if __name__ == '__main__':
    main()