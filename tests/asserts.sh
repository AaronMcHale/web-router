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
    'file_contain') assert_file_contain "$1" "${2-}" ;;
    'not: file_contain') assert_file_contain_not "$1" "${2-}" ;;
    'compose_container_up') assert_compose_service_up "$1" ;;
    'not: compose_container_up') assert_compose_service_up_not "$1" ;;
    'http_status_code') assert_http_status_code "$1" "$2" ;;
    'not: http_status_code') assert_http_status_code_not "$1" "$2" ;;
    'http_response_headers_contain') assert_http_response_headers_contain "$1" "$2" ;;
    'not: http_response_headers_contain') assert_http_response_headers_contain_not "$1" "$2" ;;
    *) echo 'assert: '"$assert"': test does not exist.'; exit 1 ;;
  esac
}

function print_assert_msg() {
  echo 'ASSERT FAIL: '"${assert_msg:-$1}"
  unset assert_msg
}

function assert_exists() {
  if [ ! -x "$1" ]; then
    print_assert_msg "$1"' does not exist, expect file or directory to exist.'
    exit 1
  fi
}

function assert_exists_not() {
  if [ -x "$1" ]; then
    if [ -d "$1" ]; then
      print_assert_msg 'directory '"$1"' exists, expected file or directory not to exist.'
      echo 'Parent working directory: '"$PWD"
      exit 1
    fi
    print_assert_msg 'file '"$1"' exists, expected file or directory not to exist.'
    echo 'Parent working directory: '"$PWD"
    exit 1
  fi
}

function assert_empty() {
  if [ -n "${2-}" ]; then
    print_assert_msg 'variable '"$1"' is not empty.'
    echo 'Value is: '"${2-}"
    exit 1
  fi
}

function assert_empty_not() {
  if [ -z "${2-}" ]; then
    print_assert_msg 'variable '"$1"' is empty, expected variable to have a value.'
    exit 1
  fi
}

function assert_equal() {
  if [ "$1" != "${2-}" ]; then
    print_assert_msg 'values are not equal, expected values to be equal.'
    echo 'Value 1: '"$1"
    echo 'Value 2: '"${2-}"
    exit 1
  fi
}

function assert_equal_not() {
  if [ "$1" = "${2-}" ]; then
    print_assert_msg 'values are equal, expected values not to be equal.'
    echo 'Value 1: '"$1"
    echo 'Value 2: '"${2-}"
    exit 1
  fi
}

function assert_contain() {
  if [ ! "$(echo ${2-} | grep $1 )" ]; then
    print_assert_msg 'first string is not within second string, expected second string to contain first string.'
    echo 'First string: '"$1"
    echo 'Second string: '"${2-}"
    exit 1
  fi
}

function assert_contain_not() {
  if [ "$(echo ${2-} | grep $1 )" ]; then
    print_assert_msg 'first string is within second string, expected second string not to contain first string.'
    echo 'First string: '"$1"
    echo 'Second string: '"${2-}"
    exit 1
  fi
}

function assert_file_contain() {
  if [ ! "$(grep "$1" ${2-} )" ]; then
    print_assert_msg 'file does not contian expected string or pattern, expected file to contain string or pattern.'
    echo 'Grep pattern: '"$1"
    echo 'File: '"${2-}"
    echo 'Parent working directory: '"$PWD"
    exit 1
  fi
}

function assert_file_contain_not() {
  if [ "$(grep "$1" ${2-} )" ]; then
    print_assert_msg 'file contians string or pattern, expected file not to contain string or pattern.'
    echo 'Grep pattern: '"$1"
    echo 'File: '"${2-}"
    echo 'Parent working directory: '"$PWD"
    exit 1
  fi
}

function assert_compose_service_up() {
  if [ ! "$(docker compose ps | grep -w $1 )" ]; then
    print_assert_msg 'docker compose container does not appear to be running, expected to find running container matching name when running `docker compose ps`.'
    echo 'Container name: '"$1"
    exit 1
  fi
}

function assert_compose_service_up_not() {
  if [ "$(docker compose ps | grep -w $1 )" ]; then
    print_assert_msg 'docker compose container appear to be running, found running container matching name when running `docker compose ps`.'
    echo 'Container name: '"$1"
    exit 1
  fi
}

function assert_http_status_code() {
  curl_status=$(curl --insecure --no-progress-meter --output /dev/null "$1" -w "%{http_code}")
  if [ "$curl_status" != "$2" ]; then
    print_assert_msg 'Expected response status code to be the same as actual response code.'
    echo 'Expected code: '"$2"
    echo 'Response code: '"$curl_status"
    echo 'URL: '"$1"
    exit 1
  fi
}

function assert_http_status_code_not() {
  curl_status=$(curl --insecure --no-progress-meter --output /dev/null "$1" -w "%{http_code}")
  if [ "$curl_status" = "$2" ]; then
    print_assert_msg 'Expected response status code to be different from actual response code.'
    echo 'Expected code: '"$2"
    echo 'Response code: '"$curl_status"
    echo 'URL: '"$1"
    exit 1
  fi
}

function assert_http_response_headers_contain() {
  tmp_file='/tmp/web-router-test-curl-'"$RANDOM"
  curl --insecure --no-progress-meter --head "$1" > "$tmp_file"
  if [ $(grep --count --fixed-strings "$2" "$tmp_file") -eq 0 ]; then
    print_assert_msg 'Expected response header to contain string, response headers do not contain expected string.'
    echo 'Expected string: '"$2"
    echo 'URL: '"$1"
    echo 'Response headers:'
    cat "$tmp_file"
    rm -f "$tmp_file"
    exit 1
  fi
  rm -f "$tmp_file"
}

function assert_http_response_headers_contain_not() {
  tmp_file='/tmp/web-router-test-curl-'"$RANDOM"
  curl --insecure --no-progress-meter --head "$1" > "$tmp_file"
  if [ $(grep --count --fixed-strings "$2" "$tmp_file") -gt 0 ]; then
    print_assert_msg 'Expected response header not to contain string, found string in response headers.'
    echo 'String: '"$2"
    echo 'URL: '"$1"
    echo 'Response headers:'
    cat "$tmp_file"
    rm -f "$tmp_file"
    exit 1
  fi
  rm -f "$tmp_file"
}
