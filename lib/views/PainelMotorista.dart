import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uber/util/StatusRequisicao.dart';
import 'package:uber/util/UsuarioFirebase.dart';

class PainelMotorista extends StatefulWidget {
  @override
  _PainelMotoristaState createState() => _PainelMotoristaState();
}

class _PainelMotoristaState extends State<PainelMotorista> {
  final _controller = StreamController<QuerySnapshot>.broadcast();
  List<String> _listOptions = ["Configurações", "Sair"];
  Firestore _db = Firestore.instance;

  _escolhaItemMenu(String item) {
    if (item == _listOptions[1]) {
      _deslogarUsuario();
    }
  }

  _deslogarUsuario() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    await auth.signOut().then((_) {
      Navigator.pushNamedAndRemoveUntil(context, "/", (_) => false);
    });
  }

  Stream<QuerySnapshot> _adicionarListernerRequisicoes() {
    final stream = _db
        .collection("requisicoes")
        .where("status", isEqualTo: StatusRequisicao.AGUARDANDO)
        .snapshots();
    stream.listen((dados) {
      _controller.add(dados);
    });
  }

  _recuperarRequisicaoAtivaMotorista() async {
    //Recuperar dados do usuário logado
    FirebaseUser firebaseUser = await UsuarioFirebase.getUsuarioAtual();
    // Recuperar requisicão ativa
    DocumentSnapshot snapshot = await _db.collection("requisicao_ativa_motorista")
      .document(firebaseUser.uid)
      .get();

    final dadosRequisicao = snapshot.data;
    if(dadosRequisicao == null){
      _adicionarListernerRequisicoes();
    } 
    else{
      String idRequisicao = dadosRequisicao["id_requisicao"];
      Navigator.pushReplacementNamed(
        context,
        "/corrida",
        arguments: idRequisicao
      );
    }
    
  }

  @override
  void initState() {
    super.initState();
    /// Recuperar requisição ativa para verificar se o motorista está
    /// atendendo alguma requisição e enviar ele para a tela de corrida.
    _recuperarRequisicaoAtivaMotorista();
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Painel Motorista"),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: _escolhaItemMenu,
            itemBuilder: (context) {
              return _listOptions.map((item) {
                return PopupMenuItem(
                  child: Text(item),
                  value: item,
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Container(
        child: StreamBuilder<QuerySnapshot>(
            stream: _controller.stream,
            builder: (context, snapshot) {
              Widget defaultWidget;
              if (snapshot.connectionState == ConnectionState.waiting) {
                defaultWidget = Center(
                    child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("Carregando Requisições"),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  ],
                ));
              } else if (snapshot.connectionState == ConnectionState.active) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Erro ao carregar os dados!",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                QuerySnapshot querySnapshot = snapshot.data;
                if (querySnapshot.documents.length == 0) {
                  return Center(
                    child: Text(
                      "Você não tem nenhuma requisição :(",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                //Contém Requisições
                defaultWidget = ListView.separated(
                  itemCount: querySnapshot.documents.length,
                  separatorBuilder: (context, index) => Divider(
                    color: Colors.grey,
                    height: 2,
                  ),
                  itemBuilder: (context, index) {
                    List<DocumentSnapshot> requisicoes =
                        querySnapshot.documents.toList();
                    DocumentSnapshot item = requisicoes[index];
                    String idRequisicao = item["id"];
                    String nomePassageiro = item["passageiro"]["nome"];
                    String rua = item["destino"]["rua"];
                    String numero = item["destino"]["numero"];

                    return ListTile(
                      title: Text(nomePassageiro),
                      subtitle: Text("Destino: $rua, $numero"),
                      isThreeLine: true,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          "/corrida",
                          arguments: idRequisicao
                        );
                      },
                    );
                  },
                );
              } else {
                defaultWidget = Container();
              }
              return defaultWidget;
            }),
      ),
    );
  }
}
