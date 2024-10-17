import { ethers } from "ethers";
import contractData from "./setup.js";

export default async function addLiquidity() {
    const { abi, contractAddress } = contractData;
    const provider = new ethers.JsonRpcProvider(`${process.env.ALCHEMY_NODE_API}`);
    const signer = new ethers.Wallet(`${process.env.PRIVATE_KEY}`, provider);
    const marketContract = new ethers.Contract(contractAddress, abi, signer);
    const amountInWei = ethers.parseEther("0.001");
   const liquid=await marketContract.currentLiquidity();
   console.log(liquid);
    console.log("Starting liquidity addition process...");
      try {
        const balance = await provider.getBalance(await signer.getAddress());
        console.log("User's ETH balance:", ethers.formatEther(balance));
        console.log("Adding liquidity to the market...");
        const addFundingTx = await marketContract.addFunding({
            value: amountInWei,
            gasLimit: 300000 
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
    }
}