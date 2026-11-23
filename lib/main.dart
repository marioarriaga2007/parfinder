import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ParfinderApp());
}

// ───────────── COLORES (dorado y oscuro) ─────────────
const Color kFondo = Color(0xFF14101C); // morado muy oscuro
const Color kFondo2 = Color(0xFF1C1528); // degradado del inicio
const Color kDorado = Color(0xFFD4AF37); // dorado perfume
const Color kCampo = Color(0xFF241D33); // tarjetas y campos
const Color kTextoSuave = Colors.white54;

// ───────────── CIFRADO DEL LOGIN ─────────────
// La contraseña NUNCA se guarda ni se compara en texto plano:
// se le agrega una "sal" y se convierte a un hash SHA-256.
const String kSal = 'parfinder_salt';

String cifrarPassword(String password) {
  final bytes = utf8.encode(kSal + password);
  return sha256.convert(bytes).toString();
}

// Usuario guardado: solo existe el HASH de la contraseña, no la contraseña.
// Usuario de prueba -> admin / 1234
const String kUsuarioGuardado = 'admin';
const String kHashGuardado =
    '4e4e142effa21d23c49a0fb55fe075bb411f676d124a65d8022935d4acdb277b';

// Usuarios registrados mientras la app está abierta: usuario -> hash.
// (Se pierden al cerrar la app; es en memoria.)
final Map<String, String> usuarios = {kUsuarioGuardado: kHashGuardado};

// ───────────── MODELO ─────────────
class Perfume {
  final String nombre;
  final String marca;
  final String genero;
  final String aroma;
  final String notas;

  /// Ruta de la imagen (assets/...). Si no existe, se dibuja un frasco.
  final String imagen;

  /// Categorías en las que aparece (Dulce, Fresco, Cítrico, Amaderado)
  final List<String> categorias;

  const Perfume({
    required this.nombre,
    required this.marca,
    required this.genero,
    required this.aroma,
    required this.notas,
    required this.imagen,
    required this.categorias,
  });
}

// ───────────── AQUÍ AGREGAS TUS PERFUMES ─────────────
const List<Perfume> perfumes = [
  Perfume(
    nombre: 'Lattafa Asad',
    marca: 'Lattafa',
    genero: 'Masculino',
    aroma: 'Dulce',
    notas: 'Vainilla, tabaco y pimienta',
    imagen: 'assets/lattafa_asad.png',
    categorias: ['Dulce', 'Amaderado'],
  ),
  Perfume(
    nombre: 'Nautica Voyage',
    marca: 'Nautica',
    genero: 'Masculino',
    aroma: 'Fresco',
    notas: 'Limon y pimienta',
    imagen: 'assets/nautica_voyage.png',
    categorias: ['Fresco', 'Cítrico'],
  ),
  Perfume(
    nombre: 'Dragon Blood',
    marca: '???',
    genero: '???',
    aroma: '???',
    notas: 'Fluidos Humanos',
    imagen: 'assets/dragon_blood.png',
    categorias: [],
  ),
];

// ───────────── APP ─────────────
class ParfinderApp extends StatelessWidget {
  const ParfinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PARFINDER',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: kDorado,
        scaffoldBackgroundColor: kFondo,
      ),
      home: const LoginPage(),
    );
  }
}

void abrirDetalle(BuildContext context, Perfume p) {
  Navigator.push(
    context,
    CupertinoPageRoute(builder: (_) => DetallePage(perfume: p)),
  );
}

