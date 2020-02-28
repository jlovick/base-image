
local user='%{$FG[226]%}%n@%{$FG[157]%}%m%{$reset_color%}'
local pwd='%{$FG[014]%}%~%{$reset_color%}'
local rvm=''

strlen () {
      FOO=$1
      local zero='%([BSUbfksu]|([FB]|){*})'
      LEN=${#${(S%%)FOO//$~zero/}}
      echo $LEN
}

# show right prompt with date ONLY when command is executed
preexec () {
      DATE=$( date +"[%H:%M:%S]" )
      local len_right=$( strlen "$DATE" )
      len_right=$(( $len_right+1 ))
      local right_start=$(($COLUMNS - $len_right))
      local len_cmd=$( strlen "$@" )
      local len_prompt=$(strlen "$PROMPT" )
      local len_left=$(($len_cmd+$len_prompt))
      RDATE="\033[${right_start}C ${DATE}"
      if [ $len_left -lt $right_start ]; then
        # command does not overwrite right prompt
        # ok to move up one line
        echo -e "\033[1A${RDATE}"
      else
        echo -e "${RDATE}"
      fi
}

if which rvm-prompt &> /dev/null; then
  rvm='%{$fg[green]%}‹$(rvm-prompt i v g)›%{$reset_color%}'
else
  if which rbenv &> /dev/null; then
    rvm='%{$fg[green]%}‹$(rbenv version | sed -e "s/ (set.*$//")›%{$reset_color%}'
  fi
fi

local return_code='%(?..%{$fg[red]%} Error Code :%? ☹  %{$reset_color%})'
#local git_branch='$(git_prompt_status)%{$reset_color%}$(git_prompt_info)%{$reset_color%}'

ZSH_THEME_GIT_PROMPT_PREFIX=" on %{$fg[green]%} "
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"

ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[green]%} ✚ added "
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[blue]%} ✹ modified "
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%} ✖ deleted "
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[magenta]%} ➜ renamed "
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[yellow]%} ═ unmerged "
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[cyan]%} ✭ untracked "

ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[green]%} ⚠ dirty "
ZSH_THEME_GIT_PROMPT_CLEAN="%{$FG[226]%} ☺ clean "


PROMPT="${user} ${pwd}$ "
RPROMPT="${return_code} ${git_branch} ${rvm}"

