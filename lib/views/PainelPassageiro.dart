import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uber/model/Destino.dart';
import 'package:uber/model/Marcador.dart';
import 'package:uber/model/Requisicao.dart';
import 'package:uber/model/Usuario.dart';
import 'package:uber/util/StatusRequisicao.dart';
import 'package:uber/util/UsuarioFirebase.dart';

class PainelPassageiro extends StatefulWidget {
  @override
  _PainelPassageiroState createState() => _PainelPassageiroState();
}

class _PainelPassageiroState extends State<PainelPassageiro> {
  TextEditingController _destinoController = TextEditingController(
    text: "R. Eduardo de Morais, s/n - Casa Caiada, Olinda - PE, 53130-150",
  );
  StreamSubscription<DocumentSnapshot> _streamSubscriptionRequisicoes;
  Completer<GoogleMapController> _controller = Completer();
  List<String> _listOptions = ["Configurações", "Sair"];
  CameraPosition _posicaoCamera = CameraPosition(
    target: LatLng(-23.561600, -46.656217),
    zoom: 18,
  );
  Set<Marker> _marcadores = {};
  String _idRequisicao;
  Map<String, dynamic> _dadosRequisicao;
  Position _localPassageiro;
  final geolocator = Geolocator();

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
  bool _exibirCaixaEndetecoDestino = true;
  String _textBotao = "Chamar Uber";
  Color _corBotao = Color(0xFF1ebbd8);
  Function _funcaoBotao;
  
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

