# SPDX-FileCopyrightText: Copyright 2026 secunet Security Networks AG <https://www.secunet.com>
#
# SPDX-License-Identifier: Apache-2.0

/**
  Verify and compare OpenAPI specifications.
*/
{
  /**
    Wrapper for `runCommand`, usually taken from `pkgs`.
  */
  runCommandLocal,
  /**
    Package providing the `jd` executable.
  */
  jd-diff-patch,
  /**
    Package providing the `openapi-generator-cli` executable.
  */
  openapi-generator-cli,
  /**
    Expected OpenAPI specification file (i.e. "golden specification").
  */
  expected,
  /**
    Current OpenAPI specification to compare with `expected`.
  */
  current,
}:
runCommandLocal "openapi-spec-golden-test" { } ''
  mkdir -p $out

  echo "validating OpenAPI specification '${current}'"
  if ! ${openapi-generator-cli}/bin/openapi-generator-cli validate -i "${current}"; then
    echo -ne "\e[31;1m"
    cat <<-TEXT
  OpenAPI specification in file '${current}' is invalid.
  TEXT
    echo -e "\e[0m"
    exit 1
  fi

  echo "comparing OpenAPI specification '${current}' with expectations"
  if ! ${jd-diff-patch}/bin/jd -set "${expected}" "${current}"; then
    echo -ne "\e[31;1m"
    cat <<-TEXT
  OpenAPI specification deviates from expectations located at '${expected}'
  This means you introduced changes to the OpenAPI specification that may influence existing consumers.
  If you're aware of this and want to overwrite the old config, run:

      nix run .#regen-expected-oas
  TEXT
    echo -e "\e[0m"
    exit 1
  fi
''
