# SPDX-FileCopyrightText: Copyright 2026 secunet Security Networks AG <https://www.secunet.com>
#
# SPDX-License-Identifier: Apache-2.0

{
  runCommand,
  contextapi,
  extra-oas,
  lib,
}:
runCommand "generate-hwaas-openapi-json" { } ''
  ARGS=""
  for F in ${lib.concatStringsSep " " extra-oas}; do
    ARGS="$ARGS --remote-oas-paths $F"
  done

  ${contextapi}/bin/contextapi-openapi-generator \
    -vv $ARGS \
    --out-file $out

  # Give the merged OAS spec a new title, since it is not the Context API alone
  sed -i -e 's/HWaaS Context API/HWaaS API/g' $out
''