  //----------------------------------------------------------------------------------------
  _exibirMarcadorPassageiro(Position local) async {
    double pixelRatio = MediaQuery.of(context).devicePixelRatio;
    BitmapDescriptor icone = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: pixelRatio),
      "images/passageiro.png",
    );
    Marker marcadorPassageiro = Marker(
      markerId: MarkerId("marcador-passageiro"),
      position: LatLng(local.latitude, local.longitude),
      infoWindow: InfoWindow(
        title: "Meu Local",
      ),
      icon: icone,
    );
    setState(() {
      _marcadores.add(marcadorPassageiro);
    });
  }

  //----------------------------------------------------------------------------------------
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
    Position position = await geolocator
        .getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);

    if (position != null) {
      //-------------------------------------------------------------
      _exibirMarcadorPassageiro(position);
      setState(() {
        _posicaoCamera = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 18,
        );
        _movimetarCamera(_posicaoCamera);
        _localPassageiro = position;
      });
    }
  }

  _adicionarListenerLocalizacao() async {
    geolocator.forceAndroidLocationManager = true;
    final locationOptions = LocationOptions(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 15,
      timeInterval: 0,
    );
    bool status =
        await geolocator.isLocationServiceEnabled();
    if (status) {
      geolocator.getPositionStream(locationOptions).listen((Position position) {
        //-------------------------------------------------------------
        if (_idRequisicao != null && _idRequisicao.isNotEmpty) {
          UsuarioFirebase.atualizarDadosLocalizacao(
            "passageiro",
            _idRequisicao,
            position.latitude,
            position.longitude,
          );
        } else {
          setState(() => _localPassageiro = position);
          _statusUberNaoChamado();
        }
      });
    }
  }

  //---------------------------------------------------------------------------------------------------
  _alterarBotaoPrincipal(String texto, Color cor, Function funcao) {
    setState(() {
      _textBotao = texto;
      _corBotao = cor;
      _funcaoBotao = funcao;
    });
  }

  _statusUberNaoChamado() {
    _exibirCaixaEndetecoDestino = true;
    _alterarBotaoPrincipal(
      "Chamar Uber",
      Color(0xFF1ebbd8),
      () => _chamarUber(),
    );
    if(_localPassageiro != null){
      Position position = Position(
        latitude: _localPassageiro.latitude,
        longitude: _localPassageiro.longitude,
      );
      _exibirMarcadorPassageiro(position);
      CameraPosition cameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 18,
      );
      _movimetarCamera(cameraPosition);
    }
    
  }

  _statusAguardando() {
    _exibirCaixaEndetecoDestino = false;
    _alterarBotaoPrincipal(
      "Cancelar",
      Colors.redAccent,
      () => _cancelarUber(),
    );
    double passageiroLat = _dadosRequisicao["passageiro"]["latitude"];
    double passageiroLon = _dadosRequisicao["passageiro"]["longitude"];
    Position position = Position(
      latitude: passageiroLat,
      longitude: passageiroLon,
    );
    _exibirMarcadorPassageiro(position);
    CameraPosition cameraPosition = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 18,
    );
    _movimetarCamera(cameraPosition);
  }

  _statusFinalizada() async {
    //Calcular Valor Viagem
    double latitudeDestino = _dadosRequisicao["destino"]["latitude"];
    double longitudeDestino = _dadosRequisicao["destino"]["longitude"];

    double latitudeOrigem = _dadosRequisicao["origem"]["latitude"];
    double longitudeOrigem = _dadosRequisicao["origem"]["longitude"];

    double distanciaEmMetros = await geolocator.distanceBetween(
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

    _exibirCaixaEndetecoDestino = false;
    _alterarBotaoPrincipal(
      "Total - R\$ $valorViagemFormatado",
      Colors.green,
      (){},
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

  _statusConfirmada(){
    if(_streamSubscriptionRequisicoes != null){
      _streamSubscriptionRequisicoes.cancel();
      _exibirCaixaEndetecoDestino = true;
      _alterarBotaoPrincipal(
        "Chamar Uber",
        Color(0xFF1ebbd8),
        () => _chamarUber(),
      );
      _dadosRequisicao.clear();
    }
    
  }

  _statusACaminho() {
    _exibirCaixaEndetecoDestino = false;
    _alterarBotaoPrincipal(
      "Motorista a caminho",
      Colors.grey,
      () {},
    );

    double latitudeDestino = _dadosRequisicao["passageiro"]["latitude"];
    double longitudeDestino = _dadosRequisicao["passageiro"]["longitude"];

    double latitudeOrigem = _dadosRequisicao["motorista"]["latitude"];
    double longitudeOrigem = _dadosRequisicao["motorista"]["longitude"];

    Marcador marcadorOrigem = Marcador(
      LatLng(latitudeOrigem, longitudeOrigem),
      "images/motorista.png",
      "Local Motorista"
    );
    Marcador marcadorDestino = Marcador(
      LatLng(latitudeDestino, longitudeDestino),
      "images/passageiro.png",
      "Local Passageiro"
    );

    _exibirCentralizadoDoisMarcadores(marcadorOrigem, marcadorDestino);
  }

  _statusEmViagem(){
    _exibirCaixaEndetecoDestino = false;
    _alterarBotaoPrincipal(
      "Em Viagem",
      Colors.grey,
      null,
    );
    double latitudeDestino = _dadosRequisicao["destino"]["latitude"];
    double longitudeDestino = _dadosRequisicao["destino"]["longitude"];

    double latitudeOrigem = _dadosRequisicao["motorista"]["latitude"];
    double longitudeOrigem = _dadosRequisicao["motorista"]["longitude"];

    Marcador marcadorOrigem = Marcador(
      LatLng(latitudeOrigem, longitudeOrigem),
      "images/motorista.png",
      "Local Motorista"
    );
    Marcador marcadorDestino = Marcador(
      LatLng(latitudeDestino, longitudeDestino),
      "images/destino.png",
      "Local Destino"
    );

    _exibirCentralizadoDoisMarcadores(marcadorOrigem, marcadorDestino);
  }

  //---------
  _exibirCentralizadoDoisMarcadores(Marcador markerOrigem, Marcador markerDestino){
    double latitudeOrigem = markerOrigem.local.latitude;
    double longitudeOrigem = markerOrigem.local.longitude;

    double latitudeDestino = markerDestino.local.latitude;
    double longitudeDestino = markerDestino.local.longitude;

    _exibirDoisMarcadores(
       markerOrigem, markerDestino
    );
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

    BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: pixelRatio),
      markerOrigem.caminhoImagem,
    ).then((BitmapDescriptor icone) {
      Marker mOrigem = Marker(
        markerId: MarkerId(markerOrigem.caminhoImagem),
        position: LatLng(latLngOrigem.latitude, latLngOrigem.longitude),
        infoWindow: InfoWindow(
          title: markerOrigem.titulo,
        ),
        icon: icone,
      );
      listMarcadores.add(mOrigem);
    });
    BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: pixelRatio),
      markerDestino.caminhoImagem,
    ).then((BitmapDescriptor icone) {
      Marker mDestino = Marker(
        markerId: MarkerId(markerDestino.caminhoImagem),
        position: LatLng(latLngDestino.latitude, latLngDestino.longitude),
        infoWindow: InfoWindow(
          title: markerDestino.titulo,
        ),
        icon: icone,
      );
      listMarcadores.add(mDestino);
    });

    setState(() {
      _marcadores = listMarcadores;
    });
  }

  _recuperarRequisisaoAtiva() async {
    FirebaseUser firebaseUser = await UsuarioFirebase.getUsuarioAtual();
    Firestore db = Firestore.instance;
    DocumentSnapshot snapshot = await db
        .collection("requisicao_ativa")
        .document(firebaseUser.uid)
        .get();
    if (snapshot.data != null) {
      //Adicionar Listener para requisição Ativa
      Map<String, dynamic> dados = snapshot.data;
      _idRequisicao = dados["id_requisicao"];
      _adicionarListenerRequisicao(_idRequisicao);
    } else {
      _statusUberNaoChamado();
    }
  }

  _adicionarListenerRequisicao(String idRequisicao) {
    Firestore db = Firestore.instance;
    _streamSubscriptionRequisicoes = db.collection("requisicoes")
        .document(idRequisicao)
        .snapshots()
        .listen((documentSnapshot) {
      if (documentSnapshot.data != null) {
        Map<String, dynamic> dadosAtuais = documentSnapshot.data;
        _idRequisicao = idRequisicao;
        _dadosRequisicao = dadosAtuais;
        String status = dadosAtuais["status"];
        switch (status) {
          case StatusRequisicao.AGUARDANDO:
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
            break;
          case StatusRequisicao.CANCELADA:
            _statusConfirmada();
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _recuperarRequisisaoAtiva();
    _recuperarUltimaLocalizacaoConhecida();
    _adicionarListenerLocalizacao();
  }

  @override
  void dispose() {
    super.dispose();
    _streamSubscriptionRequisicoes.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Painel Passageiro"),
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
            ),

            Visibility(
              visible: _exibirCaixaEndetecoDestino,
              child: Stack(
                children: <Widget>[
                  //TextField Meu Local
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.white,
                        ),
                        child: TextField(
                          readOnly: true,
                          decoration: InputDecoration(
                            icon: Container(
                              width: 30,
                              height: 30,
                              margin: EdgeInsets.only(left: 15),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.location_on,
                                color: Colors.green,
                              ),
                            ),
                            hintText: "Meu Local",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(left: 5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  //TextField Destino
                  Positioned(
                    top: 55,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.white,
                        ),
                        child: TextField(
                          controller: _destinoController,
                          decoration: InputDecoration(
                            icon: Container(
                              width: 30,
                              height: 30,
                              margin: EdgeInsets.only(left: 15),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.local_taxi,
                                color: Colors.black,
                              ),
                            ),
                            hintText: "Meu Destino",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(left: 5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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

  //?------------------------------------------------------------------------------
  //*------------------------------------------------------------------------------
  //-------------------------------------------------------------------------------
  _chamarUber() async {
    String destinoEndereco = _destinoController.text.trim();  
    if (destinoEndereco.isNotEmpty) {
      List<Placemark> listEnderecos =
          await geolocator.placemarkFromAddress(destinoEndereco);
      if (listEnderecos != null && listEnderecos.length > 0) {
        Placemark endereco = listEnderecos[0];
        Destino destino = Destino();
        destino.cidade = endereco.administrativeArea;
        destino.cep = endereco.postalCode;
        destino.bairro = endereco.subLocality;
        destino.rua = endereco.thoroughfare;
        destino.numero = endereco.subThoroughfare;
        destino.latitude = endereco.position.latitude;
        destino.longitude = endereco.position.longitude;

        String enderecoConfirmacao;
        enderecoConfirmacao = "\n Cidade: " + destino.cidade;
        enderecoConfirmacao += "\n Rua: " + destino.rua + ", " + destino.numero;
        enderecoConfirmacao += "\n Bairro: " + destino.bairro;
        enderecoConfirmacao += "\n Cep: " + destino.cep;
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("Confirmação do Endereço"),
                content: Text(
                  enderecoConfirmacao,
                ),
                contentPadding: EdgeInsets.all(16),
                actions: <Widget>[
                  FlatButton(
                    child: Text(
                      "Cancelar",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  FlatButton(
                    child: Text(
                      "Confirmar",
                      style: TextStyle(color: Colors.greenAccent),
                    ),
                    onPressed: () {
                      _salvarRequisicao(destino);
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            });
      }
    }
  }

  _salvarRequisicao(Destino destino) async {
    /*
      + requisicoes
        + ID_REQUISICAO
          + Destino(Rua, Endereco, Latitude ...)
          + Passageiro(Nome, Email ...)
          + Motorista(Nome, Email ...)
          + Status(aguardando, a caminho...finalizada)
    */
    Usuario passageiro = await UsuarioFirebase.getDadosUsuarioLogado();
    passageiro.latitude = _localPassageiro.latitude;
    passageiro.longitude = _localPassageiro.longitude;

    Requisicao requisicao = Requisicao();
    requisicao.destino = destino;
    requisicao.passageiro = passageiro;
    requisicao.status = StatusRequisicao.AGUARDANDO;

    Firestore db = Firestore.instance;
    db
        .collection("requisicoes")
        .document(requisicao.id)
        .setData(requisicao.toMap());
    //Savalar Requisição Ativa
    Map<String, dynamic> dadosRequisicaoAtiva = {
      "id_requisicao": requisicao.id,
      "id_usuario": passageiro.idUsuario,
      "status": StatusRequisicao.AGUARDANDO,
    };
    db
        .collection("requisicao_ativa")
        .document(passageiro.idUsuario)
        .setData(dadosRequisicaoAtiva);
    
    //Adicionar Listener Requisição
    if(_streamSubscriptionRequisicoes == null){
      _adicionarListenerRequisicao(requisicao.id);
    }
    
  }

  _cancelarUber() async {
    FirebaseUser firebaseUser = await UsuarioFirebase.getUsuarioAtual();
    Firestore db = Firestore.instance;
    await db
        .collection("requisicoes")
        .document(_idRequisicao)
        .updateData({"status": StatusRequisicao.CANCELADA}).then((_) {
      db.collection("requisicao_ativa").document(firebaseUser.uid).delete();
    });
  }
}
