import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import dotenv from "dotenv" 
dotenv.config();
const config: HardhatUserConfig = {
  solidity: "0.8.26",
  networks:{
    sepolia:{
      url:`https://base-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
      accounts:["746e847bbd4aaa11210e5b1ff444cb335288d24c4d698ca2dd0129d8e05248e0"]
    }
  }
};

export default config;
