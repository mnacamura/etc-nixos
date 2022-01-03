{ config, lib, substituteAll }:

let
  inherit (config.hardware.video) hidpi;
  inherit (config.environment) colors;
in

substituteAll (colors.hex // {
  src = ./conky.conf;

  gap_x = toString (140 * hidpi.scale);
})
