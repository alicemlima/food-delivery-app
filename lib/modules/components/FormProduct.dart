import 'package:ecommercefood/data/database.dart';
import 'package:ecommercefood/modules/controller/state_controller.dart';
import 'package:ecommercefood/modules/models/Category.dart';
import 'package:ecommercefood/modules/models/Product.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FormProduct extends StatefulWidget {
  const FormProduct({Key? key}) : super(key: key);

  @override
  State<FormProduct> createState() => _FormProductState();
}

class _FormProductState extends State<FormProduct> {
  final _priceFocus = FocusNode();
  final _descriptionFocus = FocusNode();

  final _imageUrlFocus = FocusNode();
  final _imageUrlController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _formData = <String, Object>{};
  int indexSelect = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
      ),
      body: _buildForm(context),
    );
  }

  @override
  void initState() {
    super.initState();
    _imageUrlFocus.addListener(updateImage);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_formData.isEmpty) {
      final arg = ModalRoute.of(context)?.settings.arguments;

      if (arg != null) {
        final product = arg as Product;
        _formData['id'] = product.id as String;
        _formData['title'] = product.name;
        _formData['price'] = product.price;
        _formData['description'] = product.description;
        _formData['imageUrl'] = product.imageUrl;
        _formData['category'] = product.categoryId.toString();
        _imageUrlController.text = product.imageUrl;
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _priceFocus.dispose();
    _descriptionFocus.dispose();

    _imageUrlFocus.removeListener(updateImage);
    _imageUrlFocus.dispose();
  }

  void updateImage() {
    setState(() {});
  }

  bool isValidImageUrl(String url) {
    bool isValidUrl = Uri.tryParse(url)?.hasAbsolutePath ?? false;
    bool endsWithFile = url.toLowerCase().endsWith('.png') ||
        url.toLowerCase().endsWith('.jpg') ||
        url.toLowerCase().endsWith('.jpeg');
    print('isValidUrl: $isValidUrl');
    return isValidUrl && endsWithFile;
  }

  void _submitForm() {
    final isValid = _formKey.currentState?.validate() ?? false;
    print(isValid);
    if (!isValid) {
      return;
    }

    _formKey.currentState?.save();

    Provider.of<StateController>(
      context,
      listen: false,
    ).saveProduct(_formData).then((value) {
      Navigator.of(context).pop();
    }).catchError((error) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Ocorreu um erro!'),
          content: const Text('Erro!!'),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            )
          ],
        ),
      );
    });
  }

  // form edit product
  Widget _buildForm(BuildContext context) {
    final arg = ModalRoute.of(context)?.settings.arguments;

    if (arg != null) {
      final product = arg as Product;
    }

    return Padding(
      padding: const EdgeInsets.all(15),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              initialValue: _formData['title']?.toString(),
              decoration: const InputDecoration(
                labelText: 'Nome',
              ),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_priceFocus);
              },
              onSaved: (name) => _formData['title'] = name ?? '',
              validator: (_name) {
                final name = _name ?? '';

                if (name.trim().isEmpty) {
                  return 'Nome é obrigatório';
                }

                if (name.trim().length < 3) {
                  return 'Nome precisa no mínimo de 3 letras.';
                }

                return null;
              },
            ),
            TextFormField(
              initialValue: _formData['price']?.toString(),
              decoration: const InputDecoration(labelText: 'Preço'),
              textInputAction: TextInputAction.next,
              focusNode: _priceFocus,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_descriptionFocus);
              },
              onSaved: (price) =>
                  _formData['price'] = double.parse(price ?? '0'),
              validator: (_price) {
                final priceString = _price ?? '';
                final price = double.tryParse(priceString) ?? -1;

                if (price <= 0) {
                  return 'Informe um preço válido.';
                }

                return null;
              },
            ),
            TextFormField(
              initialValue: _formData['description']?.toString(),
              decoration: const InputDecoration(labelText: 'Descrição'),
              focusNode: _descriptionFocus,
              keyboardType: TextInputType.multiline,
              maxLines: 3,
              onSaved: (description) =>
                  _formData['description'] = description ?? '',
              validator: (_description) {
                final description = _description ?? '';

                if (description.trim().isEmpty) {
                  return 'Descrição é obrigatória.';
                }

                if (description.trim().length < 10) {
                  return 'Descrição precisa no mínimo de 10 letras.';
                }

                return null;
              },
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextFormField(
                    decoration:
                        const InputDecoration(labelText: 'Url da Imagem'),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    focusNode: _imageUrlFocus,
                    controller: _imageUrlController,
                    onFieldSubmitted: (_) => _submitForm(),
                    onSaved: (imageUrl) =>
                        _formData['imageUrl'] = imageUrl ?? '',
                    validator: (_imageUrl) {
                      final imageUrl = _imageUrl ?? '';

                      if (!isValidImageUrl(imageUrl)) {
                        return 'Informe uma Url válida!';
                      }

                      return null;
                    },
                  ),
                ),
                Container(
                  height: 100,
                  width: 100,
                  margin: const EdgeInsets.only(
                    top: 10,
                    left: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey,
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: _imageUrlController.text.isEmpty
                      ? const Text('Informe a Url')
                      : Image.network(_imageUrlController.text),
                ),
              ],
            ),
            getSelect(),
            ElevatedButton(
              child: const Text('Salvar'),
              onPressed: _submitForm,
            )
          ],
        ),
      ),
    );
  }

  getSelect() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: DropdownButtonFormField(
        decoration: const InputDecoration(
          labelText: 'Categoria',
        ),
        value: indexSelect,
        onChanged: (value) {
          int currentValue = value as int;
          currentValue = currentValue - 1;
          _formData['category'] = currentValue.toString();
        },
        items: DatabaseProducts.getListCategoriesOrderByTitle()
            .map((category) => DropdownMenuItem(
                  value: category.id,
                  child: Text(category.title),
                ))
            .toList(),
      ),
    );
  }

  // method list category Text
  List<Widget> getListCategory() {
    List<Category> categories = DatabaseProducts.listCategories;
    return categories.map((category) => Text(category.title)).toList();
  }
}
