
class Destino{

  String _rua;
  String _numero;
  String _cidade;
  String _bairro;
  String _cep;
  double _latitude;
  double _longitude;

  Destino();

  Map<String, dynamic> toMap(){
    Map<String, dynamic> map = {
      "rua": this.rua,
      "numero": this.numero,
      "cidade": this.cidade,
      "bairro": this.bairro,
      "cep": this.cep,
      "latitude": this.latitude,
      "longitude": this.longitude,
    };
    return map;
  }

  String get rua => this._rua;
  set rua(String value) => this._rua = value;

  String get numero => this._numero;
  set numero(String value) => this._numero = value;

  String get cidade => this._cidade;
  set cidade(String value) => this._cidade = value;

  String get bairro => this._bairro;
  set bairro(String value) => this._bairro = value;

  String get cep => this._cep;
  set cep(String value) => this._cep = value;

  double get latitude => this._latitude;
  set latitude(double value) => this._latitude = value;

  double get longitude => this._longitude;
  set longitude(double value) => this._longitude = value;
}