# SPDX-FileCopyrightText: Copyright 2026 secunet Security Networks AG <https://www.secunet.com>
#
# SPDX-License-Identifier: Apache-2.0

{
  runCommand,
  jd-diff-patch,
  oas,
}:
let
  expected-oas = ../../../expected-oas/net-ctrl.openapi.json;
in
runCommand "golden-test-openapi-spec" { inherit jd-diff-patch; } ''
  mkdir -p $out

  if ! ${jd-diff-patch}/bin/jd -set ${expected-oas} ${oas}; then
    echo -ne "\e[31;1m"
    cat <<TEXT
  OpenAPI specification deviates from expectations located at '${expected-oas}'
  This means you introduced changes to the OpenAPI specification that may influence existing consumers.
  If you're aware of this and want to overwrite the old config, run:

      nix run .#regen-expected-oas
  TEXT
    echo -ne "\e[0m"
    exit 1
  fi 1>&2
''
