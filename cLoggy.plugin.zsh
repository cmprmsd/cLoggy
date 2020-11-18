####################################################
####################################################
# Complete Terminal Logging - cLoggy
# Author: Sebastian Haas - https://h8.to
####################################################
####################################################

# Aliases are optional and customizable but do not expect everything to work without them

## General
alias sc=setCustomer # set persistent customer
alias tc=tempCustomer # set temporary customer
alias co=pickColor # set new color alias
alias cl='echo $(date "+%Y-%m-%d-%H%M")-SH: ${1} >>! $HOME/customer/$customer/timeline.log'
alias cc='cd $HOME/customer/$customer/' # switch to the current customer "home" folder
alias cs="clear;loadModt" # clear screen
alias delcu="deleteCustomer"
here(){ cat "$HOME/.zsh_history.d/$PWD/history"; } # per folder history
hist() { stopLogging && GREP_COLOR='00;38;5;226' grep --color=always -i $1 $HOME/customer/**/.history $HOME/.zsh_history ; restartLogging; } # search all history files and grep them (usage hist <searchterm>) ## ** is used to not follow the currentCustomer link

## firejail
alias fireEditTemplate='firejail --quiet --private=$customer_dir_template firefox -no-remote 2>/dev/null &;disown' # Used to edit the template (add new certificates e.g.)

## taskwarrior
alias c=ctask # task warrior alias (add del done etc will all work)
alias a="ctask add" # quick add a task
alias d="ctask del" # quick del a task
f(){ctask add "file://${@}"} # Add a reflink to e.g. documentation (task rc.data.location=$HOME/customer/$customer/ctask 2>/dev/null add)

## Typora
alias note='typora $HOME/customer/$customer/markdown-$customer & disown'

### Functions ###

deleteCustomer(){
	delCust=${1// /_}
	delCust=${delCust//[^a-zA-Z0-9_\-]/}
	if [ -n "$delCust" ]; then
		echo "Delete $HOME/customer/${delCust}?"
		yn=""
		vared -p "[y/n]?" -c yn
	    case $yn in
	        [Yy]* ) rm -r $HOME/customer/${delCust};;
	        [Nn]* ) ;;
	        * ) echo "Wrong input.";;
	    esac

	else
		print "No customer given."
	fi
}

### Move Template ###
cLoggy_moveTemplate(){
	if [ ! -e $HOME/.config/cLoggy/template/.template-marker ]; then
		# Copy the template folder from the plugin/module folder to ~/.config/cLoggy/ for better compability and portability
		[[ $ZSH ]] && cp -ra $ZSH/plugins/cLoggy/template/ $HOME/.config/cLoggy/template/ || cp -ra ${0:a:h}/template/ $HOME/.config/cLoggy/template/
	fi
}

# Change the background color for the currently active customer
pickColor(){
	if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
		echoColors
		newColor=$(grim -g "$(slurp -p)" - -t png -o | convert png:- -format '%[pixel:s]\n' info:- | awk -F '[(,)]' '{printf("#%02x%02x%02x\n",$2,$3,$4)}')
		if [ -n "$newColor" ]; then
			if [ -n "$customer" ]; then
				echo $newColor >! $HOME/customer/$customer/.bgcolor && loadColor 2>&1
			else
				echo $newColor >! $HOME/.bgcolor && loadColor 2>&1
			fi
		fi
	else
		if command -v grabc &> /dev/null; then
			echoColors
			echo "Hit CTRL+C when you are satisfied with the color"
			while true; do
				newColor=$(grabc)
				if [ -n "$newColor" ]; then
					if [ -n "$customer" ]; then
						echo $newColor >! $HOME/customer/$customer/.bgcolor && loadColor 2>&1
					else
						noncustomer_bg_color=$newColor
						sed -i "s/noncustomer_bg_color\=\#.*$/noncustomer_bg_color\=$newColor/g" $ZSH/plugins/cLoggy/cLoggy-settings.conf && loadColor
					fi
				fi
			done
		else
			echo "Sorry, grabc is not installed."
		fi
	fi

}

