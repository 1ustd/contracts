import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const UserRegistarModule = buildModule("UserRegistarModule", (m) => {
  const userRegistar = m.contract("UserRegistar");
  return { userRegistar };
});

export default UserRegistarModule;
