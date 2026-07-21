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
    { pkgs, config, ... }:
    let
      expected-oas = ../../expected-oas;
    in {
      checks.openapi-spec-contextapi = pkgs.callPackage ./openapi2.nix {
        inherit (pkgs) jd-diff-patch openapi-generator-cli runCommand;
        expected = expected-oas + /contextapi.openapi.json;
        current = config.packages.contextapi-oas;
      };
      checks.openapi-spec-net-ctrl = pkgs.callPackage ./openapi2.nix {
        inherit (pkgs) jd-diff-patch openapi-generator-cli runCommand;
        expected = expected-oas + /net-ctrl.openapi.json;
        current = config.packages.net-ctrl-oas;
      };
      checks.openapi-spec-hwaas = pkgs.callPackage ./openapi2.nix {
        inherit (pkgs) jd-diff-patch openapi-generator-cli runCommand;
        expected = expected-oas + /hwaas.openapi.json;
        current = config.packages.hwaas-oas;
      };
      checks.openapi-spec-remote-auxiliary = pkgs.callPackage ./openapi2.nix {
        inherit (pkgs) jd-diff-patch openapi-generator-cli runCommand;
        expected = expected-oas + /remote-auxiliary.openapi.json;
        current = config.packages.remote-hands-oas + /remote-auxiliary.openapi.json;
      };
      checks.openapi-spec-remote-power = pkgs.callPackage ./openapi2.nix {
        inherit (pkgs) jd-diff-patch openapi-generator-cli runCommand;
        expected = expected-oas + /remote-power.openapi.json;
        current = config.packages.remote-hands-oas + /remote-power.openapi.json;
      };
      checks.openapi-spec-remote-serial = pkgs.callPackage ./openapi2.nix {
        inherit (pkgs) jd-diff-patch openapi-generator-cli runCommand;
        expected = expected-oas + /remote-serial.openapi.json;
        current = config.packages.remote-hands-oas + /remote-serial.openapi.json;
      };
      checks.openapi-spec-remote-usb = pkgs.callPackage ./openapi2.nix {
        inherit (pkgs) jd-diff-patch openapi-generator-cli runCommand;
        expected = expected-oas + /remote-usb.openapi.json;
        current = config.packages.remote-hands-oas + /remote-usb.openapi.json;
      };
    };
}
