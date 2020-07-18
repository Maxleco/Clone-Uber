import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uber/model/Destino.dart';
import 'package:uber/model/Usuario.dart';

class Requisicao {
  String _id;
  String _status;
  Usuario _passageiro;
  Usuario _motorista;
  Destino _destino;

  Requisicao() {
    Firestore db = Firestore.instance;
    DocumentReference ref = db.collection("requisicoes").document();
    this.id = ref.documentID;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> dadosPassageiro = {
      "nome": this.passageiro.nome,
      "email": this.passageiro.email,
      "tipoUsuario": this.passageiro.tipoUsuario,
      "idUsuario": this.passageiro.idUsuario,
      "latitude": this.passageiro.latitude,
      "longitude": this.passageiro.longitude,
    };

    Map<String, dynamic> dadosRequisicao = {
      "id": this.id,
      "status": this.status,
      "passageiro": dadosPassageiro,
      "motorista": null,
      "destino": this.destino.toMap(),
    };
    return dadosRequisicao;
  }

  String get id => this._id;
  set id(String value) => this._id = value;

  String get status => this._status;
  set status(String value) => this._status = value;

  Usuario get passageiro => this._passageiro;
  set passageiro(Usuario value) => this._passageiro = value;

  Usuario get motorista => this._motorista;
  set motorista(Usuario value) => this._motorista = value;

  Destino get destino => this._destino;
  set destino(Destino value) => this._destino = value;
}
