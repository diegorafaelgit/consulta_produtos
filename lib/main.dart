import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Produto',
      debugShowCheckedModeBanner: false,
      home: ConsultaProduto(),
    );
  }
}

// Criando a instancia de Produto
class Produto {
  final int id;
  final String descricao;
  final double custo;

  Produto({required this.id, required this.descricao, required this.custo});

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      id: json['id_serial'],
      descricao: json['descricao'],
      custo: json['custo'].toDouble(),
    );
  }
}

// Classe que cria o estado do produto
class ConsultaProduto extends StatefulWidget {
  @override
  _ConsultaProdutoState createState() => _ConsultaProdutoState();
}

// Controlar os dados criando uma lista de todos os produtos e produtos filtrados
class _ConsultaProdutoState extends State<ConsultaProduto> {
  late Future<List<Produto>> futureProdutos;
  List<Produto> produtos = [];
  List<Produto> produtosFiltrados = [];

  final codigoController = TextEditingController();
  final descricaoController = TextEditingController();
  final custoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    futureProdutos = fetchProdutos();
    futureProdutos.then((value) {
      setState(() {
        produtos = value;
        produtosFiltrados = value;
      });
    });
  }

  Future<List<Produto>> fetchProdutos() async {
    final response =
        await http.get(Uri.parse('http://127.0.0.1:5000/produtos'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Produto.fromJson(data)).toList();
    } else {
      throw Exception('Falha ao carregar produtos');
    }
  }

  // Metodo para atualizar a lista com os produtos filtrados e caso o campo estiver vazio,
  // buscara todos os itens
  void filtrarProdutos() {
    setState(() {
      produtosFiltrados = produtos.where((produto) {
        final codigoFiltro = codigoController.text;
        final descricaoFiltro = descricaoController.text.toLowerCase();
        final custoFiltro = custoController.text;

        final correspondeCodigo = codigoFiltro.isEmpty ||
            produto.id.toString().contains(codigoFiltro);
        final correspondeDescricao = descricaoFiltro.isEmpty ||
            produto.descricao.toLowerCase().contains(descricaoFiltro);
        final correspondeCusto = custoFiltro.isEmpty ||
            produto.custo.toString().contains(custoFiltro);

        return correspondeCodigo && correspondeDescricao && correspondeCusto;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Consulta de Produto'),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.add),
          onPressed: () async {
            // Aguarda o retorno da tela de adição de produto
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PaginaProduto(isEditing: false)),
            );

            // Verifica se o produto foi adicionado e recarrega a lista
            if (result == true) {
              setState(() {
                futureProdutos = fetchProdutos();
                futureProdutos.then((value) {
                  produtos = value;
                  produtosFiltrados = value;
                });
              });
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Inputs de filtros
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 200,
                  child: TextFormField(
                    controller: codigoController,
                    decoration: InputDecoration(
                      labelText: 'Código',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => filtrarProdutos(),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: TextFormField(
                    controller: descricaoController,
                    decoration: InputDecoration(
                      labelText: 'Descrição',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => filtrarProdutos(),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: TextFormField(
                    controller: custoController,
                    decoration: InputDecoration(
                      labelText: 'Custo',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => filtrarProdutos(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<List<Produto>>(
                future: futureProdutos,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Erro: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('Nenhum produto encontrado'));
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: DataTable(
                          columnSpacing: constraints.maxWidth * 0.05,
                          columns: [
                            DataColumn(
                              label: Container(
                                width: constraints.maxWidth * 0.2,
                                child: Text('Código'),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                width: constraints.maxWidth * 0.3,
                                child: Text('Descrição'),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                width: constraints.maxWidth * 0.2,
                                child: Text('Custo'),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                width: constraints.maxWidth * 0.2,
                                child: Text('Ações'),
                              ),
                            ),
                          ],
                          rows: produtosFiltrados.map((produto) {
                            return DataRow(cells: [
                              DataCell(Text(produto.id.toString())),
                              DataCell(Text(produto.descricao)),
                              DataCell(Text(
                                  'R\$ ${produto.custo.toStringAsFixed(2)}')),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {
                                      // Passar detalhes do produto para edição
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PaginaProduto(
                                            isEditing: true,
                                            productId: produto.id.toString(),
                                            loja: produto.descricao,
                                            precoVenda:
                                                'R\$ ${produto.custo.toStringAsFixed(2)}',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      print('Excluir produto ${produto.id}');
                                    },
                                  ),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Classe que puxa os itens caso seja para edição
class PaginaProduto extends StatefulWidget {
  final bool isEditing;
  final String? productId;
  final String? loja;
  final String? precoVenda;

  PaginaProduto({
    required this.isEditing,
    this.productId,
    this.loja,
    this.precoVenda,
  });

  @override
  PaginaProdutoEdicao createState() => PaginaProdutoEdicao();
}

class PaginaProdutoEdicao extends State<PaginaProduto> {
  final TextEditingController controllerDescricao = TextEditingController();
  final TextEditingController controllerCusto = TextEditingController();

  Future<void> adicionarProduto() async {
    final url = Uri.parse('http://127.0.0.1:5000/produtos');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'descricao': controllerDescricao.text,
        'custo': double.tryParse(controllerCusto.text) ?? 0,
      }),
    );

    if (response.statusCode == 201) {
      print('Produto adicionado com sucesso');
      Navigator.pop(context, true);
    } else {
      print('Erro ao adicionar produto: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar Produto' : 'Adicionar Produto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: TextFormField(
                      controller: controllerDescricao,
                      decoration: InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: TextFormField(
                      controller: controllerCusto,
                      decoration: InputDecoration(
                        labelText: 'Custo',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: adicionarProduto,
              child: Text(widget.isEditing ? 'Salvar' : 'Adicionar'),
            ),
          ],
        ),
      ),
    );
  }
}
