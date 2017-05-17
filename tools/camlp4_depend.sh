#!/bin/bash -e

usage() {
  PROG_NAME=${0##*/}
  if [ -n "$1" ]; then
    echo "Unexpected argument '$1'" >&2
    echo >&2
  fi
  echo "Usage: $PROG_NAME [<camlp4 flags>] [-I incdir] -- <files>" >&2
  exit 1
}

ARGTYPE=CAMLP4_OTHER_OPTIONS
FILES=
CAMLP4_OTHER_OPTIONS=
INC=
while [ -n "$1" ]; do
    case $1 in
    -h|--help) usage;;
    --) [ $ARGTYPE != "FILES" ] || usage "$1"
        ARGTYPE=FILES;;
    -I) [ $ARGTYPE != "FILES" ] || usage "$1"
        shift
        [ -n "$1" ] || usage
        INC+="-I ${1%/} ";;
    *) declare $ARGTYPE="${!ARGTYPE} $1";;
    esac
    shift
done

[ -n "$FILES" ] || usage;

CAMLP4_LOAD_OPTIONS="pr_depend.cmo pa_macro.cmo"
CAMLP4_OTHER_OPTIONS="$CAMLP4_OTHER_OPTIONS $INC"

for FILE in $FILES; do
    head -1 $FILE >/dev/null || exit 1
    set - $(head -1 $FILE)
    case "$2" in
    nocamlp4)
      COMMAND="ocamldep $INC $FILE";;
    camlp4|camlp4r|camlp4o)
      COMMAND="$2"
      shift; shift
      ARGS=$(echo $* | sed -e "s/[()*]//g")
      DEPS=
      for i in $ARGS; do
        if [[ $i =~ ^\./ ]]; then
          DEPS="$DEPS ${i:2}"
        fi
      done
      if [ -n "$DEPS" ]; then
        case $FILE in
        *.ml)  BASE=$(basename $FILE .ml);  echo $BASE.cmo $BASE.cmx: $DEPS;;
        *.mli) BASE=$(basename $FILE .mli); echo $BASE.cmi: $DEPS;;
        esac
      fi
      COMMAND="$COMMAND $CAMLP4_LOAD_OPTIONS $ARGS -- $CAMLP4_OTHER_OPTIONS $FILE";;
    *)
      COMMAND="camlp4r $CAMLP4_LOAD_OPTIONS -- $CAMLP4_OTHER_OPTIONS $FILE";;
    esac
    echo $COMMAND $FILE >&2
    # camlp4 on Windows generates backslashes and carriage returns
    # the first sed command removes all carriage returns (\x0D)
    # the second sed command replaces all single backslashes by slashes,
    # except those located at the end of a line. $ is required for macOS
    $COMMAND $FILE | sed -e $'s/\x0D//' -e 's/\\\(.\)/\/\1/g'
done
