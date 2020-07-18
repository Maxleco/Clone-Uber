import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uber/model/Usuario.dart';

class Cadastro extends StatefulWidget {
  @override
  _CadastroState createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
  TextEditingController _nomeController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _senhaController = TextEditingController();
  bool _tipoUsuario = false;
  String _messageError = "";

  _validarCampos() {
    String nome = _nomeController.text.trim();
    String email = _emailController.text.trim();
    String senha = _senhaController.text.trim();
    if (nome.isNotEmpty) {
      if (email.isNotEmpty && email.contains("@")) {
        if (senha.isNotEmpty && senha.length > 6) {
          Usuario usuario = Usuario();
          usuario.nome = nome;
          usuario.email = email;
          usuario.senha = senha;
          usuario.tipoUsuario = _tipoUsuario ? "motorista" : "passageiro";
          _cadastrarUsuario(usuario);
        } else {
          setState(() =>
              _messageError = "Preencha a senha! Digite mais de 6 caracteres");
        }
      } else {
        setState(() => _messageError = "Preencha o E-mail válido!");
      }
    } else {
      setState(() => _messageError = "Preencha o Nome!");
    }
  }

  _cadastrarUsuario(Usuario usuario) {
    FirebaseAuth auth = FirebaseAuth.instance;
    Firestore db = Firestore.instance;
    auth.createUserWithEmailAndPassword(
      email: usuario.email,
      password: usuario.senha,
    ).then((AuthResult authResult) {
      db.collection("usuarios")
          .document(authResult.user.uid)
          .setData(usuario.toMap())
          .then((_) {
        switch (usuario.tipoUsuario) {
          case "motorista":
            Navigator.pushNamedAndRemoveUntil(
              context,
              "/painel-motorista",
              (_) => false,
            );
            break;
          case "passageiro":
            Navigator.pushNamedAndRemoveUntil(
              context,
              "/painel-passageiro",
              (_) => false,
            );
            break;
        }
      });
    }).catchError((error){
      setState(() {
        _messageError = "Error ao cadastrar usuário, verifique e-mail e senha!";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cadastro")),
      body: Container(
        decoration: BoxDecoration(color: Colors.white),
        padding: EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                //Input Nome
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: TextField(
                    controller: _nomeController,
                    autofocus: true,
                    keyboardType: TextInputType.text,
                    style: TextStyle(fontSize: 20),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                      hintText: "Nome Completo",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                //Input Email
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(fontSize: 20),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                      hintText: "E-mail",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                //Input Senha
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: TextField(
                    controller: _senhaController,
                    obscureText: true,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(fontSize: 20),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                      hintText: "Senha",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                //Switch Passageiro ou Motorista
                Padding(
                  padding: EdgeInsets.only(left: 6, bottom: 10),
                  child: Row(
                    children: <Widget>[
                      Text("Passageiro"),
                      Switch(
                        value: _tipoUsuario,
                        onChanged: (bool value) {
                          setState(() {
                            _tipoUsuario = value;
                          });
                        },
                      ),
                      Text("Motorista"),
                    ],
                  ),
                ),
                //Button
                Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 10),
                  child: RaisedButton(
                    child: Text(
                      "CADASTRAR",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    shape: ContinuousRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Color(0xFF1ebbd8),
                    padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                    onPressed: () {
                      _validarCampos();
                    },
                  ),
                ),
                //Messeger Error
                if (_messageError.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Center(
                      child: Text(
                        _messageError,
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
