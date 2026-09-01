# SPDX-FileCopyrightText: Copyright 2026 secunet Security Networks AG <https://www.secunet.com>
#
# SPDX-License-Identifier: Apache-2.0

{ lib, runCommand }:

/**
  Execute nix unit tests.

  # Inputs

  `name`
  : Name of the resulting test suite, must be a valid filename.

  `tests`
  : Individual tests to run.
*/
{ name, tests }:
let
  evaluatedTests =
    (lib.evalModules {
      modules = [
        ./options.nix
        { config = { inherit tests; }; }
      ];
    }).config;
in
runCommand name { } ''
  echo "${evaluatedTests.text}" > $out

  ${lib.optionalString (!evaluatedTests.passed) ''
    echo "${evaluatedTests.text}"
    exit 1
  ''}
''