# Create configuration file
cLoggy_checkConfig() {
	if [ ! -s "$HOME/.config/cLoggy/cLoggy-settings.conf" ]; then
		mkdir -p $HOME/.config/cLoggy/
		cat > $HOME/.config/cLoggy/cLoggy-settings.conf <<EOL
		############## Config ###############
		# startEndTimeWithoutCustomer defines if date pattern ([2017-01-05 12:00:00])
		# is always shown or only when a customer is set.
		startEndTimeWithoutCustomer=1
		# Define ctask as customer bound taskwarrior alias
		integrate_ctask=1
		# Make use of the customer template folder. It is located under $HOME/.config/cLoggy/template/.
		# You can also configure the Firefox pseudo jail (with the command fireEditTemplate)
		use_customer_templating=1
		# Modify to define your own customer template folder. All data from here
		# will be copied into each customer folder during customer creation (once).
		customer_dir_template="$HOME/.config/cLoggy/template/"
		# Show Motd
		motd_enabled=1
		# Per customer zsh history
		customer_zsh_history=1
		# Per folder zsh history (global)
		use_per_folder_history=1
		# Check each mountpoint for free space with exceptions for tmpfs and cdroms
		check_free_space=1
		# Customers default background color
		customer_default_bg_color=#242436
		# NonCustomerColor
		noncustomer_bg_color=#1e1e1e
EOL
	fi
	source $HOME/.config/cLoggy/cLoggy-settings.conf
	mkdir -p $HOME/customer
	touch $HOME/.customer
	if [ -z "$customer" ]; then
		export customer=$(cat $HOME/.customer)
	fi
}

# Autocomplete for customer selection
compdef _cLoggy setCustomer
compdef _cLoggy tempCustomer
compdef _cLoggy deleteCustomer
_cLoggy () {
	compadd -V letters `_cLoggy_getCustomerList`
}
#	zstyle ':completion:*' file-sort modification
#	_files -/ -W $HOME/customer -F "^currentCustomer$" -I "/"
#} # This part was a workaround for modification time sorting of the customers

_cLoggy_getCustomerList () {
	#ls -t $HOME/customer | grep -v # This parses all customer folders and returns it as auto completion for zsh
	# The following is the madness that removes the currentCustomer symlink from
	# the results, while maintaining the mtime sort
	find $HOME/customer -mindepth 1 -maxdepth 1 -type d -printf '%T@ %P\n' | sort -k 1 -nr | cut -d' ' -f2
}

