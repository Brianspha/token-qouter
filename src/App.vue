<template>
  <v-container fluid fill-height>
    <v-row align="center" justify="center">
      <v-col cols="12" sm="8" md="6">
        <v-card style="border-radius: 20px">
          <v-card-title>TokenQuoter</v-card-title>
          <v-card-text>
            <v-form v-model="form" @submit.prevent="onSubmit">
              <v-row align="center">
                <v-col cols="9">
                  <v-text-field
                    v-model="userAddress"
                    label="Address"
                    outlined
                    dense
                    filled
                    readonly
                    variant="outlined"
                  />
                </v-col>
                <v-col cols="3" style="padding-bottom: 5%">
                  <v-btn
                    height="50px"
                    width="150px"
                    color="primary"
                    @click="toggleConnect"
                  >
                    {{ userAddress.length === 0 ? "Connect" : "Disconnect" }}
                  </v-btn>
                </v-col>
              </v-row>
              <v-row align="center">
                <v-col cols="9">
                  <v-text-field
                    :rules="[
                      {
                        required: (value) =>
                          !!value ||
                          `${selectedTokenIn.name} amount is required`,
                      },
                    ]"
                    v-model="tokenAmountIn"
                    label="Amount"
                    outlined
                    dense
                    filled
                    type="number"
                    variant="outlined"
                  />
                </v-col>
                <v-col cols="3">
                  <v-select
                    v-model="selectedTokenIn"
                    :items="tokenOptions"
                    item-text="text"
                    item-value="name"
                    variant="outlined"
                    rounded
                    persistent-hint
                    return-object
                    single-line
                    item-title="name"
                  >
                  </v-select>
                </v-col>
              </v-row>
              <v-row align="center">
                <v-col cols="9">
                  <v-text-field
                    v-model="tokenAmountOut"
                    label="Amount"
                    readonly
                    outlined
                    dense
                    filled
                    variant="outlined"
                  />
                </v-col>
                <v-col cols="3">
                  <v-select
                    v-model="selectedTokenOut"
                    :items="
                      tokenOptions.filter(
                        (token) => token.name !== selectedTokenIn
                      )
                    "
                    item-text="text"
                    item-value="name"
                    variant="outlined"
                    rounded
                    persistent-hint
                    return-object
                    single-line
                    item-title="name"
                  >
                  </v-select>
                </v-col>
              </v-row>
              <v-row>
                <v-col cols="9">
                  <div>Current Quote</div>
                </v-col>
                <v-col cols="3">
                  <div style="font-weight: bold">
                    {{ currentQuote }} {{ tokenSymbol }}
                  </div>
                </v-col>
              </v-row>
            </v-form>
          </v-card-text>
          <v-card-actions>
            <v-col>
              <v-btn
                block
                rounded="xs"
                size="x-large"
                color="#5865f1"
                @click="getQoutes"
                >Get Qoute</v-btn
              >
              <v-spacer></v-spacer>
              <v-btn
                v-if="bestDexQoute !== -1"
                color="#5865f2"
                block
                rounded="xs"
                size="x-large"
                @click="swapTokens"
                >Swap</v-btn
              >
            </v-col>
          </v-card-actions>
        </v-card>
      </v-col>
    </v-row>

    <v-overlay :model-value="isLoading" class="align-center justify-center">
      <v-progress-circular
        color="primary"
        indeterminate
        size="64"
      ></v-progress-circular>
    </v-overlay>
  </v-container>
