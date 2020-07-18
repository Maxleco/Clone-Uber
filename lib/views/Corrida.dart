import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uber/model/Marcador.dart';
import 'package:uber/model/Usuario.dart';
import 'package:uber/util/StatusRequisicao.dart';
import 'package:uber/util/UsuarioFirebase.dart';

// ignore: must_be_immutable
class Corrida extends StatefulWidget {
  String idRequisicao;
  Corrida(this.idRequisicao);
  @override
  _CorridaState createState() => _CorridaState();
}

class _CorridaState extends State<Corrida> {
  Completer<GoogleMapController> _controller = Completer();
  CameraPosition _posicaoCamera = CameraPosition(
    target: LatLng(-7.993804, -34.840125),
    zoom: 18,
  );
  Set<Marker> _marcadores = {};
  String _idRequisicao;
  Map<String, dynamic> _dadosRequisicao;
  String _mensagemStatus = "";
  String _statusRequisicao = StatusRequisicao.AGUARDANDO;
  Position _localMotorista;

  List<String> _listOptions = ["Configurações", "Sair"];
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

  //Controles para exibição de telas
  //?------------------------------------------------------------------------
  String _textBotao = "Aceitar Corrida";
  Color _corBotao = Color(0xFF1ebbd8);
  Function _funcaoBotao;

  _alterarBotaoPrincipal(String texto, Color cor, Function funcao) {
    setState(() {
      _textBotao = texto;
      _corBotao = cor;
      _funcaoBotao = funcao;
    });
  }