// ───────────── PANTALLA 0: LOGIN + REGISTRO (misma pantalla) ─────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _userFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();

  bool _ocultarPassword = true;

  // false = muestra el LOGIN
  // true  = muestra el REGISTRO (en la misma pestaña, por condiciones)
  bool _modoRegistro = false;

  @override
  void dispose() {
    _userController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _userFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  // Cambia entre login y registro sin abrir otra pantalla
  void _cambiarModo() {
    setState(() {
      _modoRegistro = !_modoRegistro;
      _emailController.clear();
      _passwordController.clear();
      _confirmController.clear();
    });
    _formKey.currentState?.reset();
  }

  // Alerta Cupertino reutilizable
  void _alerta(String titulo, String mensaje, {VoidCallback? alAceptar}) {
    showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(titulo),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(mensaje),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(dialogContext);
              if (alAceptar != null) alAceptar();
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final usuario = _userController.text.trim();
    final password = _passwordController.text;

    if (_modoRegistro) {
      // ───── REGISTRO ─────
      if (usuarios.containsKey(usuario)) {
        _alerta('Usuario existente', 'Ese username ya está registrado.');
        return;
      }

      // Se guarda solo el hash de la contraseña
      usuarios[usuario] = cifrarPassword(password);

      _alerta(
        'Cuenta creada',
        'Ya puedes iniciar sesión, $usuario.',
        alAceptar: () {
          setState(() {
            _modoRegistro = false;
            _emailController.clear();
            _passwordController.clear();
            _confirmController.clear();
          });
          _formKey.currentState?.reset();
        },
      );
    } else {
      // ───── LOGIN ─────
      final hashIngresado = cifrarPassword(password);
      final esValido = usuarios[usuario] == hashIngresado;

      if (!esValido) {
        _alerta('Acceso denegado', 'Usuario o contraseña incorrectos.');
        return;
      }

      _alerta(
        '¡Bienvenido!',
        'Hola, $usuario. Disfruta tu fragancia.',
        alAceptar: () {
          // Entra a la app y ya no se puede regresar al login con "atrás"
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(builder: (_) => const PreferenciasPage()),
          );
        },
      );
    }
  }

  // Una fila: etiqueta dorada + campo oscuro
  Widget _fila({
    required String etiqueta,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String placeholder,
    required IconData icono,
    required String? Function(String?) validator,
    bool esPassword = false,
    bool esUltimo = false,
    FocusNode? siguiente,
    TextInputType? teclado,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              etiqueta,
              style: const TextStyle(
                color: kDorado,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: CupertinoTextFormFieldRow(
              controller: controller,
              focusNode: focusNode,
              placeholder: placeholder,
              keyboardType: teclado,
              obscureText: esPassword ? _ocultarPassword : false,
              prefix: Icon(icono, color: kDorado),
              style: const TextStyle(color: Colors.white),
              placeholderStyle: const TextStyle(color: Colors.white38),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: kCampo,
                borderRadius: BorderRadius.circular(10),
              ),
              textInputAction:
                  esUltimo ? TextInputAction.done : TextInputAction.next,
              onFieldSubmitted: (_) {
                if (esUltimo) {
                  _submit();
                } else {
                  siguiente?.requestFocus();
                }
              },
              validator: validator,
            ),
          ),
          // Ojito para ver/ocultar contraseña
          if (esPassword)
            IconButton(
              onPressed: () {
                setState(() {
                  _ocultarPassword = !_ocultarPassword;
                });
              },
              icon: Icon(
                _ocultarPassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                color: Colors.white54,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo: frasco de perfume dibujado
                    SizedBox(
                      width: _modoRegistro ? 80 : 110,
                      height: _modoRegistro ? 95 : 130,
                      child: const CustomPaint(
                          painter: PerfumePainter(color: kDorado)),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'PARFINDER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Subtítulo según el modo
                    Text(
                      _modoRegistro
                          ? 'Crea tu cuenta'
                          : 'Esencias que dejan huella',
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                    const SizedBox(height: 32),

                    // Username (login y registro)
                    _fila(
                      etiqueta: 'Username:',
                      controller: _userController,
                      focusNode: _userFocusNode,
                      placeholder: 'Username',
                      icono: CupertinoIcons.person_fill,
                      siguiente:
                          _modoRegistro ? _emailFocusNode : _passwordFocusNode,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (_modoRegistro && v.trim().length < 3) {
                          return 'Mínimo 3 caracteres';
                        }
                        return null;
                      },
                    ),

                    // Email (SOLO en registro)
                    if (_modoRegistro)
                      _fila(
                        etiqueta: 'Email:',
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        placeholder: 'Email',
                        icono: CupertinoIcons.mail_solid,
                        teclado: TextInputType.emailAddress,
                        siguiente: _passwordFocusNode,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (!v.contains('@') || !v.contains('.')) {
                            return 'Email no válido';
                          }
                          return null;
                        },
                      ),

                    // Password (login y registro)
                    _fila(
                      etiqueta: 'Password:',
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      placeholder: 'Password',
                      icono: CupertinoIcons.lock_fill,
                      esPassword: true,
                      esUltimo: !_modoRegistro,
                      siguiente: _confirmFocusNode,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (_modoRegistro && v.length < 4) {
                          return 'Mínimo 4 caracteres';
                        }
                        return null;
                      },
                    ),

                    // Confirmar password (SOLO en registro)
                    if (_modoRegistro)
                      _fila(
                        etiqueta: 'Confirmar:',
                        controller: _confirmController,
                        focusNode: _confirmFocusNode,
                        placeholder: 'Repite el password',
                        icono: CupertinoIcons.lock_shield_fill,
                        esPassword: true,
                        esUltimo: true,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (v != _passwordController.text) {
                            return 'No coinciden';
                          }
                          return null;
                        },
                      ),

                    const SizedBox(height: 16),

                    // Botón principal: cambia según el modo
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: kDorado,
                        borderRadius: BorderRadius.circular(12),
                        onPressed: _submit,
                        child: Text(
                          _modoRegistro ? 'Registrarme' : 'Entra',
                          style: const TextStyle(
                            color: kFondo,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Cambiar entre login y registro
                    CupertinoButton(
                      onPressed: _cambiarModo,
                      child: Text(
                        _modoRegistro
                            ? '¿Ya tienes cuenta? Inicia sesión'
                            : '¿No tienes cuenta? Regístrate',
                        style: const TextStyle(color: kDorado, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────── PANTALLA 1: PREFERENCIAS ─────────────
class PreferenciasPage extends StatefulWidget {
  const PreferenciasPage({super.key});

  @override
  State<PreferenciasPage> createState() => _PreferenciasPageState();
}

class _PreferenciasPageState extends State<PreferenciasPage> {
  final TextEditingController _busqueda = TextEditingController();
  final Random _random = Random();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  // Busca por nombre o marca
  void _buscar() {
    final q = _busqueda.text.trim().toLowerCase();
    if (q.isEmpty) return;

    final encontrados = perfumes.where((p) =>
        p.nombre.toLowerCase().contains(q) ||
        p.marca.toLowerCase().contains(q));

    if (encontrados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No encontramos ese perfume')),
      );
    } else {
      abrirDetalle(context, encontrados.first);
    }
  }

  // Abre el primer perfume de la categoría
  void _porCategoria(String categoria) {
    final lista = perfumes.where((p) => p.categorias.contains(categoria));
    if (lista.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aún no hay perfumes $categoria')),
      );
    } else {
      abrirDetalle(context, lista.first);
    }
  }

  // Perfume al azar
  void _sorprendeme() {
    abrirDetalle(context, perfumes[_random.nextInt(perfumes.length)]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kFondo, kFondo2],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    // Logo: frasco dibujado
                    const SizedBox(
                      width: 80,
                      height: 95,
                      child: CustomPaint(
                          painter: PerfumePainter(color: kDorado)),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'PARFINDER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buscador
                    TextField(
                      controller: _busqueda,
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _buscar(),
                      decoration: InputDecoration(
                        hintText: 'Buscar perfume',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: kCampo,
                        prefixIcon: const Icon(Icons.search, color: kDorado),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: kDorado),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    const Text(
                      '¿Qué estás buscando?',
                      style: TextStyle(
                        color: kDorado,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Categorías
                    Row(
                      children: [
                        Expanded(
                          child: _BotonCategoria(
                            texto: 'Dulce',
                            icono: Icons.cake,
                            color: const Color(0xFFFF6B6B),
                            onTap: () => _porCategoria('Dulce'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _BotonCategoria(
                            texto: 'Fresco',
                            icono: Icons.eco,
                            color: const Color(0xFF2EC4A0),
                            onTap: () => _porCategoria('Fresco'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _BotonCategoria(
                            texto: 'Cítrico',
                            icono: Icons.wb_sunny,
                            color: const Color(0xFFFFB020),
                            onTap: () => _porCategoria('Cítrico'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _BotonCategoria(
                            texto: 'Amaderado',
                            icono: Icons.park,
                            color: const Color(0xFFB07040),
                            onTap: () => _porCategoria('Amaderado'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Botón Sorpréndeme
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kDorado,
                          foregroundColor: kFondo,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: _sorprendeme,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text(
                          'SORPRÉNDEME',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BotonCategoria extends StatelessWidget {
  final String texto;
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  const _BotonCategoria({
    required this.texto,
    required this.icono,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kCampo,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kDorado.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icono, color: color),
              ),
              const SizedBox(height: 6),
              Text(
                texto,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────── PANTALLA 2: DETALLE DE PERFUME ─────────────
class DetallePage extends StatelessWidget {
  final Perfume perfume;

  const DetallePage({super.key, required this.perfume});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra superior: Volver | PARFINDER | Buscar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: const Row(
                          children: [
                            Icon(Icons.chevron_left, color: kDorado, size: 20),
                            Text('Volver',
                                style:
                                    TextStyle(color: kDorado, fontSize: 13)),
                          ],
                        ),
                      ),
                      const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'PAR',
                              style: TextStyle(color: Colors.white),
                            ),
                            TextSpan(
                              text: 'FINDER',
                              style: TextStyle(color: kDorado),
                            ),
                          ],
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: const Row(
                          children: [
                            Icon(Icons.search, color: kDorado, size: 18),
                            SizedBox(width: 2),
                            Text('Buscar',
                                style:
                                    TextStyle(color: kDorado, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Imagen del perfume
                  Container(
                    width: double.infinity,
                    height: 230,
                    decoration: BoxDecoration(
                      color: kCampo,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kDorado.withOpacity(0.25)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Image.asset(
                      perfume.imagen,
                      fit: BoxFit.contain,
                      // Si todavía no agregas la imagen, dibuja un frasco
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: SizedBox(
                            width: 90,
                            height: 120,
                            child: CustomPaint(
                              painter: PerfumePainter(color: kDorado),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Nombre
                  Text(
                    perfume.nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _Fila(
                      icono: Icons.sanitizer,
                      etiqueta: 'Marca:',
                      valor: perfume.marca),
                  _Fila(
                      icono: Icons.male,
                      etiqueta: 'Género:',
                      valor: perfume.genero),
                  _Fila(
                      icono: Icons.waves,
                      etiqueta: 'Aroma:',
                      valor: perfume.aroma),

                  const SizedBox(height: 14),

                  // Notas
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kCampo,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kDorado.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: kDorado.withOpacity(0.15),
                          child:
                              const Icon(Icons.eco, size: 18, color: kDorado),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Notas:',
                                  style: TextStyle(
                                      color: kTextoSuave, fontSize: 12)),
                              Text(
                                perfume.notas,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;

  const _Fila({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: kCampo,
                child: Icon(icono, size: 18, color: kDorado),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(etiqueta,
                      style:
                          const TextStyle(color: kTextoSuave, fontSize: 12)),
                  Text(
                    valor,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Colors.white12),
      ],
    );
  }
}

/// Frasco de perfume dibujado (logo y respaldo cuando no hay imagen).
class PerfumePainter extends CustomPainter {
  final Color color;
  const PerfumePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final relleno = Paint()..color = color;
    final suave = Paint()..color = color.withOpacity(0.15);
    final linea = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Tapa
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.34, 0, w * 0.32, h * 0.17),
        const Radius.circular(5),
      ),
      relleno,
    );

    // Cuello
    canvas.drawRect(
        Rect.fromLTWH(w * 0.42, h * 0.17, w * 0.16, h * 0.10), relleno);

    // Cuerpo
    final cuerpo = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.10, h * 0.27, w * 0.80, h * 0.73),
      const Radius.circular(20),
    );
    canvas.drawRRect(cuerpo, suave);
    canvas.drawRRect(cuerpo, linea);

    // Etiqueta
    final etiqueta = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.26, h * 0.52, w * 0.48, h * 0.25),
      const Radius.circular(8),
    );
    canvas.drawRRect(etiqueta, linea..strokeWidth = 2);

    // Brillo en el cristal
    final brillo = Path()
      ..moveTo(w * 0.20, h * 0.42)
      ..quadraticBezierTo(w * 0.17, h * 0.55, w * 0.20, h * 0.68);
    canvas.drawPath(brillo, linea..strokeWidth = 3);

    // Gotitas de spray
    canvas.drawCircle(Offset(w * 0.78, h * 0.06), 2.5, relleno);
    canvas.drawCircle(Offset(w * 0.88, h * 0.13), 2.5, relleno);
    canvas.drawCircle(Offset(w * 0.80, h * 0.17), 2, relleno);
  }

  @override
  bool shouldRepaint(covariant PerfumePainter oldDelegate) =>
      oldDelegate.color != color;
}