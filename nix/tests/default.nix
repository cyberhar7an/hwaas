# SPDX-FileCopyrightText: Copyright 2026 secunet Security Networks AG <https://www.secunet.com>
#
# SPDX-License-Identifier: Apache-2.0

_: {
  imports = [
    ./aruba-switch-mock
    ./hunt
    ./ws-gateway
    ./net-ctrl
    ./remote-hands
    ./contextapi
    ./user-tooling
  ];
  perSystem =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      expected-oas = ../../expected-oas;
      /**
        Generate the check for an OAS file.

        # Inputs

        `name`
        : Name fragment of the OAS file, used to identify both the file and the resulting check.

        `drv`
        : Derivation producing the current OAS file.
      */
      package_gen =
        name: drv:
        let
          bare-name = lib.removeSuffix "-oas" name;
          check-name = "openapi-spec-" + bare-name + "-golden-test";
          expected-oas-file = bare-name + ".openapi.json";
        in
        {
          ${check-name} = pkgs.callPackage ./openapi.nix {
            expected = expected-oas + "/${expected-oas-file}";
            current = drv;
          };
        };
    in
    {
      # Every '*-oas' package gets its own 'openapi-spec-*' check.
      checks = lib.pipe config.packages [
        (lib.filterAttrs (n: _v: (lib.match "^.*-oas$" n) != null))
        (lib.attrsets.concatMapAttrs package_gen)
      ];
    };
}
