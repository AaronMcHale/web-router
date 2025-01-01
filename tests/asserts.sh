# Assert helper functions for running tests

function assert() {
  # If the first argument is `not` then we set `$invert=1` and shift all
  # positional arguments so that `$2` becomes `$1`.
  assert="$1"
  if [ "${1-}" = 'not' ]; then
    if [ -z "${2-}" ]; then
      echo 'assert: not: expected test to run, none provided.'; exit 1
    fi
    assert='not: '"${2-}"
    shift
  fi

  if [ -z "${1-}" ]; then
    echo 'assert: expected test to run, none provided.'; exit 1
  fi
  shift

  if [ -z "${1-}" ]; then
    echo 'assert: '"$assert"': missing arguments, requires one or more arguments.'; exit 1
  fi

  case "$assert" in
    'exists') assert_exists "$1" ;;
    'not: exists') assert_exists_not "$1" ;;
    'empty') assert_empty "$1" "${2-}" ;;
    'not: empty') assert_empty_not "$1" "${2-}" ;;
    'equal') assert_equal "$1" "${2-}" ;;
    'not: equal') assert_equal_not "$1" "${2-}" ;;
    'contain') assert_contain "$1" "${2-}" ;;
    'not: contain') assert_contain_not "$1" "${2-}" ;;
    'compose_container_up') assert_compose_service_up "$1" ;;
    'not: compose_container_up') assert_compose_service_up_not "$1" ;;
    *) echo 'assert: '"$assert"': test does not exist.'; exit 1 ;;
  esac
}

function assert_exists() {
  if [ ! -x "$1" ]; then
    echo 'ASSERT FAIL: '"$1"' does not exist, expect file or directory to exist.'
    exit 1
  fi
}

function assert_exists_not() {
  if [ -x "$1" ]; then
    if [ -d "$1" ]; then
      echo 'ASSERT FAIL: directory '"$1"' exists, expected file or directory not to exist.'
      echo 'Parent working directory: '"$PWD"
      exit 1
    fi
    echo 'ASSERT FAIL: file '"$1"' exists, expected file or directory not to exist.'
    echo 'Parent working directory: '"$PWD"
    exit 1
  fi
}

function assert_empty() {
  if [ -n "${2-}" ]; then
    echo 'ASSERT FAIL: variable '"$1"' is not empty.'
    echo 'Value is: '"${2-}"
    exit 1
  fi
}

function assert_empty_not() {
  if [ -z "${2-}" ]; then
    echo 'ASSERT FAIL: variable '"$1"' is empty, expected variable to have a value.'
    exit 1
  fi
}

function assert_equal() {
  if [ "$1" != "${2-}" ]; then
    echo 'ASSERT FAIL: values are not equal, expected values to be equal.'
    echo 'Value 1: '"$1"
    echo 'Value 2: '"${2-}"
    exit 1
  fi
}

function assert_equal_not() {
  if [ "$1" = "${2-}" ]; then
    echo 'ASSERT FAIL: values are equal, expected values not to be equal.'
    echo 'Value 1: '"$1"
    echo 'Value 2: '"${2-}"
    exit 1
  fi
}

function assert_contain() {
  if [ ! "$(echo ${2-} | grep $1 )" ]; then
    echo 'ASSERT FAIL: first string is not within second string, expected second string to contain first string.'
    echo 'First string: '"$1"
    echo 'Second string: '"${2-}"
    exit 1
  fi
}

function assert_contain_not() {
  if [ "$(echo ${2-} | grep $1 )" ]; then
    echo 'ASSERT FAIL: first string is within second string, expected second string not to contain first string.'
    echo 'First string: '"$1"
    echo 'Second string: '"${2-}"
    exit 1
  fi
}

function assert_compose_service_up() {
  if [ ! "$(docker compose ps | grep -w $1 )" ]; then
    echo 'ASSERT FAIL: docker compose container does not appear to be running, expected to find running container matching name when running `docker compose ps`.'
    echo 'Container name: '"$1"
    exit 1
  fi
}

function assert_compose_service_up_not() {
  if [ "$(docker compose ps | grep -w $1 )" ]; then
    echo 'ASSERT FAIL: docker compose container appear to be running, found running container matching name when running `docker compose ps`.'
    echo 'Container name: '"$1"
    exit 1
  fi
}
