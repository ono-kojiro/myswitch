#!/bin/sh

top_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

ansible_opts=""

help()
{
  cat - << EOF
usage : $0 target1 target2 ...

target
  all
  usage
EOF
}

all()
{
  help
}

hosts()
{
  ansible-inventory -i template.yml --list --yaml --output hosts.yml
}

deploy()
{
  ansible-playbook ${ansible_opts} -i hosts.yml site.yml
}

default()
{
  tag=$1
  ansible-playbook ${ansible_opts} -i hosts.yml -t ${tag} site.yml
}

clean()
{
  sws=`sudo vm switch list | tail -n +2 | awk '{ print $1 }'`
  for sw in $sws; do
    cmd="sudo vm switch destroy $sw"
    echo "CMD: $cmd"
    $cmd
  done
}

stop()
{
  vms=`sudo vm list | tail -n +2 | grep Running | awk '{ print $1 }'`
  for vm in $vms; do
    cmd="sudo vm stop $vm"
    echo "CMD: $cmd"
    #$cmd
  done
}

hosts

while [ $# -ne 0 ]; do
  case "$1" in
    -h | --help)
      usage
      exit 1
      ;;
    -o | --output)
      shift
      output=$1
      ;;
    -p | --playbook)
      shift
      playbook=$1
      ;;
    *)
      break
      ;;
  esac

  shift
done

if [ $# -eq 0 ]; then
  all
fi

for target in "$@"; do
  LANG=C type "$target" 2>&1 | grep 'function' > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    $target
  else
    default $target
    #echo "ERROR : $target is not a shell function"
    #exit 1
    #ansible-playbook ${ansible_opts} -i hosts -t ${target} site.yml
  fi
done

