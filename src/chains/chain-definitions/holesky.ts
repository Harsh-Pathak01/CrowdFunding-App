import { Chain } from "thirdweb/chains";  // ✅ Ensure correct import

export const holesky: Chain = {
    id: 17000,
    name: "Holesky",
    nativeCurrency: {
        name: "Ether",
        symbol: "ETH",
        decimals: 18,
    },
    rpc: "https://17000.rpc.thirdweb.com", // ✅ Replace `rpcUrls` with `rpc`
    testnet: true, // ✅ Explicitly defined as true
    blockExplorers: [
        {
            name: "Etherscan",
            url: "https://holesky.etherscan.io",
            apiUrl: "https://api-holesky.etherscan.io",
        },
    ], // ✅ Changed to an array
};
