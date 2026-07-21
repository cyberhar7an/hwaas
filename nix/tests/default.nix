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
        Mapping from OAS name fragment to a "package definition" that tells us
        where to find the respective OAS file. This is only necessary because
        the `remote-hands` package builds 4 different OAS files rather than a
        single one like all other packages do.

        If you add a new package that provides an OAS, just add the necessary
        entry below.
      */
      name2package = {
        contextapi.package = config.packages.contextapi-oas;
        net-ctrl.package = config.packages.net-ctrl-oas;
        hwaas.package = config.packages.hwaas-oas;
        remote-auxiliary = {
          package = config.packages.remote-hands-oas;
          expected-oas-file = "remote-auxiliary.openapi.json";
        };
        remote-power = {
          package = config.packages.remote-hands-oas;
          expected-oas-file = "remote-power.openapi.json";
        };
        remote-serial = {
          package = config.packages.remote-hands-oas;
          expected-oas-file = "remote-serial.openapi.json";
        };
        remote-usb = {
          package = config.packages.remote-hands-oas;
          expected-oas-file = "remote-usb.openapi.json";
        };
      };
      /**
        Generate the check for an OAS file.

        # Inputs

        `name`
        : Name fragment of the OAS file, used to identify both the file and the resulting check.

        `value`
        : "Package definition" used to look up correct files, see `name2package`.
      */
      package_gen =
        name: value:
        let
          check-name = "openapi-spec-" + name;
          expected-oas-file = value.expected-oas-file or (name + ".openapi.json");
        in
        {
          ${check-name} = pkgs.callPackage ./openapi.nix {
            inherit (pkgs) jd-diff-patch openapi-generator-cli runCommand;
            expected = expected-oas + "/${expected-oas-file}";
            current = value.package + (if value ? expected-oas-file then "/${expected-oas-file}" else "");
          };
        };
    in
    {
      checks = lib.attrsets.concatMapAttrs package_gen name2package;
    };
}
