# 100 Paper cuts

## Summary

This is a project lovingly evocating Ubuntu's 100 paper cuts, with the idea of fixing small issues that bother a lot. We don't have 100 paper cuts, but we do hame a few nasty annoyances that can make life better.

- Some concern separation is due to prevent the spahettification of the project.

- A refactor is also due, where some code can be elegantly reutilized.

- Project is using .bash_functions, which is a custom implementation for the developer. This won't exist anywhere else, so the idea is to make .bashrc source another script where to put work manager's shenanigans (akin to bash_functions), not messing with user's infrastructure/implementation.

- Project is not only .bash_functions, but leaves tons of backups, and backups of backups. Not tolerable.

- I think that same goes to the prompt backup (tons of backups, and backups of backups)

- When uninstalling, work directory (namely $HOME/.local/work) is left full of crap, without even noticing the user. It would be interesting to ask the user to clean up the mess automatically, or at least let the user knowthe situation.

- When installing, the y/n prompt defaults to N, preventing the user to install just by hitting enter:

```
$ ./setup.sh install
Work Manager Installation
========================

Where should the database be stored?
Database path (default: /home/pega/.local/work/timelog.db): 

Directory does not exist: /home/pega/.local/work
Create directory '/home/pega/.local/work'? (y/N): 
Installation aborted.
```

- Same goes for the bin/ directory. I'm not sure what will happen if the directory doesn't exist.

- `work status` should include time elapsed on the current status.

- Prompt should be updated. How does virtualenv do then? (alright, this one might be a wild piece of engineering). 

```
pega@temple:~$ work on something
Started work on: something
Tip: Run 'update-prompt' to update the current terminal prompt
pega@temple:~$
```

Ideas:
    1. alias work='. $(work)'. That will keep the prompt in the current environment. Major pitfall: An uncatched -e event or a random exit will kill current bash session
    2. bash function (and/or a command) launching a subterminal. Harnessing the spirit of the solution above, without its downside (i.e. terminal dies, then the subterminal dies. Even work off might mean "let's exit this terminal and go back to the previous one). Major pitfall: Flight-engineering-grade solution.
    3. alias but without -e catches, so nothing breaks _so_ bad, and getting rid of all exit statements. Downside: some control might get lost, compromising the behavior of the whole script.
    4. moving the whole application to a work function. This means a major reingeneering, but this always works flawlessly:

```
pega@temple:~$ function newprompt(){ export old_PS1=$PS1; PS1="testing my PS1: $PS1"   ; export PS1;}
pega@temple:~$ function oldprompt(){ export PS1=$old_PS1; }
pega@temple:~$ newprompt 
testing my PS1: pega@temple:~$ oldprompt 
pega@temple:~$ 
```

- `update-prompt` is missing on a clean installation:

```
pega@temple:~/dev/personal/work-manager$ work off
Stopped work on: testing1 (Duration: 1 min)
Tip: Run 'update-prompt' to update the current terminal prompt
pega@temple:~/dev/personal/work-manager$ update-prompt
update-prompt: command not found
pega@temple:~/dev/personal/work-manager$ which work
/home/pega/.local/bin/work
whpega@temple:~/dev/personal/work-manager$ which update-prompt
pega@temple:~/dev/personal/work-manager$ whereis update-prompt
update-prompt:
pega@temple:~/dev/personal/work-manager$
```
