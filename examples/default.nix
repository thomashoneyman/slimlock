# This file collects the packages used as minimal examples of the library in
# action, suitable for inclusion in the flake checks as a test suite.
{callPackage}: {
  npm-workspaces = callPackage ./npm-workspaces {};
  override-attrs = callPackage ./override-attrs {};
  override-phase = callPackage ./override-phase {};
}
