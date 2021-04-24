### Overview
Vim plugin to search and replace a pattern across multiple files interactively.

To search and replace a pattern in multiple files, you invoke a command
supplied by this plugin with the search pattern. The plugin displays the lines
containing the specified pattern in one or more specified files in a Vim
buffer. You can use the Vim editing commands to make modifications to this
buffer. To incorporate the changes back to the corresponding files, you now
invoke a plugin command. This plugin allows you to make multiple modifications
across several files in a single pass.

You can also use this plugin with other plugins that populate the quickfix
list with search results.

### Usage
1. Populate the Vim quickfix list using one of the built-in Vim commands like :grep or :vimgrep or using the :Gsearch command or using a command provided by a plugin.
2. Open the quickfix items in a buffer using the :Gqfopen command.
3. Modify/edit the buffer using the regular Vim commands.
4. Merge the changes back to the files using the :Greplace command.
5. Save all the files using the ':bufdo update' command.
