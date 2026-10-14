# SPDX-FileCopyrightText: Copyright 2026 secunet Security Networks AG <https://www.secunet.com>
#
# SPDX-License-Identifier: Apache-2.0

{
  /**
    The `runCommandLocal` function, usually provided by `nixpkgs`.
  */
  runCommandLocal,
  /**
    Derivation providing the `contextapi-openapi-generator` binary.
  */
  contextapi,
  /**
    File paths of additional OpenAPI specifications to merge into the `contextapi` OpenAPI
    specification.
  */
  extra-oas,
  /**
    Miscellaneous `nixpkgs` library functions.
  */
  lib,
}:
runCommandLocal "generate-hwaas-openapi-json"
  {
    meta.description = "Merged OpenAPI specification with user-facing parts of the HWaaS API.";
    meta.longDescription = ''
      OpenAPI specification for the full public REST API of the HWaaS. This explicitly excludes
      other OpenAPI specifications of purely internal components such as `net-ctrl`, for example.
    '';
  }
  ''
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
