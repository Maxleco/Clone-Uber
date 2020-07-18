

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uber/model/Usuario.dart';

class UsuarioFirebase{
  static Future<FirebaseUser> getUsuarioAtual() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    return await auth.currentUser();
  }

  static Future<Usuario> getDadosUsuarioLogado() async {
    FirebaseUser user = await getUsuarioAtual();
    String idUsuario = user.uid;
    Firestore db = Firestore.instance;
    DocumentSnapshot snapshot = await db.collection("usuarios")
      .document(idUsuario).get();

    Map<String, dynamic> dados = snapshot.data;
    String tipoUsuario = dados["tipoUsuario"];
    String email = dados["email"];
    String nome = dados["nome"];
    
    Usuario usuario = Usuario();
    usuario.idUsuario = idUsuario;
    usuario.nome = nome;
    usuario.email = email;
    usuario.tipoUsuario = tipoUsuario;

    return usuario;    
  }

  static atualizarDadosLocalizacao(String tipoUsuario, String idRequisicao, double lat, double lon) async {
    Firestore db = Firestore.instance;
    Usuario passageiro = await getDadosUsuarioLogado();
    passageiro.latitude = lat;
    passageiro.longitude = lon;

    db.collection("requisicoes")
      .document(idRequisicao)
      .updateData({
        tipoUsuario: passageiro.toMap(),
      });

  }
}