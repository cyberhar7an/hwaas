# SPDX-FileCopyrightText: Copyright 2026 secunet Security Networks AG <https://www.secunet.com>
#
# SPDX-License-Identifier: Apache-2.0

{
  runCommand,
  jd-diff-patch,
  remote-hands-oas,
  openapi-generator-cli,
}:
let
  expected = ../../../expected-oas;
in
runCommand "golden-test-openapi-spec" { inherit jd-diff-patch; } ''
  for FILE in ${expected}/remote-* ${remote-hands-oas}/*; do
    basename "$FILE"
  done | sort | uniq | while read FILE; do
    echo "Comparing OpenAPI spec $FILE"
    if ! ${jd-diff-patch}/bin/jd -set ${expected}/$FILE ${remote-hands-oas}/$FILE; then
      echo -ne "\e[31;1m"
      cat <<TEXT
  OpenAPI specification deviates from expectations located at '${expected}/$FILE'
  This means you introduced changes to the OpenAPI specification that may influence existing consumers.
  If you're aware of this and want to overwrite the old config, run:

      nix run .#regen-expected-oas
  TEXT
      echo -ne "\e[0m"
      exit 1
    fi 1>&2

    echo "Validating OpenAPI spec $FILE"
    ${openapi-generator-cli}/bin/openapi-generator-cli validate -i ${remote-hands-oas}/$FILE
  done

  touch $out
''
