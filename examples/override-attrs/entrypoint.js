import Database from "better-sqlite3";
import ssh2 from "ssh2";

function main() {
  console.log("Running");
  let keys = ssh2.utils.generateKeyPairSync("ed25519");
  console.log("Public key: ", keys.public);
  return new Database("registry.sqlite3", { fileMustExist: true });
}

main();
