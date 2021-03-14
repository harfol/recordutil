
#!/bin/bash
function info() { 
	printf "\033[36m[$1] \033[0m$2\n" 
}
function warning()
{

	printf "\033[33m[$1] \033[0m$2\n"
}
function process()
{
	printf "\033[36m[$1] \033[0m$2 [..]"
}
function process_finish()
{
	printf "\b\b\b\b[\033[32mOK\033[0m]\n" 
}
