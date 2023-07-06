{ lib, slimlock }:

let
  # Takes an attrset of tests and throws an error if any of them fail. A test
  # is an attrset where keys are test names and values are { expr, expected }
  runTests = tests:
    let
      testCount = builtins.length (builtins.attrNames tests);
      failures = lib.debug.runTests tests;
      failureCount = builtins.length failures;
      message = ''
        ${builtins.toString failureCount} out of ${
          builtins.toString testCount
        } tests failed:
      '' + lib.concatMapStringsSep "\n" (fail: ''
        ${fail.name}
          expected: ${builtins.toJSON fail.expected}
               got: ${builtins.toJSON fail.result}
      '') failures;
    in if builtins.length failures == 0 then [ ] else builtins.throw message;

in runTests {
  testSimpleDependencies = {
    expr = slimlock.getDependencies (slimlock.readPackageLock ./simple.json);
    expected = {
      "node_modules/leftpad" = {
        version = "0.0.1";
        integrity =
          "sha512-kBAuxBQJlJ85LDc+SnGSX6gWJnJR9Qk4lbgXmz/qPfCOCieCk7BgoN3YvzoNr5BUjqxQDOQxawJJvXXd6c+6Mg==";
        resolved = "https://registry.npmjs.org/leftpad/-/leftpad-0.0.1.tgz";
      };
    };
  };
}
