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
  _ConsultaProduto createState() => _ConsultaProduto();
}

// Criando os controllers para cada campo editavel do elemento Produto
// Criando as listas de todos os produtos, produtos filtrados e produtos atualizados
class _ConsultaProduto extends State<ConsultaProduto> {
  late Future<List<Produto>> produtosAtualizados;
  List<Produto> produtos = [];
  List<Produto> produtosFiltrados = [];

  final codigoController = TextEditingController();
  final descricaoController = TextEditingController();
  final custoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    produtosAtualizados = fetchProdutos();
    produtosAtualizados.then((value) {
      setState(() {
        produtos = value;
        produtosFiltrados = value;
      });
    });
  }

  // Buscando todos os produtos via API
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

  // Método para executar a rota de exclusao de um produto da API
  Future<void> excluirProduto(int productId) async {
    final url = Uri.parse('http://127.0.0.1:5000/produtos/$productId');
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      setState(() {
        produtosAtualizados = fetchProdutos();
        produtosAtualizados.then((value) {
          produtos = value;
          produtosFiltrados = value;
        });
      });
    }
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
                produtosAtualizados = fetchProdutos();
                produtosAtualizados.then((value) {
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
                future: produtosAtualizados,
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
                                    onPressed: () async {
                                      // Passar detalhes do produto para edição
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PaginaProduto(
                                            isEditing: true,
                                            productId: produto.id.toString(),
                                            descricao: produto.descricao,
                                            custo:
                                                'R\$ ${produto.custo.toStringAsFixed(2)}',
                                          ),
                                        ),
                                      );

                                      if (result == true) {
                                        setState(() {
                                          produtosAtualizados = fetchProdutos();
                                          produtosAtualizados.then((value) {
                                            produtos = value;
                                            produtosFiltrados = value;
                                          });
                                        });
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      excluirProduto(produto.id);
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
  final String? descricao;
  final String? custo;

  PaginaProduto({
    required this.isEditing,
    this.productId,
    this.descricao,
    this.custo,
  });

  @override
  PaginaProdutoEdicao createState() => PaginaProdutoEdicao();
}

// Classe que cria os controller e verifica se acionará o POST ou o PUT da API
class PaginaProdutoEdicao extends State<PaginaProduto> {
  final TextEditingController controllerDescricao = TextEditingController();
  final TextEditingController controllerCusto = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      controllerDescricao.text = widget.descricao ?? '';
      controllerCusto.text = widget.custo?.replaceAll('R\$ ', '') ?? '';
    }
  }

  Future<void> salvarProduto() async {
    final url = Uri.parse(
        'http://127.0.0.1:5000/produtos${widget.isEditing ? "/${widget.productId}" : ""}');
    final body = jsonEncode({
      'descricao': controllerDescricao.text,
      'custo': double.tryParse(controllerCusto.text) ?? 0,
    });

    final response = widget.isEditing
        ? await http.put(url,
            headers: {'Content-Type': 'application/json'}, body: body)
        : await http.post(url,
            headers: {'Content-Type': 'application/json'}, body: body);

    if ((widget.isEditing && response.statusCode == 200) ||
        (!widget.isEditing && response.statusCode == 201)) {
      Navigator.pop(context, true);
    }
  }

  // Página de inserção ou edicao de produto
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
              onPressed: salvarProduto,
              child: Text(widget.isEditing ? 'Salvar' : 'Adicionar'),
            ),
          ],
        ),
      ),
    );
  }
}
