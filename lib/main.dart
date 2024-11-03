import 'package:flutter/material.dart';

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

// Class da página inicial de consulta de produtos
class ConsultaProduto extends StatelessWidget {
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
                    decoration: InputDecoration(
                      labelText: 'Código',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Descrição',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Custo',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Preço de Venda',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            SizedBox(height: 8),
            // Tabela de produtos
            Expanded(
              child: LayoutBuilder(
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
                      rows: [
                        DataRow(cells: [
                          DataCell(Text('001')),
                          DataCell(Text('Produto A')),
                          DataCell(Text('R\$ 10,00')),
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
                                        productId: '001',
                                        loja: 'Loja A',
                                        precoVenda: 'R\$ 10,00',
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  print('Excluir produto 001');
                                },
                              ),
                            ],
                          )),
                        ]),
                      ],
                    ),
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
