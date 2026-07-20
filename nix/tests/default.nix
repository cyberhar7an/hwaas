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
    {
      checks = {
        openapi-spec-golden-test = pkgs.callPackage ./openapi.nix {
          inherit (pkgs) jd-diff-patch openapi-generator-cli runCommand;
          inherit (config.packages) contextapi-oas remote-hands-oas net-ctrl-oas;
        };
      };
    };
}
