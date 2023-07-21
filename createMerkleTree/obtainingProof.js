import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import fs from "fs";

// (1)
const tree = StandardMerkleTree.load(JSON.parse(fs.readFileSync("tree.json")));
console.log("here")
// (2)
for (const [i, v] of tree.entries()) {
    const address = '0xb24156B92244C1541F916511E879e60710e30b84'

  if (v[0] === address.toLowerCase()) {
    // (3)
    const proof = tree.getProof(i);
    console.log('Value:', v);
    console.log('Proof:', proof);
  }
}