import { ethers } from "ethers";
import contractData from "./setup.js";

export default async function addLiquidity() {
    const { abi, contractAddress } = contractData;
    const provider = new ethers.providers.JsonRpcProvider(`${process.env.ALCHEMY_NODE_API}`);
    const signer = new ethers.Wallet(`${process.env.PRIVATE_KEY}`, provider);
    const marketContract = new ethers.Contract(contractAddress, abi, signer);
    const amountInWei = ethers.utils.parseEther("0.01");
    console.log("Amount in Wei is :",amountInWei);
   const liquid=await marketContract.currentLiquidity();
   console.log(liquid);
    console.log("Starting liquidity addition process...");
      try {
        const balance = await provider.getBalance(await signer.getAddress());
        console.log("User's ETH balance:", ethers.utils.formatEther(balance));
        console.log("Adding liquidity to the market...");
        console.log(amountInWei);
        const addFundingTx = await marketContract.addFunding({
            value: amountInWei,
            gasLimit: 3000000
        });
        console.log("Transaction sent. Waiting for confirmation...");
        console.log("Transaction hash:", addFundingTx.hash);
        const receipt = await addFundingTx.wait();
        if (receipt.status === 0) {
            throw new Error("Transaction failed");
        }
        console.log("Liquidity added successfully!");
        console.log("Transaction hash:", receipt.transactionHash);
        console.log("Gas used:", receipt.gasUsed.toString());
        return receipt.transactionHash;
    } catch (error) {
        console.error("Error adding liquidity:", error);
        if (error.reason) {
            console.error("Reason:", error.reason);
        }
        if (error.transaction) {
            console.error("Transaction data:", error.transaction.data);
        }
        if (error.receipt) {
            console.error("Transaction receipt:", error.receipt);
        }
        return "Error has occured while adding liquidity"
    }
}