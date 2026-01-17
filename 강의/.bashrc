# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			. "$rc"
		fi
	done
fi

unset rc

export PS1='\[\e[32;1m\][\u@\h\[\e[33;1m\] \w]\$ \[\e[m\]'

#
# Terraform Configuration
#

# terrafrom alias
alias tf='terraform'

# terraform command alias
alias tf1='terraform init'
alias tf2='terraform plan'
alias tf3='terraform apply -auto-approve'
alias tf4='terraform destroy -auto-approve'

# terraform command autocompletion
complete -C /usr/bin/terraform terraform

complete -C '/usr/local/bin/aws_completer' aws
alias chrome='google-chrome'