</template>
<script>
//@dev This file is not optimised as its just for POC purposes
import bigNumber from "bignumber.js";
import swal from "sweetalert2";
import Web3 from "web3";
import detectEthereumProvider from "@metamask/detect-provider";
import tokenConfig from "../out/ERC20.sol/ERC20.json";
import wethConfig from "../out/IWETH9.sol/IWETH9.json";
import tokenQouterConfig from "../out/TokenQouter.sol/TokenQouter.json";
const tokenABI = tokenConfig.abi;
const wethABI = wethConfig.abi;
const tokenQouterABI = tokenQouterConfig.abi;
const web3 = new Web3(
  new Web3.providers.HttpProvider(import.meta.env.VITE_RPC_ENDPOINT)
);
const usdt = new web3.eth.Contract(tokenABI, import.meta.env.VITE_USDT_ADDRESS);
const weth = new web3.eth.Contract(wethABI, import.meta.env.VITE_WETH9_ADDRESS);

const tokenQouter = new web3.eth.Contract(
  tokenQouterABI,
  import.meta.env.VITE_TOKEN_QOUTER_ADDRESS
);
export default {
  data() {
    return {
      form: false,
      bestDexQoute: -1,
      userConfig: {},
      isLoading: false,
      tokenSymbol: "USDT",
      currentQuote: "",
      userAddress: "",
      tokenAmountIn: "",
      tokenAmountOut: "",
      selectedTokenOut: "",
      selectedTokenIn: "",
      tokenOptions: [
        {
          address: import.meta.env.VITE_USDT_ADDRESS,
          name: "USDT",
          token: "USDT",
          image:
            "https://icons.iconarchive.com/icons/cjdowner/cryptocurrency-flat/512/Tether-USDT-icon.png",
        },
        {
          address: import.meta.env.VITE_WETH9_ADDRESS,
          name: "ETH",
          token: "ETH",
          image:
            "https://icons.iconarchive.com/icons/cjdowner/cryptocurrency-flat/512/Ethereum-ETH-icon.png",
        },
        // Add more token options with images
      ],
    };
  },
  computed: {
    connected() {
      return this.userAddress.length > 0;
    },
  },
  async mounted() {
    this.selectedTokenOut = this.tokenOptions[1].name;
    this.selectedTokenIn = this.tokenOptions[0].name;
    await Promise.all([this.connectWallet(), this.setupListeners()]);
    this.userConfig = { gas: 6000000, from: this.userAddress };
  },
  methods: {
    toggleConnect() {
      if (this.userAddress.length === 0) {
        this.connectWallet();
      } else {
        this.userAddress = "";
      }
    },
    onSubmit() {
      if (!this.form) return;
    },
    async getQoutes() {
      if (!this.form) return;
      this.showLoading();
      if (!this.connected) {
        this.connectWallet();
      }
      try {
        const qoute = await tokenQouter.methods
          .getQouteTokenInToTokenOut(
            new bigNumber(this.tokenAmountIn)
              .multipliedBy(new bigNumber(10).pow(new bigNumber(18)))
              .toFixed(0),
            3000
          )
          .call(this.userConfig);
        const { max, index } = this.findMaxWithIndex(qoute["0"]);
        this.currentQuote = new bigNumber(max)
          .dividedBy(
            new bigNumber(10).pow(
              new bigNumber(await usdt.methods.decimals().call(this.userConfig))
            )
          )
          .toFixed(0);
        this.bestDexQoute = index;
        this.tokenAmountOut = this.currentQuote;
        this.hideLoading();
        this.success(`Best Qoute for Swapping ETH found`);
      } catch (error) {
        this.hideLoading();
        console.error(error);
        this.error("Failed to get Quotes");
      }
    },
    async swapTokens() {
      if (!this.form) return;
      this.showLoading();
      if (!this.connected) {
        this.connectWallet();
      }
      try {
        this.userConfig.value = new bigNumber(this.tokenAmountIn)
          .multipliedBy(new bigNumber(10).pow(new bigNumber(18)))
          .toFixed(0);
        const tx = await tokenQouter.methods
          .swapExactETHToTokenOut(
            this.bestDexQoute //@dev here we force the user to get best qoutes before we allow them to swap as such we always have this value
          )
          .send(this.userConfig);
        this.hideLoading();
        this.success("Swap was successful");
      } catch (error) {
        this.hideLoading();
        console.error(error);
        this.error("Failed to swap");
      }
    },
    async connectWallet() {
      this.showLoading();
      const provider = await detectEthereumProvider();
      this.hideLoading();
      // console.log("Provider: ", await window?.ethereum?.isConnected());
      if (provider && !(await window?.ethereum?.isConnected())) {
        const accounts = await window.ethereum
          .request({ method: "eth_requestAccounts" })
          .catch(async (error) => {
            this.hideLoading();
            switch (error.code) {
              case -32002:
                this.warning({
                  warning:
                    "Please check to see if a request to access your metamask has not been sent. It seems like you have not accepted",
                });
                break;
              case 4001:
                this.errorWithFooterMetamask({
                  message: "Please install metamask to use the DApp",
                });
                break;
              default:
                this.isConnected = true;
                this.userAddress = web3.utils.toChecksumAddress(accounts[0]);

              //  console.log(
              //  `Switching to already connected account ${this.userAddress}`
              //);
            }
          });
      } else if (provider && (await window?.ethereum?.isConnected())) {
        const accounts = await window.ethereum.request({
          method: "eth_requestAccounts",
        });
        this.hideLoading();
        this.isConnected = true;
        this.userAddress = web3.utils.toChecksumAddress(accounts[0]);

        // console.log(
        //    `Switching to already connected account ${this.userAddress}`
        //  );
      } else {
        this.errorWithFooterMetamask({
          message: "Please install metamask to use the DApp",
        });
      }
    },
    findMaxWithIndex(arr) {
      if (arr.length === 0) {
        // Handle the case where the array is empty.
        return { max: undefined, index: -1 };
      }

      let max = arr[0];
      let index = 0;

      for (let i = 1; i < arr.length; i++) {
        if (arr[i] > max) {
          max = arr[i];
          index = i;
        }
      }

      return { max, index };
    },
    async setupListeners() {
      // const chainId = await window.ethereum.request({ method: "eth_chainId" });

      window.ethereum.on("chainChanged", async (chainId) => {
        if (chainId !== this.chainId) {
          window.location.reload();
        }
      });
      window.ethereum.on("accountsChanged", async (accounts) => {
        console.log("accounts: ", accounts);
        if (accounts.length > 0 && accounts[0] !== this.userAddress) {
          window.location.reload();
        }
      });
      //ethereum.on("disconnect", window.location.reload());
    },
    success(message) {
      swal.fire({
        position: "top-end",
        icon: "success",
        title: "Success",
        showConfirmButton: false,
        timer: 2500,
        text: message,
      });
    },
    successWithCallBack(message) {
      swal
        .fire({
          position: "top-end",
          icon: "success",
          title: "Success",
          showConfirmButton: true,
          text: message.message,
        })
        .then((results) => {
          if (results.isConfirmed) {
            message.onTap();
          }
        });
    },
    warning(message) {
      swal.fire("Warning", message.warning, "warning").then((result) => {
        /* Read more about isConfirmed, isDenied below */
        if (result.isConfirmed) {
          message.onTap();
        }
      });
    },
    error(message) {
      swal.fire("Error!", message, "error").then((result) => {
        /* Read more about isConfirmed, isDenied below */
        if (result.isConfirmed) {
          console.log("leveled");
        }
      });
    },
    successWithFooter(message) {
      swal.fire({
        icon: "success",
        title: "Success",
        text: message,
        footer: `<a href= https://etherscan/txs/${message.txHash}> View on Theta Etherscan</a>`,
      });
    },
    errorWithFooterMetamask(message) {
      swal.fire({
        icon: "error",
        title: "Error!",
        text: message.message,
        footer: `<a href= https://metamask.io> Download Metamask</a>`,
      });
    },
    showLoading() {
      this.isLoading = true;
    },
    hideLoading() {
      this.isLoading = false;
    },
  },
};
</script>

<style scoped>
.remove-underline {
  border-style: none;
}
</style>