  //*----------------------------------------------------------------------------------------
  _exibirMarcador(Position local, String urlIcon, String infoWindow) async {
    double pixelRatio = MediaQuery.of(context).devicePixelRatio;
    BitmapDescriptor icone = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: pixelRatio),
      urlIcon,
    );
    Marker marcador = Marker(
      markerId: MarkerId(urlIcon),
      position: LatLng(local.latitude, local.longitude),
      infoWindow: InfoWindow(
        title: infoWindow,
      ),
      icon: icone,
    );
    setState(() {
      _marcadores.add(marcador);
    });
  }

  //*----------------------------------------------------------------------------------------
  _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  _movimetarCamera(CameraPosition cameraPosition) async {
    final controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(cameraPosition),
    );
  }

  _movimetarCameraBounds(LatLngBounds latLngBounds) async {
    final controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(latLngBounds, 100),
    );
  }

  _recuperarUltimaLocalizacaoConhecida() async {
    Position position = await Geolocator()
        .getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);
    if (position != null) {
      //Atulaizar localização em tempo real do motorista
      //-------------------------------------------------------------    
        _exibirMarcador(
          position,
          "images/motorista.png",
          "Motorista",
        );
        setState(() {
          _posicaoCamera = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 18,
          );
          _movimetarCamera(_posicaoCamera);
          _localMotorista = position;
        });  
    }
  }

  _adicionarListenerLocalizacao() async {
    final geolocator = Geolocator();
    final locationOptions = LocationOptions(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 15,
      timeInterval: 0,
    );
    print(geolocator.checkGeolocationPermissionStatus().toString());
    bool status = await geolocator.isLocationServiceEnabled();
    if (status) {
      geolocator.getPositionStream(locationOptions).listen((Position position) {
        if (position != null) {
          if (_idRequisicao != null && _idRequisicao.isNotEmpty) {
            if (_statusRequisicao != StatusRequisicao.AGUARDANDO) {
              UsuarioFirebase.atualizarDadosLocalizacao(
                "motorista",
                _idRequisicao,
                position.latitude,
                position.longitude,
              );
            } else if (position != null) {
              setState(() => _localMotorista = position);
              _statusAguardando();
            }
          }
        }
      });
    }
  }

  //*----------------------------------------------------------------------------------------------
  _statusAguardando() {
    _alterarBotaoPrincipal(
      "Aceitar Corrida",
      Color(0xFF1ebbd8),
      () => _aceitarCorrida(),
    );
    if (_localMotorista != null) {
      double motoristaLat = _localMotorista.latitude;
      double motoristaLon = _localMotorista.longitude;
      Position position = Position(
        latitude: motoristaLat,
        longitude: motoristaLon,
      );
      _exibirMarcador(
        position,
        "images/motorista.png",
        "Motorista",
      );
      CameraPosition cameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 18,
      );
      _movimetarCamera(cameraPosition);
    }
  }

  _statusFinalizada() async {
    //Calcular Valor Viagem
    double latitudeDestino = _dadosRequisicao["destino"]["latitude"];
    double longitudeDestino = _dadosRequisicao["destino"]["longitude"];

    double latitudeOrigem = _dadosRequisicao["origem"]["latitude"];
    double longitudeOrigem = _dadosRequisicao["origem"]["longitude"];

    double distanciaEmMetros = await Geolocator().distanceBetween(
      latitudeOrigem,
      longitudeOrigem,
      latitudeDestino,
      longitudeDestino,
    );
    // Converte para KM
    double distanciaKm = distanciaEmMetros / 1000;
    //Valor cobrado: 8 Reais por KM
    double valorViagem = distanciaKm * 8;
    final formatter = NumberFormat("#,##0.00", "pt_BR");
    final valorViagemFormatado = formatter.format(valorViagem);

    _mensagemStatus = " - Viagem Finalizada";
    _alterarBotaoPrincipal(
      "Confirmar - R\$ $valorViagemFormatado",
      Color(0xFF1ebbd8),
      () => _confirmarCorrida(),
    );

    _marcadores = {};
    Position position = Position(
      latitude: latitudeDestino,
      longitude: longitudeDestino,
    );
    _exibirMarcador(
      position,
      "images/destino.png",
      "Destino",
    );
    CameraPosition cameraPosition = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 18,
    );
    _movimetarCamera(cameraPosition);
  }

  _statusConfirmada() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      "/painel-motorista",
      (_) => false,
    );
  }

  _statusACaminho() {
    _mensagemStatus = " - A caminho do passageiro";
    _alterarBotaoPrincipal(
      "Iniciar Corrida",
      Color(0xFF1ebbd8),
      () => _iniciarCorrida(),
    );

    double latitudeDestino = _dadosRequisicao["passageiro"]["latitude"];
    double longitudeDestino = _dadosRequisicao["passageiro"]["longitude"];

    double latitudeOrigem = _dadosRequisicao["motorista"]["latitude"];
    double longitudeOrigem = _dadosRequisicao["motorista"]["longitude"];

    Marcador marcadorOrigem = Marcador(LatLng(latitudeOrigem, longitudeOrigem),
        "images/motorista.png", "Local Motorista");
    Marcador marcadorDestino = Marcador(
        LatLng(latitudeDestino, longitudeDestino),
        "images/passageiro.png",
        "Local Passageiro");

    _exibirCentralizadoDoisMarcadores(marcadorOrigem, marcadorDestino);
  }

  _statusEmViagem() {
    _mensagemStatus = " - Em Viagem";
    _alterarBotaoPrincipal(
      "Finalizar Corrida",
      Color(0xFF1ebbd8),
      () => _finalizarCorrida(),
    );
    double latitudeDestino = _dadosRequisicao["destino"]["latitude"];
    double longitudeDestino = _dadosRequisicao["destino"]["longitude"];

    double latitudeOrigem = _dadosRequisicao["motorista"]["latitude"];
    double longitudeOrigem = _dadosRequisicao["motorista"]["longitude"];

    Marcador marcadorOrigem = Marcador(LatLng(latitudeOrigem, longitudeOrigem),
        "images/motorista.png", "Local Motorista");
    Marcador marcadorDestino = Marcador(
        LatLng(latitudeDestino, longitudeDestino),
        "images/destino.png",
        "Local Destino");

    _exibirCentralizadoDoisMarcadores(marcadorOrigem, marcadorDestino);
  }

  //---------
  _exibirCentralizadoDoisMarcadores(
      Marcador markerOrigem, Marcador markerDestino) async {
    // final api = Provider.of<DirectionsProvider>(context);
    // print("--------- BUSCANDO ROTA ---------");
    // await api.findDirections(markerOrigem.local, markerDestino.local);

    double latitudeOrigem = markerOrigem.local.latitude;
    double longitudeOrigem = markerOrigem.local.longitude;

    double latitudeDestino = markerDestino.local.latitude;
    double longitudeDestino = markerDestino.local.longitude;

    _exibirDoisMarcadores(markerOrigem, markerDestino);
    //Centralizar a camera em relação as dois pontos
    var sLat, sLon, nLat, nLon;
    if (latitudeOrigem <= latitudeDestino) {
      sLat = latitudeOrigem;
      nLat = latitudeDestino;
    } else {
      sLat = latitudeDestino;
      nLat = latitudeOrigem;
    }
    if (longitudeOrigem <= longitudeDestino) {
      sLon = longitudeOrigem;
      nLon = longitudeDestino;
    } else {
      sLon = longitudeDestino;
      nLon = longitudeOrigem;
    }
    _movimetarCameraBounds(
      LatLngBounds(
        northeast: LatLng(nLat, nLon), //Nordeste
        southwest: LatLng(sLat, sLon), //Sudoeste
      ),
    );
  }
  //---------

  _exibirDoisMarcadores(Marcador markerOrigem, Marcador markerDestino) async {
    double pixelRatio = MediaQuery.of(context).devicePixelRatio;
    Set<Marker> listMarcadores = {};

    LatLng latLngOrigem = markerOrigem.local;
    LatLng latLngDestino = markerDestino.local;

    BitmapDescriptor iconeOrgigem = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: pixelRatio),
      markerOrigem.caminhoImagem,
      mipmaps: true,
    );
    Marker mOrigem = Marker(
      markerId: MarkerId(markerOrigem.caminhoImagem),
      position: LatLng(latLngOrigem.latitude, latLngOrigem.longitude),
      infoWindow: InfoWindow(
        title: markerOrigem.titulo,
      ),
      icon: iconeOrgigem,
    );
    listMarcadores.add(mOrigem);

    BitmapDescriptor iconeDestino = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: pixelRatio),
      markerDestino.caminhoImagem,
      mipmaps: true
    );
    Marker mDestino = Marker(
      markerId: MarkerId(markerDestino.caminhoImagem),
      position: LatLng(latLngDestino.latitude, latLngDestino.longitude),
      infoWindow: InfoWindow(
        title: markerDestino.titulo,
      ),
      icon: iconeDestino,
    );
    listMarcadores.add(mDestino);

    setState(() {
      _marcadores = listMarcadores;
    });
  }

  _adicionarListenerRequisicao() async {
    Firestore db = Firestore.instance;
    db.collection("requisicoes")
        .document(_idRequisicao)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.data != null) {
        _dadosRequisicao = snapshot.data;

        Map<String, dynamic> dados = snapshot.data;
        _statusRequisicao = dados["status"];
        switch (_statusRequisicao) {
          case StatusRequisicao.AGUARDANDO:
            _recuperarUltimaLocalizacaoConhecida();
            _statusAguardando();
            break;
          case StatusRequisicao.A_CAMINHO:
            _statusACaminho();
            break;
          case StatusRequisicao.VIAGEM:
            _statusEmViagem();
            break;
          case StatusRequisicao.FINALIZADA:
            _statusFinalizada();
            break;
          case StatusRequisicao.CONFIRMADA:
            _statusConfirmada();
        }
      }
    });
  }

  // Position _fixarPosicaoMotorista() {
  //   // -7.993804, -34.840125
  //   return Position(
  //     latitude: -7.993804,
  //     longitude: -34.840125,
  //   );
  // }

  @override
  void initState() {
    super.initState();
    _idRequisicao = widget.idRequisicao;
    _adicionarListenerRequisicao();
    //Adicionar Listener para mudança na requisicao
    // _recuperarUltimaLocalizacaoConhecida();
    _adicionarListenerLocalizacao();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Painel Corrida" + _mensagemStatus),
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
        child: Stack(
          children: <Widget>[
            GoogleMap(
              initialCameraPosition: _posicaoCamera,
              mapType: MapType.normal,
              onMapCreated: _onMapCreated,
              // myLocationEnabled: true,
              myLocationButtonEnabled: false,
              markers: _marcadores,
              // polylines: api.currentRoute,
            ),
            //Button
            Positioned(
              right: 0,
              left: 0,
              bottom: 0,
              child: Padding(
                padding: Platform.isIOS
                    ? EdgeInsets.fromLTRB(20, 10, 20, 25)
                    : EdgeInsets.all(10),
                child: RaisedButton(
                  child: Text(
                    this._textBotao,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: this._corBotao,
                  padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                  onPressed: this._funcaoBotao,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _aceitarCorrida() async {
    Usuario motorista = await UsuarioFirebase.getDadosUsuarioLogado();
    motorista.latitude = _localMotorista.latitude;
    motorista.longitude = _localMotorista.longitude;

    Firestore db = Firestore.instance;
    String idRequisicao = _dadosRequisicao["id"];
    db.collection("requisicoes").document(idRequisicao).updateData({
      "motorista": motorista.toMap(),
      "status": StatusRequisicao.A_CAMINHO,
    }).then((_) {
      //Atualização Requisição Ativa
      String idPassageiro = _dadosRequisicao["passageiro"]["idUsuario"];
      db
          .collection("requisicao_ativa")
          .document(idPassageiro)
          .updateData({"status": StatusRequisicao.A_CAMINHO});
      //Salvar Requisição Ativa para motorista
      String idMotorista = motorista.idUsuario;
      db
          .collection("requisicao_ativa_motorista")
          .document(idMotorista)
          .setData({
        "id_requisicao": idRequisicao,
        "id_usuario": motorista.idUsuario,
        "status": StatusRequisicao.A_CAMINHO,
      });
    });
  }

  _iniciarCorrida() {
    Firestore db = Firestore.instance;
    db.collection("requisicoes").document(_idRequisicao).updateData({
      "origem": {
        "latitude": _dadosRequisicao["motorista"]
            ["latitude"], //_dadosRequisicao["passageiro"]["latitude"],
        "longitude": _dadosRequisicao["motorista"]
            ["longitude"], //_dadosRequisicao["passageiro"]["longitude"],
      },
      "status": StatusRequisicao.VIAGEM,
    });

    String idPassageiro = _dadosRequisicao["passageiro"]["idUsuario"];
    db
        .collection("requisicao_ativa")
        .document(idPassageiro)
        .updateData({"status": StatusRequisicao.VIAGEM});

    String idMotorista = _dadosRequisicao["motorista"]["idUsuario"];
    db
        .collection("requisicao_ativa_motorista")
        .document(idMotorista)
        .updateData({"status": StatusRequisicao.VIAGEM});
  }

  _finalizarCorrida() {
    Firestore db = Firestore.instance;
    db.collection("requisicoes").document(_idRequisicao).updateData({
      "status": StatusRequisicao.FINALIZADA,
    });

    String idPassageiro = _dadosRequisicao["passageiro"]["idUsuario"];
    db
        .collection("requisicao_ativa")
        .document(idPassageiro)
        .updateData({"status": StatusRequisicao.FINALIZADA});

    String idMotorista = _dadosRequisicao["motorista"]["idUsuario"];
    db
        .collection("requisicao_ativa_motorista")
        .document(idMotorista)
        .updateData({"status": StatusRequisicao.FINALIZADA});
  }

  _confirmarCorrida() {
    Firestore db = Firestore.instance;
    db.collection("requisicoes").document(_idRequisicao).updateData({
      "status": StatusRequisicao.CONFIRMADA,
    });

    String idPassageiro = _dadosRequisicao["passageiro"]["idUsuario"];
    db.collection("requisicao_ativa").document(idPassageiro).delete();

    String idMotorista = _dadosRequisicao["motorista"]["idUsuario"];
    db.collection("requisicao_ativa_motorista").document(idMotorista).delete();
  }
}
