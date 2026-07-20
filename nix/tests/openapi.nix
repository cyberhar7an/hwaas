# SPDX-FileCopyrightText: Copyright 2026 secunet Security Networks AG <https://www.secunet.com>
#
# SPDX-License-Identifier: Apache-2.0

{ runCommand
, jd-diff-patch
, openapi-generator-cli
, contextapi-oas
, remote-hands-oas
, net-ctrl-oas
, ...
}:
let
  expected-contextapi = ../../expected-oas/contextapi.openapi.json;
  expected-net-ctrl = ../../expected-oas/net-ctrl.openapi.json;
  expected-remote-hands = ../../expected-oas;
in
runCommand "openapi-spec-golden-test" { } ''
  mkdir -p $out

  function _openapi_diff {
    expected="''${1:?"you must provide the expected OpenAPI specification as first argument"}"
    actual="''${2:?"you must proivde the actual OpenAPI specification as second argument"}"

    echo "validating OpenAPI specification '$actual'"
    if ! ${openapi-generator-cli}/bin/openapi-generator-cli validate -i "$actual"; then
      echo -ne "\e[31;1m"
      cat <<-TEXT
  OpenAPI specification in file '$actual' is invalid.
  TEXT
      echo -e "\e[0m"
      exit 1
    fi

    echo "comparing OpenAPI specification '$actual' with expectations"
    if ! ${jd-diff-patch}/bin/jd -set "$expected" "$actual"; then
      echo -ne "\e[31;1m"
      cat <<-TEXT
  OpenAPI specification deviates from expectations located at '$expected'
  This means you introduced changes to the OpenAPI specification that may influence existing consumers.
  If you're aware of this and want to overwrite the old config, run:

      nix run .#regen-expected-oas
  TEXT
      echo -e "\e[0m"
      exit 1
    fi
  }

  _openapi_diff "${expected-contextapi}" "${contextapi-oas}"
  _openapi_diff "${expected-net-ctrl}" "${net-ctrl-oas}"

  remote_hands_expected_files="$(find "${expected-remote-hands}" -name 'remote-*.json' -printf '%f\n')"
  remote_hands_actual_files="$(find "${remote-hands-oas}" -name '*.json' -printf '%f\n')"
  mapfile -t -u 3 remote_hands_files 3< <(echo -e "$remote_hands_expected_files\n$remote_hands_actual_files" | sort | uniq)
  for oas_file in "''${remote_hands_files[@]}"; do
    _openapi_diff "${expected-remote-hands}/$oas_file" "${remote-hands-oas}/$oas_file"
  done
''
