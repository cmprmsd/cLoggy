# cLoggy Cheatsheet

### General

| Alias       | Command            | Description                                                  |
| ----------- | ------------------ | ------------------------------------------------------------ |
| **General** |                    |                                                              |
| sc          | setCustomer        | Permanent customer selection. This persists through the creation of new terminals |
| tc          | tempCustomer       | Temporary customer selection. This does only apply to the current zsh terminal. Starting a new terminal will load the last permanent customer from the `.customer` file in your home location. |
| delcu       | deleteCustomer     | Delete the specified customer (`delcu customerF`)            |
| cback       |                    | Switch back to the last permanent customer                   |
| cs          |                    | Clear the terminal screen and load the motd                  |
| cc          |                    | Switch to the customer home folder                           |
| cl          |                    | Add a comment to the currently active project into the `timeline.log`. This prepends the current date and time as well as your initials to the comment. |
| co          | pickColor          | Choose the background color for the current customer         |
| hist        | grep magic         | Search through all customer history files and output the search command (e.g. `hist ps`) |
| here        | path based history | This function does show the history file for the current folder. All history files are saved to `$HOME/.zsh_history.d/$PWD/history` regardless which customer is active. |

### Firejail

| Alias            | Command | Description                                                  |
| ---------------- | ------- | ------------------------------------------------------------ |
| firefox          |         | This command starts firefox in a firejail in order to have a unique firefox instance for each customer. |
| fireEditTemplate |         | Used to edit the template (add new certificates e.g.)        |

### Taskwarrior


| Alias | Command                 | Description                                                  |
| ----- | ----------------------- | ------------------------------------------------------------ |
| c     | ctask                   | Main taskwarrior command to interact with the customer instance |
| a     | ctask add               | Add a new item to ctask                                      |
| d     | ctask del               | Delete an item from ctask                                    |
| f     | ctask add "file://${@}" | Add a file link to ctask (clickable in most terminals)       |

### Typora

| Alias | Command                                              | Description                                                  |
| ----- | ---------------------------------------------------- | ------------------------------------------------------------ |
| note  | `typora $HOME/customer/$customer/markdown-$customer` | Open Typora in the currently active customer markdown project folder. |