setCustomer(){
	# Sanitize userinput - Replace spaces with underscores and clean out anything
	# that's not alphanumeric a dash or an underscore
	CLEAN=${1// /_}
	CLEAN=${CLEAN//[^a-zA-Z0-9_\-]/}
	echo "$CLEAN" >! $HOME/.customer
	customer=$CLEAN
	if [ -n "$1" ]; then
		logdir=$HOME/customer/$customer/logs # Workaround! To be fixed in the app flow later on
		if [ ! -d $logdir ]; then
				mkdir -p $logdir
		fi
		cd $HOME/customer/$customer/ # This shall make sure that on customer change the
																 # path will be changed regardless of the current working dir
																 # Create currentCustomer symlink

		# Check if the permanent customer (file) has been changed in order to change
		# the symlink only on a different customer. If not tested against, tools like the file browser exit the currentCustomer
		# folder on the creation of a new terminal window.
		if [ -L  $HOME/customer/currentCustomer ] ; then
			if [ $(basename $(readlink $HOME/customer/currentCustomer)) != $(cat $HOME/.customer) ]; then
				rm $HOME/customer/currentCustomer 2>/dev/null
				ln -s $HOME/customer/$customer $HOME/customer/currentCustomer 2>&1
			fi
		else
			ln -s $HOME/customer/$customer $HOME/customer/currentCustomer 2>&1
		fi
		loadCustomer
	else
		cd
		unloadCustomer
	fi
}

tempCustomer(){
	# Sanitize userinput
	# replace spaces with underscores and clean out anything that's not alphanumeric a dash or an underscore
	CLEAN=${1// /_}
	CLEAN=${CLEAN//[^a-zA-Z0-9_\-]/}
	customer=$CLEAN
	if [ -n "$1" ]; then
		logdir=$HOME/customer/$customer/logs # Workaround! To be fixed in the app flow later on
		if [ ! -d $logdir ]; then
				mkdir -p $logdir
		fi
		cd $HOME/customer/$customer/ # This shall make sure that on customer change the
																 # path will be changed regardless of the current working dir
		loadCustomer
	else
		cd
		unloadCustomer
	fi
}

# Switch back to the last permanent customer
cback(){
	export customer=$(cat $HOME/.customer)
	cd $HOME/customer/$customer/
	loadCustomer
}

# Screen layout cleanup
softStartTerminal(){
	clear
	loadColor
	loadModt
}

# Customer loadup sequence
loadCustomer(){
	if [ "$customer_zsh_history" = 1 ] ; then
		fc -p $HOME/customer/$customer/.history
	fi
	startLogging
	if [ "$(pwd)" = "$HOME" ]; then
		cd $HOME/customer/$customer/
	fi
	if [ -n "$customer" ] ; then
		# Custom taskwarrior instance
		if [ $integrate_ctask = 1 ] ; then
			mkdir -p $HOME/customer/$customer/ctask
			alias ctask="task rc.data.location=$HOME/customer/$customer/ctask 2>/dev/null "
		fi
		# Setup Firefox alias to use firejail and copy the template
		if [ $use_customer_templating = 1 ] ; then
			if [ ! -e $HOME/customer/$customer/.template-marker ]; then
				cp -ra $customer_dir_template/. $HOME/customer/$customer/
				mv $HOME/customer/$customer/markdown-notes $HOME/customer/$customer/markdown-$customer # Delete, if you do not use Markdown documentation
			fi
			alias firefox="firejail --quiet --private=$HOME/customer/$customer firefox -no-remote 2>/dev/null &;disown"
		fi
	fi
	softStartTerminal
}

unloadCustomer(){
	if [ "$customer_zsh_history" = 1 ] ; then
		fc -p $HOME/.zsh_history
	fi
	unalias cc 2>/dev/null
	unalias ctask 2>/dev/null
	unalias firefox 2>/dev/null
	stopLogging
	#cd moved to the command itself. Else it is even triggered when the Nemo function "Open Terminal here" is used.
	unset customer
	rm $HOME/customer/currentCustomer 2>/dev/null
	softStartTerminal
}

loadTimeStamps(){
	preexec () {
		if [ "$use_per_folder_history" = 1 ] ; then
			if [[ ! "$1" =~ "^here.*" && "$1" != "zsh" ]]; then # exclude any occurence of here and here with grep pipes (here | grep word)
				mkdir -p "$HOME/.zsh_history.d/$PWD/"
				echo $1 >>! "$HOME/.zsh_history.d/$PWD/history"
			fi
		fi
		DATE=$( date +"Begin [%Y-%m-%d %H:%M:%S]" )
		local len_right=${#DATE}
		len_right=$(( $len_right+1 ))
		local right_start=$(($COLUMNS - $len_right))
		RDATE="\033[${right_start}C ${DATE}"
		echo -e "${RDATE}"
	}
	# End-Time (Workaround as there is no function for postexec() - precmd used instead as it is executed before the next prompt)
	precmd() {
		DATE=$( date +"End [%Y-%m-%d %H:%M:%S]" )
		local len_right=${#DATE}
		len_right=$(( $len_right+1 ))
		local right_start=$(($COLUMNS - $len_right))
		RDATE="\033[${right_start}C ${DATE}"
		echo -e "${RDATE}"
	}
}

startLogging(){
	logdir=$HOME/customer/$customer/logs
	if [ ! -d $logdir ]; then
			mkdir -p $logdir
	fi
	logfile=$logdir/tmux_$(date +%F_%T)_PID$$.html
	tmux pipe-pane "exec cat - | ansifilter --html --font monospace | sed -u 's/^.*End/\%   End/g' >> $logfile"
}

restartLogging(){
	tmux pipe-pane "exec cat - | ansifilter --html --font monospace | sed -u 's/^.*End/\%   End/g' >> $logfile"
}

stopLogging(){
	tmux pipe-pane
}

loadModt(){
	if [ -n "$customer" ] ; then
		echo "$fg[green]Logging to: file://$logfile$fg[default]"
	else
		echo "$fg[red]Not logging - No customer set..$fg[default]"
	fi
	if [ "$motd_enabled" = 1 ]; then
		echo "Uptime: $(uptime -p)"
		echo "Networks:\n$(ip -brief -color -4  a | grep -v UNKNOWN)"
		if ext="$(curl -4 https://my.h8.to/ -m 1 2>/dev/null)"; then
			echo "External IP:\t $fg[green]UP\t\t\033[35m${ext} $fg[default]GW:\033[35m $(ip r | grep default | cut -f3 -d' ' | head -1)$fg[default] ($(ip r | grep default | cut -f5 -d' ' | head -1))"
		else
			echo "External IP:\t $fg[red]DOWN$fg[default]\t        \033[35mProxy or Offline$fg[default]"
		fi
		if [ $integrate_ctask = 1 -a -n "$customer" ] ; then
			if [ -e $HOME/.taskrc ]; then
				echo "$(ctask ls 2>/dev/null | head -n -1)"
			else
				echo "$fg[red]Please run taskwarrior first in order to create the .taskrc configuration file.$fg[default]"
			fi
		fi
		if [ $check_free_space = 1 ] ; then
			timeout -k 2 2 df -H | grep -vE '^Filesystem|tmpfs|cdrom|boot' | awk '{ print $5 " " $1 }' | while read output;
			do
				usep=$(echo $output | awk '{ print $1}' | cut -d'%' -f1  )
				partition=$(echo $output | awk '{ print $2 }' )
				if [ $usep -ge 90 ]; then
					echo "$fg[yellow]Running out of disk space \e[1;33m\"$partition ($fg[red]$usep%$fg[yellow])\"$fg[default]"
				fi
			done
		fi
	fi
}

loadColor(){
	if [ -n "$customer" ]; then
		if [ -e $HOME/customer/$customer/.bgcolor ]; then
			customer_bg_color=$(cat $HOME/customer/$customer/.bgcolor)
			tmux select-pane -P "bg=$customer_bg_color"
		else
			tmux select-pane -P "bg=$customer_default_bg_color"
		fi
	else
		tmux select-pane -P "bg=$noncustomer_bg_color"
	fi
}

echoColors(){
	setBackgroundColor()
	{
    	printf '\x1b[48;2;%s;%s;%sm' $1 $2 $3
	}

	resetOutput()
	{
    	echo -en "\x1b[0m\n"
	}

	# Gives a color $1/255 % along HSV
	# Who knows what happens when $1 is outside 0-255
	# Echoes "$red $green $blue" where
	# $red $green and $blue are integers
	# ranging between 0 and 255 inclusive

	for i in `seq 0 127`; do setBackgroundColor $i 0 0;	echo -en " "; done;	resetOutput
	for i in `seq 0 127`; do setBackgroundColor $i $((i/2)) $((i/2)); echo -n " "; done; resetOutput
	for i in `seq 0 127`; do setBackgroundColor $i $((i/2)) 0; echo -en " "; done; resetOutput
	for i in `seq 0 127`; do setBackgroundColor $i $i 0; echo -en " ";	done; resetOutput
	for i in `seq 0 127`; do setBackgroundColor $((i*2/3)) $i 0; echo -en " "; done; resetOutput
	for i in `seq 0 127`; do setBackgroundColor $((i/2)) $i $((i/2)); echo -n " "; done; resetOutput
	for i in `seq 0 127`; do setBackgroundColor 0 $i 0;	echo -n " "; done; resetOutput
	for i in `seq 0 127`; do setBackgroundColor 0 $i $((i*2/3)); echo -n " "; done; resetOutput
	for i in `seq 0 127`; do setBackgroundColor 0 $i $i; echo -n " "; done;	resetOutput
	for i in `seq 0 127`; do setBackgroundColor $((i/2)) $((i/2)) $i; echo -n " "; done; resetOutput
	for i in `seq 0 127`; do setBackgroundColor 0 $((i/2)) $i; echo -n " ";	done; resetOutput
	for i in `seq 0 127`; do setBackgroundColor 0 $((i/2)) $((i*2/3)); echo -en " "; done; resetOutput
	for i in `seq 0 127`; do setBackgroundColor 0 0 $i; echo -n " "; done; resetOutput
	for i in `seq 0 127`; do setBackgroundColor $i $i $i; echo -n " "; done; resetOutput

}

### Flow ###
cLoggy_checkConfig
cLoggy_moveTemplate
if [ -n "$customer" ]; then
	loadCustomer
else
	unloadCustomer
fi

if [ $startEndTimeWithoutCustomer = 1 -o -n "$customer" ] ; then
	loadTimeStamps
fi
