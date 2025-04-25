# nixos-config
Repository collecting configuration.nix files for various PCs

## Usage

1. Move /etc/nixos/configuration.nix to the locally cloned GitHub repo in the
   user’s home directory.
2. In /etc/nixos/, run:
	$ sudo ln -s ~/<your-github-repo-name>/configuration.nix .
    Take note of the trailing “.” at the end.

## Machines

In alphabetical order, with a short description for context:

* `prometheus` main laptop, general purpose usage.
* `calamaro` Thinkpad x61 used as a media center (old machine soon to be
  decommissioned)
  
