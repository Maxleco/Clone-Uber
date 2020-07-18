import 'package:flutter/material.dart';
import 'package:uber/views/Cadastro.dart';
import 'package:uber/views/Corrida.dart';
import 'package:uber/views/Home.dart';
import 'package:uber/views/PainelMotorista.dart';
import 'package:uber/views/PainelPassageiro.dart';

class RouteGenerator{

  static Route<dynamic> generateRoute(RouteSettings settings){

    final args = settings.arguments;

    switch (settings.name) {
      case "/":
        return MaterialPageRoute(
          builder: (_) => Home(),
        );
        break;
      case "/cadastro":
        return MaterialPageRoute(
          builder: (_) => Cadastro(),
        );
        break;
      case "/painel-motorista":
        return MaterialPageRoute(
          builder: (_) => PainelMotorista(),
        );
        break;
      case "/painel-passageiro":
        return MaterialPageRoute(
          builder: (_) => PainelPassageiro(),
        );
        break;
      case "/corrida":
        return MaterialPageRoute(
          builder: (_) => Corrida(args),
        );
        break;
      default:
        _erroRota();
    }

  }

  static Route<dynamic> _erroRota(){
    return MaterialPageRoute(
      builder: (_){
        return Scaffold(
          appBar: AppBar(title: Text("Tela não encontrada")),
          body: Center(
            child: Text("Tela não encontrada"),
          ),
        );
      }
    );
  }

}
