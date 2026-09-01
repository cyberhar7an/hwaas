# SPDX-FileCopyrightText: Copyright 2026 secunet Security Networks AG <https://www.secunet.com>
#
# SPDX-License-Identifier: Apache-2.0

{ lib, ... }:
let
  inherit (builtins) listToAttrs map mapAttrs;

  /**
    Convert a (partial) machine definition to a (filtered) name-value pair.

    Any attributes in the machine definition not explicitly mentioned as inputs below are ignored.

    # Inputs

    Attribute set
    : containing the following attributes.

      `machine`
      : The identifier of a test machine.

      `networkInterfaces`
      : List of network interfaces provided by he machine.

    # Type

    ```
    mapMachineToNameValuePair :: AttrSet -> AttrSet
    ```

    # Examples

    :::{.example}
    ## Usage example
    ```nix
    let
      example_machine = {
        machine = "machine1";
        networkInterfaces = [ "LAN1" "LAN2" ];
      };
    in
    mapMachineToNameValuePair example_machine
    # => { name = "machine1"; value = { LAN1 = { }; ... }; }
    ```
    :::
  */
  mapMachineToNameValuePair = { machine, networkInterfaces }: {
    name = machine;
    value = lib.genAttrs networkInterfaces (_dev: { });
  };

  /**
    Map multiple machine definitions to (filtered) name-value pairs.

    # Inputs

    `machines`
    : A list of machine definitions as expected by `mapMachineToNameValuePair`.

    # Type

    ```
    mapMachines :: list -> AttrSet
    ```

    # Examples

    :::{.example}
    ## Usage example
    ```nix
    let
      example_machines = [
        { machine = "machine1"; networkInterfaces = [ "LAN1" "LAN2" ]; }
        { machine = "machine2"; networkInterfaces = [ "LAN3" ]; }
      ];
    in
    mapMachines example_machines
    # =>  {
    #       machine1 = { LAN1 = { }; ... };
    #       machine2 = { LAN3 = { }; };
    #     }
    ```
    :::
  */
  mapMachines = machines: listToAttrs (map mapMachineToNameValuePair machines);

  /**
    Map a test network description to nested name-value pairs.

    Convert the network items of the HWaaS test driver to a format that is friendly for
    Elasticsearch meta information.

    # Inputs

    `networks`
    : Attribute set defining the test networks with their respective machines.

    # Type

    ```
    mapNetworks :: AttrSet -> AttrSet
    ```

    # Examples

    :::{.example}
    ## Usage example
    ```nix
    let
      example_network = {
        network1 = [
          { machine = "machine1"; networkInterfaces = [ "LAN1" "LAN2" ]; }
          { machine = "machine2"; networkInterfaces = [ "LAN3" ]; }
        ];
      };
    in
    mapNetworks example_network
    # =>  {
    #       network1 = {
    #         machine1 = { LAN1 = { }; ... };
    #         machine2 = { LAN3 = { }; };
    #       };
    #     }
    ```
    :::
  */
  mapNetworks = networks: mapAttrs (_name: mapMachines) networks;
in
{
  inherit mapMachineToNameValuePair mapMachines mapNetworks;
}
