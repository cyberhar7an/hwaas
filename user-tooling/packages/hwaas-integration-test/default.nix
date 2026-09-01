# SPDX-FileCopyrightText: Copyright 2026 secunet Security Networks AG <https://www.secunet.com>
#
# SPDX-License-Identifier: Apache-2.0

{ pkgs }:
let
  inherit (builtins)
    isFunction
    readFile
    removeAttrs
    toJSON
    ;
  inherit (pkgs) lib;

  helpers = import ./helpers.nix { inherit lib; };

  checkTestconfig = import ../../../nix/lib/user-tooling/check-testconfig { inherit lib; };
in
helpers
// {
  inherit checkTestconfig;

  /**
    Remove attributes unknown to the underlying NixOS integration testing functions.

    # Inputs

    `hwaasTestConfig`
    : The full configuration for a HWaaS test.

    # Type

    ```
    filterTestConfig :: AttrSet -> AttrSet
    ```
  */
  filterTestConfig =
    hwaasTestConfig:
    let
      # Attributes we need to filter before passing the test configuration to
      # the nixosTest function. Otherwise, we would get an error about
      # unexpected parameters.
      hwaasConfigOnlyAttributes = [
        "machines"
        "networks"
        "apiUrl"
      ];
    in
    removeAttrs hwaasTestConfig hwaasConfigOnlyAttributes;

  /**
    Inject runtime dependencies for HWaaS user tooling into a HWaaS test.

    # Inputs

    `hwaasTestConfig`
    : The full configuration for a HWaaS test.

    # Type

    ```text
    mkTestConfig :: AttrSet -> AttrSet
    ```
  */
  mkTestConfig =
    {
      extraPythonPackages ? _: [ ],
      ...
    }@hwaasTestConfig:
    let
      benchmarkDataCollector = pkgs.callPackage ../benchmark-data-collector { };
      hwaasPythonDriver = pkgs.callPackage ../hwaas-driver { inherit benchmarkDataCollector; };
    in
    hwaasTestConfig
    // {
      extraPythonPackages =
        pyPkgs:
        [
          hwaasPythonDriver
          benchmarkDataCollector
        ]
        ++ extraPythonPackages pyPkgs;
    };

  /**
    Create a test script from a HWaaS test configuration and additional arguments.

    During test script perparation, the `hwaasTestConfig` input is preprocessed and passed to the
    underlying Python-based testing framework.

    The `testScriptArgs` input is only used when the `testScript` attribute of the `hwaasTestConfig`
    input is a function.

    # Inputs

    `hwaasTestConfig`
    : The full configuration for a HWaaS test.

    `testScriptArgs`
    : Arbitrary arguments passed through to the test script unmodified.

    # Type

    ```
    mkTestScript :: AttrSet -> Any -> String
    ```
  */
  mkTestScript =
    {
      name,
      testScript,
      machines ? { },
      networks ? { },
      apiUrl,
      ...
    }:
    testScriptArgs:
    let
      hwaasConfig =
        let
          inherit (helpers) mapNetworks;

          config = checkTestconfig {
            # Attributes required and checked by our HWaaS test configuration checker.
            inherit
              machines
              name
              networks
              testScript
              apiUrl
              ;
          };

          config' = {
            inherit (config) machines apiUrl;
            networks = mapNetworks config.networks;
          };
        in
        "'''${toJSON config'}'''";

      testScript' = if isFunction testScript then testScript testScriptArgs else testScript;
    in
    ''
      HWAAS_CONFIG = ${hwaasConfig}

      ${readFile ./setup.py}

      ${testScript'}
    '';

  /**
    Create a NixOS integration test with `pkgs` predefined.
  */
  mkTest =
    let
      standardNixosTestConfig = { lib, ... }: { config.nixpkgs.pkgs = lib.mkDefault pkgs; };
    in
    (import "${pkgs.path}/nixos/lib/testing-python.nix" {
      inherit (pkgs.stdenv.hostPlatform) system;
      inherit pkgs;
      extraConfigurations = [ standardNixosTestConfig ];
    }).simpleTest;

  __functor =
    {
      filterTestConfig,
      mkTest,
      mkTestConfig,
      mkTestScript,
      ...
    }:
    hwaasTestConfig:
    let
      testConfig = mkTestConfig (filterTestConfig hwaasTestConfig) // {
        testScript = mkTestScript hwaasTestConfig;
      };

      test = mkTest testConfig;
    in
    lib.recursiveUpdate test { meta.tag = "nix-integration-test"; };
}
