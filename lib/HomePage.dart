import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:web3dart/web3dart.dart';
import 'package:url_launcher/url_launcher_string.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Client client;
  late Web3Client web3client;
  late String myAddress = "";
  String contractAddress = "0xEc970bB9456e248D5ee164C1F25bD74eB4F47eb5";

  final rpc_url =
      "https://goerli.infura.io/v3/4009a1b4ddf34fc6ad587c4b10dabe52";
  double _value = 0.0;
  int myAmount = 0;
  var myData = BigInt.zero;
  late DeployedContract contract;
  var _session, _uri;

  @override
  void initState() {
    super.initState();
    client = Client();
    web3client = Web3Client(rpc_url, client);
    getBalance(myAddress);
  }

  var connector = WalletConnect(
      bridge: 'https://bridge.walletconnect.org',
      clientMeta: const PeerMeta(
          name: 'My App',
          description: 'An app for Connect with MetaMask and Send Transaction',
          url: 'https://walletconnect.org',
          icons: [
            'https://files.gitbook.com/v0/b/gitbook-legacy-files/o/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media'
          ]));

  Future<DeployedContract> loadContract() async {
    String abi = await rootBundle.loadString("assets/abi.json");
    final contract = DeployedContract(ContractAbi.fromJson(abi, "Coin"),
        EthereumAddress.fromHex(contractAddress));
    return contract;
  }

  Future<List<dynamic>> query(String name, List<dynamic> args) async {
    final contract = await loadContract();
    final ethFunction = contract.function(name);
    final result = await web3client.call(
        contract: contract, function: ethFunction, params: args);
    return result;
  }

  Future<void> getBalance(String targetAddress) async {
    List<dynamic> result = await query("getBalance", []);
    myData = result[0];
    setState(() {});
  }

  Future<String> withDraw() async {
    var bigAmount = BigInt.from(myAmount);
    var response = await submit("withdraw", [bigAmount]);

    return response;
  }

  Future<String> deposit() async {
    var bigAmount = BigInt.from(myAmount);
    var response = await submit("deposit", [bigAmount]);

    return response;
  }

  submit(String name, List<BigInt> args) async {
    if (connector.connected) {
      try {
        EthereumWalletConnectProvider provider =
            EthereumWalletConnectProvider(connector);
        await launchUrlString(_uri, mode: LaunchMode.externalApplication);
        Uint8List data = contract.function(name).encodeCall(args);
        await provider.sendTransaction(
          from: _session.accounts[0],
          to: contractAddress,
          gas: 200000,
          data: data,
        );
      } catch (exp) {
        print(exp);
      }
    }else{
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please Connect with Metamask"),
      ));
    }
  }

  loginUsingMetamask(BuildContext context) async {
    if (!connector.connected) {
      try {
        var session = await connector.createSession(onDisplayUri: (uri) async {
          _uri = uri;
          await launchUrlString(uri, mode: LaunchMode.externalApplication);
        });
        contract = await loadContract();

        setState(() {
          _session = session;
          myAddress = _session.accounts[0];
        });
      } catch (exp) {
        print(exp);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flutter with Blockchain"),
      ),
      drawer: Drawer(
          child: ListView(
        children: [
          (_session != null)
              ? UserAccountsDrawerHeader(
                  accountName: const Text("Asad"),
                  accountEmail: Text('${_session.accounts[0]}'),
                  currentAccountPicture: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text("A"),
                  ),
                )
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent),
                  onPressed: () => loginUsingMetamask(context),
                  child: const Text("Connect with Metamask")),
        ],
      )),
      body: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 50),
              margin: const EdgeInsets.all(10),
              child: Text(
                "${myData} \Coin",
                style: const TextStyle(fontSize: 40),
              ),
            ),
            InkWell(
              onTap: () {
                getBalance(myAddress);
              },
              child: Container(
                margin: const EdgeInsets.only(top: 50),
                height: 40,
                width: 200,
                color: Colors.greenAccent,
                child: const Center(
                  child: Text(
                    "REFRESH",
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
            const Divider(height: 50),
            SfSlider(
              min: 0.0,
              max: 10.0,
              interval: 1,
              showTicks: true,
              showLabels: true,
              enableTooltip: true,
              minorTicksPerInterval: 1,
              value: _value,
              onChanged: (value) {
                setState(() {
                  _value = value;
                  myAmount = value.round();
                });
              },
            ),
            InkWell(
              onTap: () {
                deposit();
              },
              child: Container(
                margin: const EdgeInsets.only(top: 50),
                height: 40,
                width: 200,
                color: Colors.blueAccent,
                child: const Center(
                  child: Text(
                    "DEPOSIT",
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                withDraw();
              },
              child: Container(
                margin: const EdgeInsets.only(top: 50),
                height: 40,
                width: 200,
                color: Colors.blueAccent,
                child: const Center(
                  child: Text(
                    "WITHDRAW",
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
