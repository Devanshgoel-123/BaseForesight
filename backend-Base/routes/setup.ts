import {ethers} from "ethers";
import Abi from "../FPMMMarket.json"

export async function initial_setup() {
  const provider = new ethers.JsonRpcProvider("https://base-sepolia.g.alchemy.com/v2/cB8d-av2mkW_a4Eftu_eIHsIjzwZOh5S");

  const signer=new ethers.Wallet("746e847bbd4aaa11210e5b1ff444cb335288d24c4d698ca2dd0129d8e05248e0",provider);

  const abi=Abi.abi;
  const contractAddress ="0xf9cc4870C429FD236270febeF0C70221A253D637"; //contract address of the base sepolia network;

  const contractWrite=new ethers.Contract(contractAddress,abi,signer);
  const contractRead=new ethers.Contract(contractAddress,abi,provider);

  console.log("✅ market Contract connected at =", contractWrite.getAddress());


  return {
    provider,signer,abi,contractAddress,contractWrite,contractRead
  };
}
