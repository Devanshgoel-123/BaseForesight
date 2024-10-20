import { ethers } from "ethers";
import Abi from "../FPMMMarket.json" assert { type: "json" };
import dotenv from "dotenv"
dotenv.config();
async function connectContract() {
  try {
    const provider = new ethers.providers.JsonRpcProvider(`${process.env.ALCHEMY_NODE_API}`);
    const signer = new ethers.Wallet(`${process.env.PRIVATE_KEY}`, provider);    
    const abi = Abi.abi;
    const contractAddress = "0x267b8Bd953C91E2E38A72dF38CD1Af77D5fFC8B2"; // Contract address of the base sepolia network the nwew on  
    const contractRead = new ethers.Contract(contractAddress, abi, provider);
   
    return {
      provider,
      signer,
      abi,
      contractAddress,
      contractRead
    };
  } catch (error) {
    console.error("❌ Error connecting to the contract:", error);
  }
}

const contractData = await connectContract();

export default contractData;
