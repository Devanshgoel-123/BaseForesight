import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const LockModule = buildModule("FPMM_marketModule", (m) => {
  const collateralToken = "0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43";  // Replace with actual token address
  const fee = 5; 
  const owner = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
  const FPMM_contract  = m.contract("FPMMMarket",[collateralToken,fee,owner]);

  return { FPMM_contract };
});

export default LockModule;
