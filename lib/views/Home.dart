import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uber/model/Usuario.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _senhaController = TextEditingController();
  String _messageError = "";
  bool _isLoading = false;

  void loading(bool value){
    setState(() => _isLoading = value);
  }

  _validarCampos() {
    String email = _emailController.text.trim();
    String senha = _senhaController.text.trim();

    if (email.isNotEmpty && email.contains("@")) {
      if (senha.isNotEmpty && senha.length > 6) {
        loading(true);
        Usuario usuario = Usuario();
        usuario.email = email;
        usuario.senha = senha;
        _logarUsuario(usuario);
      } else {
        setState((){
          _messageError = "Preencha a senha! Digite mais de 6 caracteres";
          _isLoading = false;
        });
      }
    } else {
      setState((){
        _messageError = "Preencha o E-mail válido!";
        _isLoading = false;
      });
    }
  }

  _logarUsuario(Usuario usuario) {
    FirebaseAuth auth = FirebaseAuth.instance;
    
    auth.signInWithEmailAndPassword(
      email: usuario.email,
      password: usuario.senha,
    ).then((AuthResult authResult){
      _redirecionaPainelPorTipoUsuario(authResult.user.uid);
    }).catchError((error){
      setState(() {
        _messageError = "Error ao autenticar usuário, verifique e-mail e senha!";
        _isLoading = false;
      });
    });
  }

  _redirecionaPainelPorTipoUsuario(String idUsuario) async {
    Firestore db = Firestore.instance;
    DocumentReference docRef = db
      .collection("usuarios")
      .document(idUsuario);
    if(docRef != null){
      docRef.get().then((DocumentSnapshot snapshot){
        Map<String, dynamic> dados = snapshot.data;
        String tipoUsuario = dados["tipoUsuario"];
        loading(false);
        switch (tipoUsuario) {
          case "passageiro":
            Navigator.pushReplacementNamed(context, "/painel-passageiro");
            break;
          case "motorista":
            Navigator.pushReplacementNamed(context, "/painel-motorista");
            break;
        }
      });
    }  
  }

  //------------------------------------------------------------------------------------------
  _verificarUsuarioLogado() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseUser usuarioLogado = await auth.currentUser();
    if(usuarioLogado != null){
      String idUsuario = usuarioLogado.uid;
      _redirecionaPainelPorTipoUsuario(idUsuario);
    }
  }
  @override
  void initState() {
    super.initState();
    _verificarUsuarioLogado();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("images/fundo.png"),
            fit: BoxFit.cover,
          ),
        ),
        padding: EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(bottom: 32),
                  child: Image.asset(
                    "images/logo.png",
                    width: 200,
                    height: 150,
                  ),
                ),
                //Input Email
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: TextField(
                    controller: _emailController,
                    // autofocus: true,
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
                  padding: const EdgeInsets.all(4.0),
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
                //Button
                Padding(
                  padding: EdgeInsets.only(
                    top: 16,
                    bottom: 10,
                  ),
                  child: RaisedButton(
                    child: Text(
                      "ENTRAR",
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
                //Cadastra-se
                Center(
                  child: GestureDetector(
                    child: Text(
                      "Não tem conta? Cadastre-se!",
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        "/cadastro",
                      );
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
                //? Loading Logar
                if(_isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
