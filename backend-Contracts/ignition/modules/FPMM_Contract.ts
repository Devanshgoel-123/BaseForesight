import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";


const LockModule = buildModule("FPMM_marketModule", (m) => {
  const fee = 5; 

  const FPMM_contract  = m.contract("FPMMMarket",[fee]);

  return { FPMM_contract };
});

export default LockModule;
