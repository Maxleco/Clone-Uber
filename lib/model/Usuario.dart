
class Usuario{

  String _idUsuario;
  String _nome;
  String _email;
  String _senha;
  String _tipoUsuario;

  double _latitude;
  double _longitude;

  Usuario();

  Map<String, dynamic> toMap(){
    Map<String, dynamic> map = {
      "idUsuario": this.idUsuario,
      "nome": this.nome,
      "email": this.email,
      "tipoUsuario": this.tipoUsuario,
      "latitude": this.latitude,
      "longitude": this.longitude,
    };
    return map;
  }

  String get idUsuario => this._idUsuario;
  set idUsuario(String value) => this._idUsuario = value;

  String get nome => this._nome;
  set nome(String value) => this._nome = value;

  String get email => this._email;
  set email(String value) => this._email = value;

  String get senha => this._senha;
  set senha(String value) => this._senha = value;

  String get tipoUsuario => this._tipoUsuario;
  set tipoUsuario(String value) => this._tipoUsuario = value;

  double get latitude => this._latitude;
  set latitude(double value) => this._latitude = value;

  double get longitude => this._longitude;
  set longitude(double value) => this._longitude = value;
  
}