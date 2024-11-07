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
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PaginaProduto(isEditing: false)),
            );
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
  final List<Map<String, String>> tabelaLojas = [];

  final TextEditingController controllerLoja = TextEditingController();
  final TextEditingController controllerPrecoVenda = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Adiciona os itens teste de loja e preço
    tabelaLojas.addAll([
      {'loja': 'Loja A', 'precoVenda': 'R\$ 10,00'},
      {'loja': 'Loja B', 'precoVenda': 'R\$ 12,00'},
    ]);

    if (widget.isEditing) {
      controllerLoja.text = widget.loja ?? '';
      controllerPrecoVenda.text = widget.precoVenda ?? '';
    }
  }

  void mostrarItensLoja({Map<String, String>? item}) {
    final TextEditingController storeController = TextEditingController(
      text: item != null ? item['loja'] : '',
    );
    final TextEditingController priceController = TextEditingController(
      text: item != null ? item['precoVenda'] : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item != null ? 'Editar Loja' : 'Adicionar Loja'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: storeController,
                decoration: InputDecoration(labelText: 'Loja'),
              ),
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Preço de Venda'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (item != null) {
                  setState(() {
                    item['loja'] = storeController.text;
                    item['precoVenda'] = priceController.text;
                  });
                } else {
                  setState(() {
                    tabelaLojas.add({
                      'loja': storeController.text,
                      'precoVenda': priceController.text,
                    });
                  });
                }
                Navigator.of(context).pop();
              },
              child: Text('Salvar'),
            ),
          ],
        );
      },
    );
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
                    padding: const EdgeInsets.only(right: 0),
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Código',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: TextFormField(
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
            SizedBox(height: 16),
            // Botão para abrir modal para adicionar uma nova loja
            ElevatedButton(
              onPressed: () {
                mostrarItensLoja();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Tabela de lojas relacionadas a esse item
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return DataTable(
                    columnSpacing: constraints.maxWidth * 0.05,
                    columns: [
                      DataColumn(
                        label: Container(
                          width: constraints.maxWidth * 0.3,
                          child: Text('Loja'),
                        ),
                      ),
                      DataColumn(
                        label: Container(
                          width: constraints.maxWidth * 0.3,
                          child: Text('Preço de Venda'),
                        ),
                      ),
                      DataColumn(
                        label: Container(
                          width: constraints.maxWidth * 0.3,
                          child: Text('Ações'),
                        ),
                      ),
                    ],
                    rows: tabelaLojas.map((item) {
                      return DataRow(cells: [
                        DataCell(Text(item['loja']!)),
                        DataCell(Text(item['precoVenda']!)),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                mostrarItensLoja(item: item);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  tabelaLojas.remove(item);
                                });
                              },
                            ),
                          ],
                        )),
                      ]);
                    }).toList(),
                  );
                },
              ),
            ),
            SizedBox(height: 24),
            // Botão para salvar as alterações da inserção/edição do produto
            IconButton(
              icon: Icon(Icons.save, size: 30),
              onPressed: () {
                if (widget.isEditing) {
                  print('Produto editado com ID: ${widget.productId}');
                } else {
                  print('Produto adicionado');
                }
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
