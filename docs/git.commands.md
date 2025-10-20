# Git Commands

Common Git commands and configuration examples:

```py title="clone repo" linenums="1"
# Clone a repository
git clone <repo-url>
```

```py title="set user" linenums="1"
# Configure user info
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

```py title="repo info" linenums="1"
# Check status and changes
git status
git diff
```

```py title="stage repo and commit" linenums="1"
# Stage and commit changes
git add <file>
git commit -m "Commit message"
git commit --amend --reset-author --no-edit
```

```py title="push repo" linenums="1"
# Push changes to remote
git push origin main
git push origin master
```

```py title="check config" linenums="1"
# View Git configuration
git config --list
```

```py title="git command history" linenums="1"
# Search command history for Git commands
history | grep git
```
