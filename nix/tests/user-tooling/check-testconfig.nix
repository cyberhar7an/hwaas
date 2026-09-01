# SPDX-FileCopyrightText: Copyright 2026 secunet Security Networks AG <https://www.secunet.com>
#
# SPDX-License-Identifier: Apache-2.0

/**
  Run unit tests for the `checkTestconfig` function.
*/
{ lib, runCommand }:
let
  checkTestconfig = import ../../lib/user-tooling/check-testconfig { inherit lib; };
  nixUnittest = import ../../lib/user-tooling/nix-unittest { inherit lib runCommand; };

  goodConfig = {
    name = "Hello World Test";
    apiUrl = "https://api.hwaas.example/v5";
    machines.bmr1 = {
      image = "linux.img";
      platform = "bmrType1";
    };
    networks.network1 = [
      {
        machine = "bmr1";
        networkInterfaces = [ "LAN1" ];
      }
    ];
    testScript = { ... }: ''
      execute_tests()
    '';
  };

  /**
    Dummy to generate a HWaaS machine configuration.
  */
  machineConfig = { lib, ... }: { stateVersion = lib.trivial.release; };

  /**
    Wrap a HWaaS user configuration into a test case with an attached message.
  */
  mkTest =
    {
      expected,
      config,
      message,
    }:
    {
      check = checkTestconfig config;
      inherit message expected;
    };
  /**
    Assume that a HWaaS user configuration evaluates successfully.
  */
  testSuccess = attrs: mkTest (attrs // { expected = true; });
  /**
    Assume that a HWaaS user configuration fails to evaluate.
  */
  testFailure = attrs: mkTest (attrs // { expected = false; });
in
nixUnittest {
  name = "checkTestconfig-test";
  tests = [
    (testSuccess {
      config = goodConfig;
      message = "Valid config evaluates without error";
    })

    (testFailure {
      config = goodConfig // {
        machines.bmr1.image = null;
      };
      message = "Machine needs either image or config";
    })
    (testFailure {
      config = goodConfig // {
        machines.bmr1.config = machineConfig;
      };
      message = "Machine can't have image and config";
    })

    (testFailure {
      config = goodConfig // {
        machines.bmr1 = {
          image = null;
          config = machineConfig;
        };
      };
      message = "Using machine.config is currently not possible";
    })

    (testFailure {
      config = lib.filterAttrs (n: _: n == "name" goodConfig);
      message = "Config needs a name";
    })
    (testFailure {
      config = lib.filterAttrs (n: _: n == "machines" goodConfig);
      message = "Config needs machines";
    })
    (testFailure {
      config = lib.filterAttrs (n: _: n == "networks" goodConfig);
      message = "Config needs networks";
    })
    (testFailure {
      config = lib.filterAttrs (n: _: n == "testScript" goodConfig);
      message = "Config needs a testScript";
    })
    (testFailure {
      config = lib.filterAttrs (n: _: n == "apiUrl" goodConfig);
      message = "Config needs a apiUrl";
    })
  ];
}
